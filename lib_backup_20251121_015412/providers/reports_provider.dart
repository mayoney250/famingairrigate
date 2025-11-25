import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../models/irrigation_log_model.dart';
import '../models/irrigation_schedule_model.dart';
import '../models/user_model.dart';
import '../models/alert_model.dart';
import '../services/irrigation_log_service.dart';
import '../services/irrigation_schedule_service.dart';
import '../services/sensor_data_service.dart';
import '../services/alert_service.dart';

enum ReportPeriod { daily, weekly, monthly }
enum CycleTypeFilter { all, scheduled, manual }
enum StatusFilter { all, scheduled, running, completed, stopped }

class ReportsProvider with ChangeNotifier {
  final IrrigationLogService _logService = IrrigationLogService();
  final IrrigationScheduleService _scheduleService = IrrigationScheduleService();
  final SensorDataService _sensorService = SensorDataService();
  final AlertService _alertService = AlertService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Filters
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  CycleTypeFilter _cycleTypeFilter = CycleTypeFilter.all;
  StatusFilter _statusFilter = StatusFilter.all;
  String? _selectedFieldFilter;
  DateTime? _selectedDate;

  // Loading state
  bool _isLoading = true;
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

  // Water Usage Data
  double _totalWaterUsed = 0.0;
  double _avgWaterPerCycle = 0.0;
  Map<String, double> _fieldWiseUsage = {};
  Map<String, double> _dailyWaterUsage = {};

  // Performance Metrics
  double _completionRate = 0.0;
  int _missedCycles = 0;

  // Alerts
  List<AlertModel> _alerts = [];

  // Getters
  ReportPeriod get selectedPeriod => _selectedPeriod;
  CycleTypeFilter get cycleTypeFilter => _cycleTypeFilter;
  StatusFilter get statusFilter => _statusFilter;
  String? get selectedFieldFilter => _selectedFieldFilter;
  DateTime? get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get reportGeneratedAt => _reportGeneratedAt;
  UserModel? get user => _user;
  List<Map<String, String>> get fields => _fields;
  List<IrrigationScheduleModel> get scheduledCycles => _scheduledCycles;
  List<IrrigationScheduleModel> get runningCycles => _runningCycles;
  List<IrrigationLogModel> get manualCycles => _manualCycles;
  List<IrrigationLogModel> get allLogs => _allLogs;
  double get totalWaterUsed => _totalWaterUsed;
  double get avgWaterPerCycle => _avgWaterPerCycle;
  Map<String, double> get fieldWiseUsage => _fieldWiseUsage;
  Map<String, double> get dailyWaterUsage => _dailyWaterUsage;
  double get completionRate => _completionRate;
  int get missedCycles => _missedCycles;
  List<AlertModel> get alerts => _alerts;

  // Filtered getters
  List<IrrigationScheduleModel> get filteredScheduledCycles {
    var filtered = _scheduledCycles;
    if (_selectedFieldFilter != null) {
      filtered = filtered.where((c) => c.zoneId == _selectedFieldFilter).toList();
    }
    if (_statusFilter != StatusFilter.all) {
      filtered = filtered.where((c) => c.status == _statusFilter.name).toList();
    }
    return filtered;
  }

  List<IrrigationLogModel> get filteredManualCycles {
    var filtered = _manualCycles;
    if (_selectedFieldFilter != null) {
      filtered = filtered.where((c) => c.zoneId == _selectedFieldFilter).toList();
    }
    return filtered;
  }

  List<IrrigationLogModel> get filteredLogs {
    var filtered = _allLogs;
    if (_selectedFieldFilter != null) {
      filtered = filtered.where((log) => log.zoneId == _selectedFieldFilter).toList();
    }
    return filtered;
  }

  List<AlertModel> get filteredAlerts {
    var filtered = _alerts;
    if (_selectedFieldFilter != null) {
      // Assuming alerts have fieldId or similar; adjust based on model
      filtered = filtered.where((alert) => alert.farmId == _selectedFieldFilter).toList();
    }
    return filtered;
  }

  // Farm Overview data
  String get lastIrrigation {
    final completedLogs = filteredLogs.where((log) => log.action == IrrigationAction.completed).toList();
    if (completedLogs.isEmpty) return 'No data for this date';
    completedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return DateFormat('MMM dd, yyyy hh:mm a').format(completedLogs.first.timestamp);
  }

