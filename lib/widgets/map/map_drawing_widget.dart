import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../models/irrigation_zone_model.dart';

enum DrawingMode {
  none,
  polygon,
  polyline,
  marker,
}

class MapDrawingWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final List<LatLng>? initialPoints;
  final DrawingMode initialDrawingMode;
  final Function(List<LatLng> points, DrawingMode mode)? onDrawingComplete;
  final bool showControls;
  final bool allowModeSwitch;
  
  const MapDrawingWidget({
    super.key,
    this.initialLocation,
    this.initialPoints,
    this.initialDrawingMode = DrawingMode.none,
    this.onDrawingComplete,
    this.showControls = true,
    this.allowModeSwitch = true,
  });

  @override
  State<MapDrawingWidget> createState() => _MapDrawingWidgetState();
}

class _MapDrawingWidgetState extends State<MapDrawingWidget> {
  GoogleMapController? _mapController;
  DrawingMode _drawingMode = DrawingMode.none;
  final List<LatLng> _points = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  
  LatLng _currentCenter = const LatLng(0.0, 0.0);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCoordinateInput = false;
  MapType _currentMapType = MapType.hybrid;

  @override
  void initState() {
    super.initState();
    _drawingMode = widget.initialDrawingMode;
    if (widget.initialPoints != null && widget.initialPoints!.isNotEmpty) {
      _points.addAll(widget.initialPoints!);
      _updateDrawing();
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentCenter, 15),
      );
    } catch (e) {
      _setDefaultLocation();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setDefaultLocation() {
    final defaultLocation = widget.initialLocation ?? const LatLng(-1.286389, 36.817223);
    setState(() {
      _currentCenter = defaultLocation;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentCenter, 12),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      setState(() => _isLoading = true);
      
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _currentCenter = newPosition;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addCoordinateManually() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coordinates')),
      );
      return;
    }
    
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates out of range')),
      );
      return;
    }
    
    final newPoint = LatLng(lat, lng);
    setState(() {
      _points.add(newPoint);
      _updateDrawing();
      _latController.clear();
      _lngController.clear();
    });
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newPoint, 15),
    );
  }

  void _onMapTap(LatLng position) {
    if (_drawingMode == DrawingMode.none) return;
    
    setState(() {
      _points.add(position);
      _updateDrawing();
    });
  }

  void _updateDrawing() {
    _markers.clear();
    _polylines.clear();
    _polygons.clear();
    
    for (int i = 0; i < _points.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _points[i],
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _points[i] = newPosition;
              _updateDrawing();
            });
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _drawingMode == DrawingMode.polygon ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: 'Point ${i + 1}',
            snippet: '${_points[i].latitude.toStringAsFixed(6)}, ${_points[i].longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }
    
    if (_points.length >= 2) {
      if (_drawingMode == DrawingMode.polyline) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('drawing'),
            points: _points,
            color: Colors.red,
            width: 3,
          ),
        );
      } else if (_drawingMode == DrawingMode.polygon && _points.length >= 3) {
        _polygons.add(
          Polygon(
            polygonId: const PolygonId('drawing'),
            points: _points,
            strokeColor: Colors.blue,
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.3),
          ),
        );
      }
    }
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
      _markers.clear();
      _polylines.clear();
      _polygons.clear();
    });
  }

  void _completeDrawing() {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No points to save')),
      );
      return;
    }
    
    if (_drawingMode == DrawingMode.polygon && _points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon needs at least 3 points')),
      );
      return;
    }
    
    if (_drawingMode == DrawingMode.polyline && _points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Line needs at least 2 points')),
      );
      return;
    }
    
    widget.onDrawingComplete?.call(_points, _drawingMode);
  }

  void _removeLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
        _updateDrawing();
      });
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.hybrid 
          ? MapType.normal 
          : _currentMapType == MapType.normal
              ? MapType.satellite
              : MapType.hybrid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            if (widget.initialLocation != null) {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(widget.initialLocation!, 15),
              );
            }
          },
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation ?? _currentCenter,
            zoom: 15,
          ),
          mapType: _currentMapType,
          onTap: _onMapTap,
          markers: _markers,
          polylines: _polylines,
          polygons: _polygons,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        
        if (widget.showControls) ...[
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: _searchLocation,
                    ),
                    
                    if (_showCoordinateInput) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _lngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_location),
                            onPressed: _addCoordinateManually,
                            tooltip: 'Add Point',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            right: 16,
            top: _showCoordinateInput ? 180 : 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'mapType',
                  onPressed: _toggleMapType,
                  child: const Icon(Icons.layers),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'coords',
                  onPressed: () {
                    setState(() {
                      _showCoordinateInput = !_showCoordinateInput;
                    });
                  },
                  child: const Icon(Icons.pin_drop),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.allowModeSwitch) ...[
                      Row(
                        children: [
                          const Text('Drawing Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<DrawingMode>(
                              segments: const [
                                ButtonSegment(
                                  value: DrawingMode.none,
                                  label: Text('None'),
                                  icon: Icon(Icons.block, size: 16),
                                ),
                                ButtonSegment(
                                  value: DrawingMode.polygon,
                                  label: Text('Area'),
                                  icon: Icon(Icons.pentagon, size: 16),
                                ),
                                ButtonSegment(
                                  value: DrawingMode.polyline,
                                  label: Text('Line'),
                                  icon: Icon(Icons.timeline, size: 16),
                                ),
                              ],
                              selected: {_drawingMode},
                              onSelectionChanged: (Set<DrawingMode> modes) {
                                setState(() {
                                  _drawingMode = modes.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    Row(
                      children: [
                        Text(
                          'Points: ${_points.length}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (_points.isNotEmpty) ...[
                          TextButton.icon(
                            onPressed: _removeLastPoint,
                            icon: const Icon(Icons.undo),
                            label: const Text('Undo'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _clearDrawing,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _points.isEmpty ? null : _completeDrawing,
                          icon: const Icon(Icons.check),
                          label: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
