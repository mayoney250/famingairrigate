import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/colors.dart';
import '../../services/irrigation_log_service.dart';
import '../../services/irrigation_schedule_service.dart';
import '../../services/sensor_data_service.dart';
import '../../services/alert_service.dart';
import '../../models/irrigation_log_model.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../models/user_model.dart';
import '../../models/alert_model.dart';
import '../../models/sensor_data_model.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final IrrigationLogService _logService = IrrigationLogService();
  final IrrigationScheduleService _scheduleService = IrrigationScheduleService();
  final SensorDataService _sensorService = SensorDataService();
  final AlertService _alertService = AlertService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Selection State
  String? _selectedFieldId;
  String? _selectedFieldName;
  DateTimeRange? _selectedDateRange;
  bool _isReportGenerated = false;

  bool _isLoading = false;
  bool _isLoadingFields = true;
  String? _errorMessage;
  DateTime? _reportGeneratedAt;
  
  // User & Metadata
  UserModel? _user;
  List<Map<String, String>> _fields = [];
  
  // Irrigation Data
  List<IrrigationScheduleModel> _scheduledCycles = [];
  List<IrrigationScheduleModel> _runningCycles = [];
  List<IrrigationLogModel> _manualCycles = [];
  List<IrrigationLogModel> _allLogs = [];
  StreamSubscription? _runningCyclesSubscription;
  
  // Sensor Data
  List<SensorDataModel> _sensorReadings = [];
  
  // Water Usage Data
  double _totalWaterUsed = 0.0;
  double _avgWaterPerCycle = 0.0;
  Map<String, double> _dailyWaterUsage = {};
  
  // Performance Metrics
  double _completionRate = 0.0;
  int _missedCycles = 0;
  int _overWateringCount = 0;
  int _underWateringCount = 0;
  
  // Notifications
  List<AlertModel> _alerts = [];
  
  // Field Metadata
  Map<String, dynamic>? _fieldData;
  double? _fieldSize;
  String? _cropType;
  String? _growthStage;
  
  // Trend Data
  double _previousPeriodWaterUsage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _runningCyclesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _loadUserData(user.uid);
    await _loadFields(user.uid);
    
    if (mounted) {
      setState(() {
        _isLoadingFields = false;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedFieldId == null || _selectedDateRange == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _reportGeneratedAt = DateTime.now();
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please sign in to view reports';
      });
      return;
    }

    try {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;

      await Future.wait([
        _loadScheduledCycles(user.uid, start, end),
        _loadIrrigationLogs(user.uid, start, end),
        _loadAlerts(user.uid, start, end),
        _loadSensorData(start, end),
        _loadFieldData(), // Load field metadata
      ]);

      // Calculate previous period for trend
      await _calculatePreviousPeriodUsage(user.uid, start, end);

      _startRealTimeRunningCyclesListener(user.uid, start, end);
      _calculateMetrics();
      
      setState(() {
        _isReportGenerated = true;
      });
      
    } catch (e) {
      debugPrint('Error loading report data: $e');
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    }

    setState(() => _isLoading = false);
  }

  void _resetSelection() {
    setState(() {
      _isReportGenerated = false;
      _runningCyclesSubscription?.cancel();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadFields(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('fields')
          .where('userId', isEqualTo: userId)
          .get();

      _fields = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': (data['label'] ?? data['name'] ?? data['fieldName'] ?? 'Field').toString(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading fields: $e');
    }
  }

  Future<void> _loadScheduledCycles(String userId, DateTime start, DateTime end) async {
    try {
      final allSchedules = await _scheduleService.getUserSchedules(userId);
      
      final filteredSchedules = allSchedules.where((schedule) {
        if (schedule.zoneId != _selectedFieldId) return false;
        if (!schedule.isActive) return false;
        
        final scheduleTime = schedule.nextRun ?? schedule.startTime;
        final scheduleCreated = schedule.createdAt ?? scheduleTime;
        
        if (schedule.repeatDays.isNotEmpty) {
          return scheduleCreated.isBefore(end.add(const Duration(days: 1)));
        }
        
        return scheduleTime.isAfter(start.subtract(const Duration(days: 1))) && 
               scheduleTime.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      _scheduledCycles = filteredSchedules.where((s) => s.status == 'scheduled').toList();
      _runningCycles = filteredSchedules.where((s) => s.status == 'running').toList();
      
    } catch (e) {
      debugPrint('❌ Error loading scheduled cycles: $e');
      _scheduledCycles = [];
      _runningCycles = [];
    }
  }

  void _startRealTimeRunningCyclesListener(String userId, DateTime start, DateTime end) {
    _runningCyclesSubscription?.cancel();
    
    try {
      _runningCyclesSubscription = _firestore
          .collection('irrigationSchedules')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'running')
          .snapshots()
          .listen((snapshot) {
        final runningList = snapshot.docs.map((doc) => 
          IrrigationScheduleModel.fromFirestore(doc)
        ).where((schedule) {
          if (schedule.zoneId != _selectedFieldId) return false;
          final scheduleTime = schedule.nextRun ?? schedule.startTime;
          return scheduleTime.isAfter(start.subtract(const Duration(days: 1))) && 
                 scheduleTime.isBefore(end.add(const Duration(days: 1)));
        }).toList();

        if (mounted) {
          setState(() {
            _runningCycles = runningList;
          });
        }
      });
    } catch (e) {
      debugPrint('Error setting up running cycles listener: $e');
    }
  }

  Future<void> _loadIrrigationLogs(String userId, DateTime start, DateTime end) async {
    try {
      final logs = await _logService.getLogsInRange(userId, start, end);
      _allLogs = logs.where((log) => log.zoneId == _selectedFieldId).toList();
      
      _manualCycles = _allLogs.where((log) => 
        log.triggeredBy == 'manual' && 
        log.action == IrrigationAction.completed
      ).toList();
      
    } catch (e) {
      debugPrint('❌ Error loading irrigation logs: $e');
      _allLogs = [];
      _manualCycles = [];
    }
  }

  Future<void> _loadAlerts(String userId, DateTime start, DateTime end) async {
    try {
      if (_selectedFieldId != null) {
         final allAlerts = await _alertService.getFarmAlerts(_selectedFieldId!);
         _alerts = allAlerts.where((alert) {
          return alert.ts.isAfter(start) && 
                 alert.ts.isBefore(end.add(const Duration(days: 1)));
        }).toList();
      } else {
        _alerts = [];
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
      _alerts = [];
    }
  }

  Future<void> _loadSensorData(DateTime start, DateTime end) async {
    try {
      if (_selectedFieldId != null) {
        _sensorReadings = await _sensorService.getReadingsInRange(
          _selectedFieldId!,
          start,
          end,
        );
        // Sort by timestamp
        _sensorReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading sensor data: $e');
      _sensorReadings = [];
    }
  }

  Future<void> _loadFieldData() async {
    try {
      if (_selectedFieldId != null) {
        final doc = await _firestore.collection('fields').doc(_selectedFieldId).get();
        if (doc.exists) {
          _fieldData = doc.data();
          _fieldSize = _fieldData?['size']?.toDouble() ?? _fieldData?['area']?.toDouble();
          _cropType = _fieldData?['cropType'] ?? _fieldData?['crop'];
          _growthStage = _fieldData?['growthStage'] ?? _fieldData?['stage'];
        }
      }
    } catch (e) {
      debugPrint('Error loading field data: $e');
      _fieldData = null;
    }
  }

  Future<void> _calculatePreviousPeriodUsage(String userId, DateTime start, DateTime end) async {
    try {
      final periodDuration = end.difference(start);
      final previousStart = start.subtract(periodDuration);
      final previousEnd = start;

      final previousLogs = await _logService.getLogsInRange(userId, previousStart, previousEnd);
      final previousFieldLogs = previousLogs.where((log) => log.zoneId == _selectedFieldId).toList();
      
      _previousPeriodWaterUsage = previousFieldLogs
          .where((log) => log.action == IrrigationAction.completed)
          .fold<double>(0.0, (sum, log) => sum + (log.waterUsed ?? 0.0));
    } catch (e) {
      debugPrint('Error calculating previous period usage: $e');
      _previousPeriodWaterUsage = 0.0;
    }
  }

  void _calculateMetrics() {
    final completedLogs = _allLogs.where((log) => 
      log.action == IrrigationAction.completed
    ).toList();

    _totalWaterUsed = completedLogs.fold<double>(
      0.0,
      (sum, log) => sum + (log.waterUsed ?? 0.0),
    );

    _avgWaterPerCycle = completedLogs.isNotEmpty 
        ? _totalWaterUsed / completedLogs.length 
        : 0.0;

    _dailyWaterUsage.clear();
    for (var log in completedLogs) {
      final dateKey = DateFormat('MM/dd').format(log.timestamp);
      _dailyWaterUsage[dateKey] = (_dailyWaterUsage[dateKey] ?? 0.0) + (log.waterUsed ?? 0.0);
    }

    final totalScheduled = _scheduledCycles.length;
    final completedScheduled = _scheduledCycles.where((s) => s.status == 'completed').length;
    _completionRate = totalScheduled > 0 ? (completedScheduled / totalScheduled) * 100 : 0.0;
    _missedCycles = _scheduledCycles.where((s) => 
      s.status == 'scheduled' && 
      (s.nextRun ?? s.startTime).isBefore(DateTime.now())
    ).length;
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FamingaBrandColors.primaryOrange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('index')) {
      return 'Setting up database. Please try again in a few minutes.';
    } else if (errorStr.contains('permission')) {
      return 'Permission denied. Please check your account.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Unable to load report. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Irrigation Report'),
        leading: _isReportGenerated 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _resetSelection,
            )
          : null,
        actions: [
          if (_isReportGenerated)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportToPdf,
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: _isLoadingFields 
        ? const Center(child: CircularProgressIndicator())
        : _isReportGenerated 
            ? _buildDashboardView(isDark)
            : _buildSelectionView(isDark),
    );
  }

  Widget _buildSelectionView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: FamingaBrandColors.primaryOrange.withOpacity(0.8),
            ),
            const SizedBox(height: 32),
            Text(
              'Generate Report',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a field and date range to view detailed insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            
            DropdownButtonFormField<String>(
              value: _selectedFieldId,
              decoration: InputDecoration(
                labelText: 'Select Field',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.grass),
              ),
              items: _fields.map((field) {
                return DropdownMenuItem(
                  value: field['id'],
                  child: Text(field['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFieldId = value;
                  _selectedFieldName = _fields.firstWhere((f) => f['id'] == value)['name'];
                });
              },
            ),
            const SizedBox(height: 24),
            
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date Range',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.date_range),
                ),
                child: Text(
                  _selectedDateRange != null
                      ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                      : 'Select Dates',
                  style: TextStyle(
                    color: _selectedDateRange != null 
                        ? Theme.of(context).textTheme.bodyLarge?.color 
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            ElevatedButton(
              onPressed: (_selectedFieldId != null && _selectedDateRange != null && !_isLoading)
                  ? _generateReport
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: FamingaBrandColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'GENERATE REPORT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _generateReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(isDark),
            const SizedBox(height: 24),
            
            // Water Usage Cards Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: _buildModernWaterCard('Total Water Used', _totalWaterUsed, 'L', Icons.water_drop, Colors.blue, isDark, showTrend: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildModernWaterCard('Average per Cycle', _avgWaterPerCycle, 'L', Icons.opacity, Colors.cyan, isDark)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildModernWaterCard('Total Water Used', _totalWaterUsed, 'L', Icons.water_drop, Colors.blue, isDark, showTrend: true),
                      const SizedBox(height: 16),
                      _buildModernWaterCard('Average per Cycle', _avgWaterPerCycle, 'L', Icons.opacity, Colors.cyan, isDark),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Field Data Card (Full Width)
            _buildFieldDataCard(isDark),
            const SizedBox(height: 24),
            
            // Moisture Insights & Status Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMoistureInsightsCard(isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildModernIrrigationStatus(isDark)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildMoistureInsightsCard(isDark),
                      const SizedBox(height: 16),
                      _buildModernIrrigationStatus(isDark),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Modern Recommendations
            _buildModernRecommendations(isDark),
            const SizedBox(height: 24),
            
            // Charts
            if (_sensorReadings.isNotEmpty) ...[
              _buildMoistureChart(isDark),
              const SizedBox(height: 24),
            ],
            _buildWaterUsageChart(isDark),
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivityList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FamingaBrandColors.primaryOrange,
            FamingaBrandColors.primaryOrange.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFieldName ?? 'Unknown Field',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_allLogs.length} Logs',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(bool isDark) {
    // Get current soil moisture if available
    final currentMoisture = _sensorReadings.isNotEmpty 
        ? _sensorReadings.last.soilMoisture 
        : 0.0;
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Water',
          '${_totalWaterUsed.toStringAsFixed(1)}L',
          Icons.water_drop,
          Colors.blue,
          isDark,
        ),
        _buildMetricCard(
          'Avg / Cycle',
          '${_avgWaterPerCycle.toStringAsFixed(1)}L',
          Icons.opacity,
          Colors.cyan,
          isDark,
        ),
        _buildMetricCard(
          'Field Data',
          '${_allLogs.length} Logs',
          Icons.analytics,
          Colors.green,
          isDark,
        ),
        _buildMetricCard(
          'Soil Moisture',
          '${currentMoisture.toStringAsFixed(1)}%',
          Icons.grass,
          _getMoistureCardColor(currentMoisture),
          isDark,
        ),
      ],
    );
  }

  Color _getMoistureCardColor(double moisture) {
    if (moisture < 30) return Colors.redAccent;
    if (moisture > 70) return Colors.blueAccent;
    return Colors.green;
  }

  // Modern UI Components

  Widget _buildModernWaterCard(String title, double value, String unit, IconData icon, Color color, bool isDark, {bool showTrend = false}) {
    String trendText = '';
    IconData? trendIcon;
    Color? trendColor;
    
    if (showTrend && _previousPeriodWaterUsage > 0) {
      final diff = value - _previousPeriodWaterUsage;
      final percentChange = (diff / _previousPeriodWaterUsage * 100).abs();
      
      if (diff > 0) {
        trendText = '+${percentChange.toStringAsFixed(1)}%';
        trendIcon = Icons.trending_up;
        trendColor = Colors.red;
      } else if (diff < 0) {
        trendText = '-${percentChange.toStringAsFixed(1)}%';
        trendIcon = Icons.trending_down;
        trendColor = Colors.green;
      } else {
        trendText = '0%';
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              if (showTrend && trendIcon != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(trendIcon, size: 14, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        trendText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          if (title.contains('Average'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Based on selected date range',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldDataCard(bool isDark) {
    final currentMoisture = _sensorReadings.isNotEmpty ? _sensorReadings.last.soilMoisture : 0.0;
    final nextSchedule = _scheduledCycles.isNotEmpty ? _scheduledCycles.first : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: FamingaBrandColors.primaryOrange, size: 28),
              const SizedBox(width: 12),
              Text(
                'Field Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Field Name
          _buildFieldInfoRow(Icons.label, 'Field Name', _selectedFieldName ?? 'Unknown', isDark),
          const SizedBox(height: 12),
          
          // Field Size
          if (_fieldSize != null)
            _buildFieldInfoRow(Icons.square_foot, 'Field Size', '${_fieldSize!.toStringAsFixed(2)} ha', isDark),
          if (_fieldSize != null) const SizedBox(height: 12),
          
          // Crop Type
          if (_cropType != null)
            _buildFieldInfoRow(Icons.eco, 'Crop Type', _cropType!, isDark),
          if (_cropType != null) const SizedBox(height: 12),
          
          // Growth Stage
          if (_growthStage != null)
            _buildFieldInfoRow(Icons.trending_up, 'Growth Stage', _growthStage!, isDark),
          if (_growthStage != null) const SizedBox(height: 12),
          
          // Current Moisture
          _buildFieldInfoRow(
            Icons.water_drop,
            'Current Moisture',
            '${currentMoisture.toStringAsFixed(1)}%',
            isDark,
            valueColor: _getMoistureCardColor(currentMoisture),
          ),
          const SizedBox(height: 12),
          
          // Next Schedule
          if (nextSchedule != null)
            _buildFieldInfoRow(
              Icons.schedule,
              'Next Schedule',
              DateFormat('MMM dd, HH:mm').format(nextSchedule.nextRun ?? nextSchedule.startTime),
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildFieldInfoRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: FamingaBrandColors.primaryOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoistureInsightsCard(bool isDark) {
    final currentMoisture = _sensorReadings.isNotEmpty ? _sensorReadings.last.soilMoisture : 0.0;
    final lastReading = _sensorReadings.isNotEmpty ? _sensorReadings.last.timestamp : null;
    
    String recommendation = 'No data available';
    IconData recommendIcon = Icons.info_outline;
    Color recommendColor = Colors.grey;
    
    if (currentMoisture > 0) {
      if (currentMoisture < 30) {
        recommendation = 'Irrigate Soon - Moisture is low';
        recommendIcon = Icons.water;
        recommendColor = Colors.red;
      } else if (currentMoisture > 70) {
        recommendation = 'Skip Next Cycle - Moisture is high';
        recommendIcon = Icons.check_circle;
        recommendColor = Colors.blue;
      } else {
        recommendation = 'Optimal - Maintain schedule';
        recommendIcon = Icons.thumb_up;
        recommendColor = Colors.green;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Moisture Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Current Moisture Display
          Center(
            child: Column(
              children: [
                Text(
                  '${currentMoisture.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getMoistureCardColor(currentMoisture),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Moisture',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Ideal Range
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ideal Range: 30% - 70%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Last Reading
          if (lastReading != null)
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  'Last reading: ${DateFormat('MMM dd, HH:mm').format(lastReading)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          
          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: recommendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(recommendIcon, color: recommendColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: recommendColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernIrrigationStatus(bool isDark) {
    final completedCount = _allLogs.where((log) => log.action == IrrigationAction.completed).length;
    final runningCount = _runningCycles.length;
    final canceledCount = _allLogs.where((log) => log.action == IrrigationAction.stopped || log.action == IrrigationAction.failed).length;
    final scheduledCount = _scheduledCycles.length;
    final total = completedCount + runningCount + canceledCount + scheduledCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: FamingaBrandColors.primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Irrigation Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Horizontal Bar Chart
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (completedCount > 0)
                    Expanded(
                      flex: completedCount,
                      child: Container(
                        height: 24,
                        color: Colors.green.shade400,
                      ),
                    ),
                  if (runningCount > 0)
                    Expanded(
                      flex: runningCount,
                      child: Container(
                        height: 24,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  if (canceledCount > 0)
                    Expanded(
                      flex: canceledCount,
                      child: Container(
                        height: 24,
                        color: Colors.red.shade400,
                      ),
                    ),
                  if (scheduledCount > 0)
                    Expanded(
                      flex: scheduledCount,
                      child: Container(
                        height: 24,
                        color: Colors.orange.shade400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Legend
          _buildStatusLegendItem('Completed', completedCount, total, Colors.green.shade400, isDark),
          const SizedBox(height: 12),
          _buildStatusLegendItem('Running', runningCount, total, Colors.blue.shade400, isDark),
          const SizedBox(height: 12),
          _buildStatusLegendItem('Canceled', canceledCount, total, Colors.red.shade400, isDark),
          const SizedBox(height: 12),
          _buildStatusLegendItem('Scheduled', scheduledCount, total, Colors.orange.shade400, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusLegendItem(String label, int count, int total, Color color, bool isDark) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($percentage%)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModernRecommendations(bool isDark) {
    final recommendations = <Map<String, dynamic>>[];
    
    // Generate top 3 actionable insights
    if (_missedCycles > 0) {
      recommendations.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
        'title': 'System Connectivity Issue',
        'description': '$_missedCycles irrigation cycles were missed. Check system connectivity.',
        'priority': 'high',
      });
    }
    
    if (_sensorReadings.isNotEmpty) {
      final latest = _sensorReadings.last;
      if (latest.soilMoisture < 30) {
        recommendations.add({
          'icon': Icons.water_drop,
          'color': Colors.orange,
          'title': 'Low Moisture Alert',
          'description': 'Soil moisture is ${latest.soilMoisture.toStringAsFixed(0)}%. Increase watering frequency or duration.',
          'priority': 'high',
        });
      } else if (latest.soilMoisture > 80) {
        recommendations.add({
          'icon': Icons.check_circle,
          'color': Colors.blue,
          'title': 'High Moisture Level',
          'description': 'Soil moisture is ${latest.soilMoisture.toStringAsFixed(0)}%. Consider skipping the next irrigation cycle.',
          'priority': 'medium',
        });
      }
    }

    if (_avgWaterPerCycle > 1000) {
      recommendations.add({
        'icon': Icons.trending_up,
        'color': Colors.purple,
        'title': 'High Water Usage',
        'description': 'Average usage is ${_avgWaterPerCycle.toStringAsFixed(0)}L per cycle. Check for leaks or optimize flow rate.',
        'priority': 'medium',
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.thumb_up,
        'color': Colors.green,
        'title': 'System Running Optimally',
        'description': 'All metrics are within normal ranges. No action needed at this time.',
        'priority': 'low',
      });
    }

    // Take top 3
    final topRecommendations = recommendations.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FamingaBrandColors.primaryOrange.withOpacity(0.1),
            FamingaBrandColors.primaryOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: FamingaBrandColors.primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...topRecommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final rec = entry.value;
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 16),
                _buildRecommendationItem(
                  rec['icon'] as IconData,
                  rec['color'] as Color,
                  rec['title'] as String,
                  rec['description'] as String,
                  rec['priority'] as String,
                  isDark,
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(IconData icon, Color color, String title, String description, String priority, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (priority == 'high')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HIGH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureChart(bool isDark) {
    if (_sensorReadings.isEmpty) return const SizedBox.shrink();

    // Downsample if too many points to avoid clutter
    final points = _sensorReadings.length > 50 
        ? _sensorReadings.where((e) => _sensorReadings.indexOf(e) % (_sensorReadings.length ~/ 50) == 0).toList()
        : _sensorReadings;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.soilMoisture.toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soil Moisture Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < points.length) {
                          if (points.length > 5 && index % (points.length ~/ 5) != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(points[index].timestamp),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterUsageChart(bool isDark) {
    if (_dailyWaterUsage.isEmpty) return const SizedBox.shrink();

    final sortedKeys = _dailyWaterUsage.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _dailyWaterUsage[e.value]!);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Water Usage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedKeys.length) {
                          if (sortedKeys.length > 7 && index % 2 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedKeys[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: FamingaBrandColors.primaryOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationStatusBreakdown(bool isDark) {
    // Get counts for each status
    final completedCount = _allLogs.where((log) => log.action == IrrigationAction.completed).length;
    final runningCount = _runningCycles.length;
    final canceledCount = _allLogs.where((log) => log.action == IrrigationAction.stopped || log.action == IrrigationAction.failed).length;
    final scheduledCount = _scheduledCycles.length;
    final total = completedCount + runningCount + canceledCount + scheduledCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: FamingaBrandColors.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Irrigation Status Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status cards grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _buildStatusMetricCard(
                '✓ Completed',
                completedCount,
                total,
                Colors.green,
                isDark,
              ),
              _buildStatusMetricCard(
                '▶ Running',
                runningCount,
                total,
                Colors.blue,
                isDark,
              ),
              _buildStatusMetricCard(
                '✕ Canceled',
                canceledCount,
                total,
                Colors.red,
                isDark,
              ),
              _buildStatusMetricCard(
                '📅 Scheduled',
                scheduledCount,
                total,
                Colors.orange,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetricCard(String label, int count, int total, Color color, bool isDark) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '($percentage%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(bool isDark) {
    final recommendations = <Map<String, dynamic>>[];
    
    // Logic based on sensor data and logs
    if (_missedCycles > 0) {
      recommendations.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
        'text': 'Check system connectivity. $_missedCycles cycles were missed.',
      });
    }
    
    if (_sensorReadings.isNotEmpty) {
      final latest = _sensorReadings.last;
      if (latest.soilMoisture < 30) {
        recommendations.add({
          'icon': Icons.water_drop,
          'color': Colors.orange,
          'text': 'Soil moisture is low (${latest.soilMoisture.toStringAsFixed(0)}%). Consider increasing irrigation duration.',
        });
      } else if (latest.soilMoisture > 80) {
        recommendations.add({
          'icon': Icons.opacity,
          'color': Colors.blue,
          'text': 'Soil moisture is high (${latest.soilMoisture.toStringAsFixed(0)}%). You can skip the next cycle.',
        });
      }
    }

    if (_avgWaterPerCycle > 1000) {
      recommendations.add({
        'icon': Icons.trending_up,
        'color': Colors.purple,
        'text': 'High water usage detected. Check for leaks or optimize flow rate.',
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'text': 'System is running optimally. No actions needed.',
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamingaBrandColors.primaryOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: FamingaBrandColors.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (rec['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(rec['icon'] as IconData, size: 16, color: rec['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec['text'] as String,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isDark) {
    return Column(
      children: [
        if (_runningCycles.isNotEmpty) ...[
          _buildStatusCard(
            'Running Cycles',
            _runningCycles,
            Icons.play_circle_fill,
            Colors.green,
            isDark,
            isRunning: true,
          ),
          const SizedBox(height: 20),
        ],
        if (_scheduledCycles.isNotEmpty) ...[
          _buildStatusCard(
            'Scheduled Cycles',
            _scheduledCycles,
            Icons.schedule,
            Colors.blue,
            isDark,
          ),
          const SizedBox(height: 20),
        ],
        if (_manualCycles.isNotEmpty) ...[
          _buildStatusCard(
            'Manual Irrigations',
            _manualCycles, // This is List<IrrigationLogModel>, handled below
            Icons.touch_app,
            Colors.orange,
            isDark,
            isLog: true,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard(
    String title, 
    List<dynamic> items, 
    IconData icon, 
    Color color, 
    bool isDark, 
    {bool isRunning = false, bool isLog = false}
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.take(3).length, // Show max 3
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              String titleText = '';
              String subtitleText = '';
              String timeText = '';

              if (isLog) {
                final log = item as IrrigationLogModel;
                titleText = 'Zone: ${log.zoneName}';
                subtitleText = '${log.waterUsed?.toStringAsFixed(1) ?? 0}L Used';
                timeText = DateFormat('MMM dd, HH:mm').format(log.timestamp);
              } else {
                final schedule = item as IrrigationScheduleModel;
                titleText = schedule.zoneName;
                final time = schedule.nextRun ?? schedule.startTime;
                timeText = DateFormat('MMM dd, HH:mm').format(time);
                subtitleText = isRunning 
                    ? 'In Progress' 
                    : 'Duration: ${schedule.durationMinutes} min';
              }

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(subtitleText),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if (isRunning)
                      const Text(
                        'Active',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              );
            },
          ),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {}, // Could expand to full list
                  child: const Text('View All'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(bool isDark) {
    final recentLogs = _allLogs.take(5).toList(); // Show last 5
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        if (recentLogs.isEmpty)
          const Text('No activity in this period.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentLogs.length,
            itemBuilder: (context, index) {
              final log = recentLogs[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: log.action == IrrigationAction.completed 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.orange.withOpacity(0.1),
                    child: Icon(
                      log.action == IrrigationAction.completed ? Icons.check : Icons.schedule,
                      color: log.action == IrrigationAction.completed ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    DateFormat('MMM dd, hh:mm a').format(log.timestamp),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${log.waterUsed?.toStringAsFixed(1) ?? 0}L Used'),
                  trailing: Text(
                    (log.triggeredBy ?? 'unknown').toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: FamingaBrandColors.statusWarning),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Unknown Error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateReport,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdf = pw.Document();
      
      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header with decorative design
              pw.Container(
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [PdfColors.orange800, PdfColors.orange600],
                  ),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IRRIGATION REPORT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      _selectedFieldName ?? 'Unknown Field',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey300,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 24),
              
              // Executive Summary with colored boxes
              _buildPdfSectionHeader('Executive Summary', PdfColors.blue800),
              pw.SizedBox(height: 12),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfMetricBox('Total Water', '${_totalWaterUsed.toStringAsFixed(1)}L', PdfColors.blue),
                  _buildPdfMetricBox('Avg/Cycle', '${_avgWaterPerCycle.toStringAsFixed(1)}L', PdfColors.cyan),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfMetricBox('Completion', '${_completionRate.toStringAsFixed(0)}%', PdfColors.green),
                  _buildPdfMetricBox('Missed', '$_missedCycles', PdfColors.red),
                ],
              ),
              
              pw.SizedBox(height: 24),
              
              // Irrigation Status Breakdown
              _buildPdfSectionHeader('Irrigation Status Breakdown', PdfColors.green800),
              pw.SizedBox(height: 12),
              
              ..._buildPdfIrrigationStatusSection(),
              
              pw.SizedBox(height: 24),
              
              // Soil Moisture Trends
              if (_sensorReadings.isNotEmpty) ...[
                _buildPdfSectionHeader('Soil Moisture Trends', PdfColors.blue800),
                pw.SizedBox(height: 12),
                
                ..._buildPdfSoilMoistureTrend(),
                
                pw.SizedBox(height: 24),
              ],
              
              // Daily Water Usage
              if (_dailyWaterUsage.isNotEmpty) ...[
                _buildPdfSectionHeader('Daily Water Usage', PdfColors.cyan800),
                pw.SizedBox(height: 12),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildPdfTableCell('Date', isHeader: true),
                        _buildPdfTableCell('Water Used (L)', isHeader: true),
                        _buildPdfTableCell('Visual', isHeader: true),
                      ],
                    ),
                    ..._dailyWaterUsage.entries.map((entry) {
                      final maxUsage = _dailyWaterUsage.values.reduce((a, b) => a > b ? a : b);
                      final barLength = ((entry.value / maxUsage) * 20).round();
                      final bar = '█' * barLength;
                      return pw.TableRow(
                        children: [
                          _buildPdfTableCell(entry.key),
                          _buildPdfTableCell(entry.value.toStringAsFixed(1)),
                          _buildPdfTableCell(bar),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 24),
              ],
              
              // AI Recommendations
              _buildPdfSectionHeader('AI Recommendations', PdfColors.orange800),
              pw.SizedBox(height: 12),
              
              ..._buildPdfRecommendations(),
              
              pw.SizedBox(height: 24),
              
              // Recent Activity Details
              if (_allLogs.isNotEmpty) ...[
                _buildPdfSectionHeader('Recent Activity', PdfColors.purple800),
                pw.SizedBox(height: 12),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildPdfTableCell('Date & Time', isHeader: true),
                        _buildPdfTableCell('Water (L)', isHeader: true),
                        _buildPdfTableCell('Trigger', isHeader: true),
                        _buildPdfTableCell('Status', isHeader: true),
                      ],
                    ),
                    ..._allLogs.take(15).map((log) {
                      return pw.TableRow(
                        children: [
                          _buildPdfTableCell(DateFormat('MMM dd, HH:mm').format(log.timestamp)),
                          _buildPdfTableCell((log.waterUsed ?? 0).toStringAsFixed(1)),
                          _buildPdfTableCell((log.triggeredBy ?? 'unknown').toUpperCase()),
                          _buildPdfTableCell(_getStatusText(log.action)),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
              
              // Footer
              pw.SizedBox(height: 32),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: 2),
                  ),
                ),
                padding: const pw.EdgeInsets.only(top: 12),
                child: pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Faminga Irrigation System',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Smart Farming Solutions for Africa',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Generate filename and share the PDF directly
      final fileName = 'irrigation_report_${_selectedFieldName?.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      
      // Share or save the PDF (this handles platform differences automatically)
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
      ),
    );
  }

  List<pw.Widget> _buildPdfRecommendations() {
    final recommendations = <String>[];
    
    if (_missedCycles > 0) {
      recommendations.add('⚠ Check system connectivity. $_missedCycles cycles were missed.');
    }
    
    if (_sensorReadings.isNotEmpty) {
      final latest = _sensorReadings.last;
      if (latest.soilMoisture < 30) {
        recommendations.add('💧 Soil moisture is low (${latest.soilMoisture.toStringAsFixed(0)}%). Consider increasing irrigation duration.');
      } else if (latest.soilMoisture > 80) {
        recommendations.add('💧 Soil moisture is high (${latest.soilMoisture.toStringAsFixed(0)}%). You can skip the next cycle.');
      }
    }

    if (_avgWaterPerCycle > 1000) {
      recommendations.add('📈 High water usage detected. Check for leaks or optimize flow rate.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✓ System is running optimally. No actions needed.');
    }

    return recommendations.map((rec) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 8,
              height: 8,
              margin: const pw.EdgeInsets.only(top: 4, right: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.orange,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                rec,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  pw.Widget _buildPdfSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: color, width: 4),
        ),
        color: PdfColors.grey100,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _buildPdfMetricBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color.shade(0.1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color, width: 2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<pw.Widget> _buildPdfIrrigationStatusSection() {
    // Get counts for each status
    final completedCount = _allLogs.where((log) => log.action == IrrigationAction.completed).length;
    final runningCount = _runningCycles.length;
    final canceledCount = _allLogs.where((log) => log.action == IrrigationAction.stopped || log.action == IrrigationAction.failed).length;
    final scheduledCount = _scheduledCycles.length;

    return [
      // Status summary boxes
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildPdfStatusBox('✓ Completed', completedCount, PdfColors.green),
          _buildPdfStatusBox('▶ Running', runningCount, PdfColors.blue),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildPdfStatusBox('✕ Canceled', canceledCount, PdfColors.red),
          _buildPdfStatusBox('📅 Scheduled', scheduledCount, PdfColors.orange),
        ],
      ),
      pw.SizedBox(height: 16),

      // Detailed breakdown table
      if (completedCount + runningCount + canceledCount + scheduledCount > 0) ...[
        pw.Text(
          'Detailed Breakdown',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPdfTableCell('Status', isHeader: true),
                _buildPdfTableCell('Count', isHeader: true),
                _buildPdfTableCell('Percentage', isHeader: true),
              ],
            ),
            if (completedCount > 0)
              _buildPdfStatusRow('✓ Completed', completedCount, PdfColors.green),
            if (runningCount > 0)
              _buildPdfStatusRow('▶ Running', runningCount, PdfColors.blue),
            if (canceledCount > 0)
              _buildPdfStatusRow('✕ Canceled', canceledCount, PdfColors.red),
            if (scheduledCount > 0)
              _buildPdfStatusRow('📅 Scheduled', scheduledCount, PdfColors.orange),
          ],
        ),
      ],
    ];
  }

  pw.Widget _buildPdfStatusBox(String label, int count, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color.shade(0.1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color, width: 1.5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              count.toString(),
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.TableRow _buildPdfStatusRow(String status, int count, PdfColor color) {
    final total = _allLogs.length + _runningCycles.length + _scheduledCycles.length;
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            status,
            style: pw.TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        _buildPdfTableCell(count.toString()),
        _buildPdfTableCell('$percentage%'),
      ],
    );
  }

  List<pw.Widget> _buildPdfSoilMoistureTrend() {
    if (_sensorReadings.isEmpty) return [];

    // Calculate statistics
    final moistureValues = _sensorReadings.map((r) => r.soilMoisture).toList();
    final minMoisture = moistureValues.reduce((a, b) => a < b ? a : b);
    final maxMoisture = moistureValues.reduce((a, b) => a > b ? a : b);
    final avgMoisture = moistureValues.reduce((a, b) => a + b) / moistureValues.length;

    // Sample readings if too many
    final displayReadings = _sensorReadings.length > 10
        ? _sensorReadings.where((r) => _sensorReadings.indexOf(r) % (_sensorReadings.length ~/ 10) == 0).toList()
        : _sensorReadings;

    return [
      // Statistics boxes
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildPdfMetricBox('Min', '${minMoisture.toStringAsFixed(1)}%', PdfColors.red),
          pw.SizedBox(width: 8),
          _buildPdfMetricBox('Avg', '${avgMoisture.toStringAsFixed(1)}%', PdfColors.blue),
          pw.SizedBox(width: 8),
          _buildPdfMetricBox('Max', '${maxMoisture.toStringAsFixed(1)}%', PdfColors.green),
        ],
      ),
      pw.SizedBox(height: 16),

      // Moisture readings table with visual indicators
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildPdfTableCell('Date & Time', isHeader: true),
              _buildPdfTableCell('Moisture %', isHeader: true),
              _buildPdfTableCell('Visual', isHeader: true),
              _buildPdfTableCell('Trend', isHeader: true),
            ],
          ),
          ...displayReadings.asMap().entries.map((entry) {
            final index = entry.key;
            final reading = entry.value;
            final moisture = reading.soilMoisture;
            
            // Create visual bar
            final barLength = (moisture / 10).round();
            final bar = '█' * barLength;
            
            // Determine trend
            String trend = '→';
            if (index > 0) {
              final prevMoisture = displayReadings[index - 1].soilMoisture;
              if (moisture > prevMoisture + 2) {
                trend = '↑';
              } else if (moisture < prevMoisture - 2) {
                trend = '↓';
              }
            }

            return pw.TableRow(
              children: [
                _buildPdfTableCell(DateFormat('MMM dd HH:mm').format(reading.timestamp)),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    moisture.toStringAsFixed(1),
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: _getMoistureColor(moisture),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                _buildPdfTableCell(bar),
                _buildPdfTableCell(trend),
              ],
            );
          }).toList(),
        ],
      ),

      pw.SizedBox(height: 12),

      // Legend
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildPdfLegendItem('Low (\u003c30%)', PdfColors.red),
            _buildPdfLegendItem('Optimal (30-70%)', PdfColors.green),
            _buildPdfLegendItem('High (\u003e70%)', PdfColors.blue),
          ],
        ),
      ),
    ];
  }

  pw.Widget _buildPdfLegendItem(String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  PdfColor _getMoistureColor(double moisture) {
    if (moisture < 30) return PdfColors.red;
    if (moisture > 70) return PdfColors.blue;
    return PdfColors.green;
  }

  String _getStatusText(IrrigationAction action) {
    switch (action) {
      case IrrigationAction.started:
        return '▶ STARTED';
      case IrrigationAction.completed:
        return '✓ COMPLETED';
      case IrrigationAction.stopped:
        return '⏹ STOPPED';
      case IrrigationAction.failed:
        return '✕ FAILED';
      case IrrigationAction.scheduled:
        return '📅 SCHEDULED';
    }
  }
}