  String get nextIrrigation {
    final upcoming = filteredScheduledCycles.where((s) => s.status == 'scheduled').toList();
    if (upcoming.isEmpty) return 'No scheduled irrigation';
    upcoming.sort((a, b) => (a.nextRun ?? a.startTime).compareTo(b.nextRun ?? b.startTime));
    return DateFormat('MMM dd, hh:mm a').format(upcoming.first.nextRun ?? upcoming.first.startTime);
  }

  String get currentMoisture {
    // Calculate average moisture from sensor data for selected fields
    // For now, use a simple calculation based on water usage as proxy
    if (_selectedFieldFilter != null) {
      // Specific field
      final fieldUsage = _fieldWiseUsage[_selectedFieldFilter];
      if (fieldUsage != null && fieldUsage > 0) {
        // Simple proxy: higher usage might indicate lower moisture
        final moisturePercent = (100 - (fieldUsage / 10).clamp(0, 50)).toStringAsFixed(0);
        return '$moisturePercent%';
      }
    } else {
      // All fields average
      if (_fieldWiseUsage.isNotEmpty) {
        final totalUsage = _fieldWiseUsage.values.reduce((a, b) => a + b);
        final avgUsage = totalUsage / _fieldWiseUsage.length;
        final moisturePercent = (100 - (avgUsage / 10).clamp(0, 50)).toStringAsFixed(0);
        return '$moisturePercent%';
      }
    }
    return 'No data';
  }

  Future<void> loadReportData() async {
    _isLoading = true;
    _errorMessage = null;
    _reportGeneratedAt = DateTime.now();
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      _errorMessage = 'Please sign in to view reports';
      notifyListeners();
      return;
    }

    try {
      await Future.wait([
        _loadUserData(user.uid),
        _loadFields(user.uid),
      ]);

      final dateRange = _getDateRange();
      await Future.wait([
        _loadScheduledCycles(user.uid, dateRange['start']!, dateRange['end']!),
        _loadIrrigationLogs(user.uid, dateRange['start']!, dateRange['end']!),
        _loadAlerts(user.uid, dateRange['start']!, dateRange['end']!),
      ]);

      _startRealTimeRunningCyclesListener(user.uid, dateRange['start']!, dateRange['end']!);
      _calculateMetrics();

    } catch (e) {
      debugPrint('Error loading report data: $e');
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
    }

    _isLoading = false;
    notifyListeners();
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
        final name = data['label'] ?? data['name'] ?? data['fieldName'] ?? data['field_name'] ?? data['title'] ?? 'Field';
        final cropType = data['crop'] ?? data['cropType'] ?? data['crop_type'] ?? data['cropName'] ?? data['crop_name'] ?? data['cropType'] ?? 'N/A';
        final farmSize = data['area'] ?? data['size'] ?? data['farmSize'] ?? data['fieldSize'] ?? data['areaSize'] ?? data['size'] ?? 'N/A';

        return {
          'id': doc.id,
          'name': name.toString(),
          'cropType': cropType.toString(),
          'farmSize': farmSize.toString(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading fields: $e');
      _fields = [];
    }
  }

  Future<void> _loadScheduledCycles(String userId, DateTime start, DateTime end) async {
    try {
      final allSchedules = await _scheduleService.getUserSchedules(userId);

      final filteredSchedules = allSchedules.where((schedule) {
        if (!schedule.isActive) return false;

        final scheduleTime = schedule.nextRun ?? schedule.startTime;
        final scheduleCreated = schedule.createdAt ?? scheduleTime;

        if (schedule.repeatDays.isNotEmpty) {
          final shouldInclude = scheduleCreated.isBefore(end.add(const Duration(days: 1)));
          return shouldInclude;
        }

        final shouldInclude = scheduleTime.isAfter(start.subtract(const Duration(days: 1))) &&
               scheduleTime.isBefore(end.add(const Duration(days: 1)));
        return shouldInclude;
      }).toList();

      _scheduledCycles = filteredSchedules.where((s) => s.status == 'scheduled').toList();
      _runningCycles = filteredSchedules.where((s) => s.status == 'running').toList();
    } catch (e) {
      debugPrint('Error loading scheduled cycles: $e');
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
          final scheduleTime = schedule.nextRun ?? schedule.startTime;
          return scheduleTime.isAfter(start.subtract(const Duration(days: 1))) &&
                 scheduleTime.isBefore(end.add(const Duration(days: 1)));
        }).toList();

