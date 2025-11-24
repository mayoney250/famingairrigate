import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

enum DrawingMode {
  none,
  polygon,
  polyline,
  marker,
}

class OSMMapDrawingWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final List<LatLng>? initialPoints;
  final DrawingMode initialDrawingMode;
  final Function(List<LatLng> points, DrawingMode mode)? onDrawingComplete;
  final bool showControls;
  final bool allowModeSwitch;
  final String mapTileLayer; // 'streets' or 'satellite'
  
  const OSMMapDrawingWidget({
    super.key,
    this.initialLocation,
    this.initialPoints,
    this.initialDrawingMode = DrawingMode.none,
    this.onDrawingComplete,
    this.showControls = true,
    this.allowModeSwitch = true,
    this.mapTileLayer = 'streets',
  });

  @override
  State<OSMMapDrawingWidget> createState() => _OSMMapDrawingWidgetState();
}

class _OSMMapDrawingWidgetState extends State<OSMMapDrawingWidget> {
  final MapController _mapController = MapController();
  DrawingMode _drawingMode = DrawingMode.none;
  final List<LatLng> _points = [];
  
  LatLng _currentCenter = const LatLng(0.0, 0.0);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCoordinateInput = false;
  String _currentMapLayer = 'streets'; // streets, satellite

  @override
  void initState() {
    super.initState();
    _drawingMode = widget.initialDrawingMode;
    _currentMapLayer = widget.mapTileLayer; // Use passed-in layer preference
    if (widget.initialPoints != null && widget.initialPoints!.isNotEmpty) {
      _points.addAll(widget.initialPoints!);
      // If we have initial points, center on them instead of current location
      if (_points.isNotEmpty) {
        _currentCenter = _points.first;
      } else {
        _getCurrentLocation();
      }
    } else {
      // Request user's location
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services disabled. Using default location.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied. Using default location.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Using default location.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
      });
      
      _mapController.move(_currentCenter, 15);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Centered on your location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Using default location.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
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
    _mapController.move(_currentCenter, 12);
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Use Nominatim (OpenStreetMap's free geocoding service)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FamingaIrrigation/1.0', // Required by Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          final result = results.first;
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          final newPosition = LatLng(lat, lon);
          
          setState(() {
            _currentCenter = newPosition;
          });
          
          _mapController.move(newPosition, 15);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found: ${result['display_name']}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location not found. Try a different search term.')),
            );
          }
        }
      } else {
        throw Exception('Search service unavailable');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: Unable to find location')),
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
      _latController.clear();
      _lngController.clear();
    });
    
    _mapController.move(newPoint, 15);
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    if (_drawingMode == DrawingMode.none) return;
    
    setState(() {
      _points.add(position);
    });
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
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
      });
    }
  }

  void _toggleMapLayer() {
    setState(() {
      if (_currentMapLayer == 'streets') {
        _currentMapLayer = 'satellite';
      } else {
        _currentMapLayer = 'streets';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialLocation ?? _currentCenter,
            initialZoom: 15,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: _currentMapLayer == 'satellite'
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'faminga.irrigate',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            
            if (_points.isNotEmpty && _drawingMode == DrawingMode.polygon && _points.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _points,
                    color: Colors.blue.withOpacity(0.3),
                    borderStrokeWidth: 2,
                    borderColor: Colors.blue,
                  ),
                ],
              ),
            
            if (_points.isNotEmpty && _drawingMode == DrawingMode.polyline && _points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _points,
                    color: Colors.red,
                    strokeWidth: 3,
                  ),
                ],
              ),
            
            MarkerLayer(
              markers: _points.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Note: Dragging markers in flutter_map is more complex
                      // For now, we'll just allow tapping to add points
                    },
                    child: Icon(
                      Icons.location_on,
                      color: _drawingMode == DrawingMode.polygon ? Colors.blue : Colors.red,
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
                  onPressed: _toggleMapLayer,
                  child: Icon(_currentMapLayer == 'satellite' ? Icons.layers : Icons.satellite),
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