        _runningCycles = runningList;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error setting up running cycles listener: $e');
    }
  }

  Future<void> _loadIrrigationLogs(String userId, DateTime start, DateTime end) async {
    try {
      _allLogs = await _loadLogsWithFallback(userId, start, end);

      final completedLogs = _allLogs.where((log) => log.action == IrrigationAction.completed).toList();
      _manualCycles = _allLogs.where((log) =>
        log.triggeredBy == 'manual' &&
        log.action == IrrigationAction.completed
      ).toList();
    } catch (e) {
      debugPrint('Error loading irrigation logs: $e');
      _allLogs = [];
      _manualCycles = [];
    }
  }

  Future<List<IrrigationLogModel>> _loadLogsWithFallback(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _logService.getLogsInRange(userId, startDate, endDate);
    } catch (e) {
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('requires an index')) {
        debugPrint('Index not ready, using fallback query');
        final allLogs = await _logService.getUserLogs(userId);
        return allLogs.where((log) {
          return log.timestamp.isAfter(startDate) && 
                 log.timestamp.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
      }
      rethrow;
    }
  }

  Future<void> _loadAlerts(String userId, DateTime start, DateTime end) async {
    try {
      if (_fields.isNotEmpty) {
        final farmId = _fields.first['id']!;
        final allAlerts = await _alertService.getFarmAlerts(farmId);
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

  void _calculateMetrics() {
    final filteredLogs = this.filteredLogs;
    final filteredScheduledCycles = this.filteredScheduledCycles;

    final completedLogs = filteredLogs.where((log) =>
      log.action == IrrigationAction.completed
    ).toList();

    _totalWaterUsed = completedLogs.fold<double>(
      0.0,
      (sum, log) => sum + (log.waterUsed ?? 0.0),
    );

    _avgWaterPerCycle = completedLogs.isNotEmpty
        ? _totalWaterUsed / completedLogs.length
        : 0.0;

    _fieldWiseUsage.clear();
    for (var log in completedLogs) {
      final fieldName = log.zoneName;
      _fieldWiseUsage[fieldName] = (_fieldWiseUsage[fieldName] ?? 0.0) + (log.waterUsed ?? 0.0);
    }

    _dailyWaterUsage.clear();
    for (var log in completedLogs) {
      final dateKey = DateFormat('MM/dd').format(log.timestamp);
      _dailyWaterUsage[dateKey] = (_dailyWaterUsage[dateKey] ?? 0.0) + (log.waterUsed ?? 0.0);
    }

    final totalScheduled = filteredScheduledCycles.length;
    final completedScheduled = filteredScheduledCycles.where((s) => s.status == 'completed').length;
    _completionRate = totalScheduled > 0 ? (completedScheduled / totalScheduled) * 100 : 0.0;
    _missedCycles = filteredScheduledCycles.where((s) =>
      s.status == 'scheduled' &&
      (s.nextRun ?? s.startTime).isBefore(DateTime.now())
    ).length;
  }

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        final base = _selectedDate ?? now;
        start = DateTime(base.year, base.month, base.day);
        break;
      case ReportPeriod.weekly:
        final daysToMonday = (now.weekday - DateTime.monday) % 7;
        start = now.subtract(Duration(days: daysToMonday));
        start = DateTime(start.year, start.month, start.day);
        break;
      case ReportPeriod.monthly:
        start = DateTime(now.year, now.month, 1);
        break;
    }

    return {'start': start, 'end': end};
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

  // Filter setters
  void setSelectedPeriod(ReportPeriod period) {
    _selectedPeriod = period;
    loadReportData();
  }

  void setCycleTypeFilter(CycleTypeFilter filter) {
    _cycleTypeFilter = filter;
    _calculateMetrics();
    notifyListeners();
  }

  void setStatusFilter(StatusFilter filter) {
    _statusFilter = filter;
    _calculateMetrics();
    notifyListeners();
  }

  void setSelectedFieldFilter(String? fieldId) {
    _selectedFieldFilter = fieldId;
    _calculateMetrics();
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    loadReportData();
  }

  void resetFilters() {
    _selectedFieldFilter = null;
    _cycleTypeFilter = CycleTypeFilter.all;
    _statusFilter = StatusFilter.all;
    _calculateMetrics();
    notifyListeners();
  }

  @override
  void dispose() {
    _runningCyclesSubscription?.cancel();
    super.dispose();
  }
}
