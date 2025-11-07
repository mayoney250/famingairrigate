import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../config/colors.dart';
import '../../services/irrigation_log_service.dart';
import '../../services/irrigation_schedule_service.dart';
import '../../services/sensor_data_service.dart';
import '../../services/alert_service.dart';
import '../../models/irrigation_log_model.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../models/user_model.dart';
import '../../models/alert_model.dart';

enum ReportPeriod { daily, weekly, monthly }
enum CycleTypeFilter { all, scheduled, manual }
enum StatusFilter { all, scheduled, running, completed, stopped }

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
  
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  CycleTypeFilter _cycleTypeFilter = CycleTypeFilter.all;
  StatusFilter _statusFilter = StatusFilter.all;
  String? _selectedFieldFilter;
  
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
  int _overWateringCount = 0;
  int _underWateringCount = 0;
  
  // Notifications
  List<AlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  @override
  void dispose() {
    _runningCyclesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadReportData() async {
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
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    }

    setState(() => _isLoading = false);
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
      
      // Filter cycles by date range and separate by status
      final filteredSchedules = allSchedules.where((schedule) {
        if (!schedule.isActive) return false;
        final scheduleTime = schedule.nextRun ?? schedule.startTime;
        return scheduleTime.isAfter(start.subtract(const Duration(days: 1))) && 
               scheduleTime.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      // Separate scheduled vs running
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
      _allLogs = await _loadLogsWithFallback(userId, start, end);
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
      // Get user's first field to get alerts (alerts are farmId-scoped)
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
    // Water Usage
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

    // Field-wise breakdown
    _fieldWiseUsage.clear();
    for (var log in completedLogs) {
      final fieldName = log.zoneName;
      _fieldWiseUsage[fieldName] = (_fieldWiseUsage[fieldName] ?? 0.0) + (log.waterUsed ?? 0.0);
    }

    // Daily water usage for chart
    _dailyWaterUsage.clear();
    for (var log in completedLogs) {
      final dateKey = DateFormat('MM/dd').format(log.timestamp);
      _dailyWaterUsage[dateKey] = (_dailyWaterUsage[dateKey] ?? 0.0) + (log.waterUsed ?? 0.0);
    }

    // Performance Metrics
    final totalScheduled = _scheduledCycles.length;
    final completedScheduled = _scheduledCycles.where((s) => s.status == 'completed').length;
    _completionRate = totalScheduled > 0 ? (completedScheduled / totalScheduled) * 100 : 0.0;
    _missedCycles = _scheduledCycles.where((s) => 
      s.status == 'scheduled' && 
      (s.nextRun ?? s.startTime).isBefore(DateTime.now())
    ).length;

    // Over/under watering (simplified - based on soil moisture if available)
    _overWateringCount = 0;
    _underWateringCount = 0;
  }

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        start = DateTime(now.year, now.month, now.day);
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

  List<IrrigationScheduleModel> get _filteredScheduledCycles {
    var filtered = _scheduledCycles;
    
    if (_selectedFieldFilter != null) {
      filtered = filtered.where((c) => c.zoneId == _selectedFieldFilter).toList();
    }
    
    if (_statusFilter != StatusFilter.all) {
      filtered = filtered.where((c) => c.status == _statusFilter.name).toList();
    }
    
    return filtered;
  }

  List<IrrigationLogModel> get _filteredManualCycles {
    var filtered = _manualCycles;
    
    if (_selectedFieldFilter != null) {
      filtered = filtered.where((c) => c.zoneId == _selectedFieldFilter).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Irrigation Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: FamingaBrandColors.primaryOrange,
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  color: FamingaBrandColors.primaryOrange,
                  onRefresh: _loadReportData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(isDark),
                        const SizedBox(height: 20),
                        _buildMetadataSection(isDark),
                        const SizedBox(height: 20),
                        _buildWaterUsageSummary(isDark),
                        const SizedBox(height: 20),
                        _buildPerformanceMetrics(isDark),
                        const SizedBox(height: 20),
                        _buildScheduledCyclesSection(isDark),
                        const SizedBox(height: 20),
                        _buildRunningCyclesCard(isDark),
                        const SizedBox(height: 20),
                        _buildManualCyclesSection(isDark),
                        const SizedBox(height: 20),
                        _buildCompletedIrrigationsCard(isDark),
                        const SizedBox(height: 20),
                        _buildNotificationsSection(isDark),
                        const SizedBox(height: 20),
                        _buildChartsSection(isDark),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Field', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedFieldFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Fields')),
                    ..._fields.map((field) => DropdownMenuItem(
                      value: field['id'],
                      child: Text(field['name']!),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedFieldFilter = value),
                ),
                const SizedBox(height: 16),
                const Text('Cycle Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<CycleTypeFilter>(
                  value: _cycleTypeFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: CycleTypeFilter.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => _cycleTypeFilter = value!),
                ),
                const SizedBox(height: 16),
                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<StatusFilter>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: StatusFilter.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => _statusFilter = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFieldFilter = null;
                _cycleTypeFilter = CycleTypeFilter.all;
                _statusFilter = StatusFilter.all;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FamingaBrandColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      color: FamingaBrandColors.primaryOrange,
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height - 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: FamingaBrandColors.statusWarning),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadReportData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FamingaBrandColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildPeriodButton('Daily', ReportPeriod.daily, isDark, isFirst: true)),
          Expanded(child: _buildPeriodButton('Weekly', ReportPeriod.weekly, isDark)),
          Expanded(child: _buildPeriodButton('Monthly', ReportPeriod.monthly, isDark, isLast: true)),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, ReportPeriod period, bool isDark, {bool isFirst = false, bool isLast = false}) {
    final isSelected = _selectedPeriod == period;
    
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = period);
        _loadReportData();
      },
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? const Radius.circular(10) : Radius.zero,
        right: isLast ? const Radius.circular(10) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? FamingaBrandColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(10) : Radius.zero,
            right: isLast ? const Radius.circular(10) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : FamingaBrandColors.darkGreen),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Report Metadata', Icons.info_outline, isDark),
          const SizedBox(height: 16),
          _buildInfoRow('Farmer', _user?.fullName ?? 'N/A', isDark),
          _buildInfoRow('Fields', _fields.isNotEmpty ? _fields.map((f) => f['name']).join(', ') : 'N/A', isDark),
          _buildInfoRow('Report Type', _selectedPeriod.name.toUpperCase(), isDark),
          _buildInfoRow('Generated', 
            _reportGeneratedAt != null 
                ? DateFormat('MMM dd, yyyy hh:mm a').format(_reportGeneratedAt!) 
                : 'N/A', 
            isDark
          ),
        ],
      ),
    );
  }

  Widget _buildWaterUsageSummary(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Water Usage Summary', Icons.water_drop, isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Water', '${_totalWaterUsed.toStringAsFixed(1)}L', isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Avg/Cycle', '${_avgWaterPerCycle.toStringAsFixed(1)}L', isDark),
              ),
            ],
          ),
          if (_fieldWiseUsage.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text('Field-wise Breakdown', style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            )),
            const SizedBox(height: 12),
            ..._fieldWiseUsage.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  )),
                  Text('${entry.value.toStringAsFixed(1)}L', style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: FamingaBrandColors.primaryOrange,
                  )),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance Metrics', Icons.assessment, isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Completion', '${_completionRate.toStringAsFixed(0)}%', isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Missed', _missedCycles.toString(), isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledCyclesSection(bool isDark) {
    final filtered = _filteredScheduledCycles;
    
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Scheduled Cycles (${filtered.length})', Icons.schedule, isDark),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmptyState('No scheduled cycles found', isDark)
          else
            ...filtered.take(5).map((cycle) => _buildCycleListItem(
              zoneName: cycle.zoneName,
              time: DateFormat('MMM dd, hh:mm a').format(cycle.nextRun ?? cycle.startTime),
              duration: '${cycle.durationMinutes} min',
              water: 'Planned',
              status: cycle.status,
              isDark: isDark,
            )),
          if (filtered.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${filtered.length - 5} more cycles',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualCyclesSection(bool isDark) {
    final filtered = _filteredManualCycles;
    
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Manual Cycles (${filtered.length})', Icons.touch_app, isDark),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmptyState('No manual cycles found', isDark)
          else
            ...filtered.take(5).map((cycle) => _buildCycleListItem(
              zoneName: cycle.zoneName,
              time: DateFormat('MMM dd, hh:mm a').format(cycle.timestamp),
              duration: '${cycle.durationMinutes ?? 0} min',
              water: '${cycle.waterUsed?.toStringAsFixed(1) ?? 0}L',
              status: 'completed',
              isDark: isDark,
            )),
          if (filtered.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${filtered.length - 5} more cycles',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRunningCyclesCard(bool isDark) {
    final filteredRunning = _selectedFieldFilter != null
        ? _runningCycles.where((c) => c.zoneId == _selectedFieldFilter).toList()
        : _runningCycles;
    
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle('Running Cycles (${filteredRunning.length})', Icons.play_circle, isDark),
              const SizedBox(width: 8),
              if (filteredRunning.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredRunning.isEmpty)
            _buildEmptyState('No irrigation cycles currently running', isDark)
          else
            ...filteredRunning.map((cycle) => _buildRunningCycleItem(cycle, isDark)),
        ],
      ),
    );
  }

  Widget _buildRunningCycleItem(IrrigationScheduleModel cycle, bool isDark) {
    final startTime = cycle.nextRun ?? cycle.startTime;
    final estimatedEndTime = startTime.add(Duration(minutes: cycle.durationMinutes));
    final elapsed = DateTime.now().difference(startTime);
    final remaining = estimatedEndTime.difference(DateTime.now());
    final progress = elapsed.inMinutes / cycle.durationMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: FamingaBrandColors.primaryOrange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: FamingaBrandColors.primaryOrange.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water,
                  color: FamingaBrandColors.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycle.zoneName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cycle.isManual ? 'Manual Irrigation' : 'Scheduled Irrigation',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RUNNING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildRunningCycleInfo(
                        icon: Icons.access_time,
                        label: 'Started',
                        value: DateFormat('hh:mm a').format(startTime),
                        isDark: isDark,
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRunningCycleInfo(
                        icon: Icons.schedule,
                        label: 'Est. End',
                        value: DateFormat('hh:mm a').format(estimatedEndTime),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildRunningCycleInfo(
                        icon: Icons.timer,
                        label: 'Duration',
                        value: '${cycle.durationMinutes} min',
                        isDark: isDark,
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRunningCycleInfo(
                        icon: Icons.timelapse,
                        label: 'Remaining',
                        value: remaining.inMinutes > 0 ? '${remaining.inMinutes} min' : 'Finishing...',
                        isDark: isDark,
                        valueColor: FamingaBrandColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FamingaBrandColors.primaryOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(FamingaBrandColors.primaryOrange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunningCycleInfo({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FamingaBrandColors.primaryOrange.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildCompletedIrrigationsCard(bool isDark) {
    final completedLogs = _allLogs.where((log) => 
      log.action == IrrigationAction.completed
    ).toList();

    // Apply field filter if selected
    final filteredCompleted = _selectedFieldFilter != null
        ? completedLogs.where((log) => log.zoneId == _selectedFieldFilter).toList()
        : completedLogs;
    
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Completed Irrigations (${filteredCompleted.length})', Icons.check_circle, isDark),
          const SizedBox(height: 16),
          if (filteredCompleted.isEmpty)
            _buildEmptyState('No completed irrigations in this period', isDark)
          else ...[
            // Summary row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompletedStat(
                    'Total',
                    filteredCompleted.length.toString(),
                    Icons.water_drop,
                    isDark,
                  ),
                  Container(width: 1, height: 40, color: Colors.green.withOpacity(0.3)),
                  _buildCompletedStat(
                    'Water Used',
                    '${filteredCompleted.fold<double>(0.0, (sum, log) => sum + (log.waterUsed ?? 0.0)).toStringAsFixed(1)}L',
                    Icons.opacity,
                    isDark,
                  ),
                  Container(width: 1, height: 40, color: Colors.green.withOpacity(0.3)),
                  _buildCompletedStat(
                    'Avg Duration',
                    filteredCompleted.isNotEmpty 
                        ? '${(filteredCompleted.fold<int>(0, (sum, log) => sum + (log.durationMinutes ?? 0)) / filteredCompleted.length).toStringAsFixed(0)}m'
                        : '0m',
                    Icons.timer,
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Recent Completions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            ...filteredCompleted.take(10).map((log) => _buildCompletedIrrigationItem(log, isDark)),
            if (filteredCompleted.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+ ${filteredCompleted.length - 10} more completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedStat(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedIrrigationItem(IrrigationLogModel log, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.zoneName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(log.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('hh:mm a').format(log.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (log.triggeredBy != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.triggeredBy == 'manual' 
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.triggeredBy!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: log.triggeredBy == 'manual' ? Colors.orange : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.timer, size: 11, color: FamingaBrandColors.primaryOrange),
                    const SizedBox(width: 4),
                    Text(
                      '${log.durationMinutes ?? 0} min',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FamingaBrandColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.water_drop,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(height: 2),
              Text(
                '${log.waterUsed?.toStringAsFixed(1) ?? '0'}L',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
              Text(
                'used',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Notifications (${_alerts.length})', Icons.notifications, isDark),
          const SizedBox(height: 16),
          if (_alerts.isEmpty)
            _buildEmptyState('No notifications in this period', isDark)
          else
            ..._alerts.take(5).map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    _getAlertIcon(alert.type),
                    size: 20,
                    color: _getAlertColor(alert.severity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          alert.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd').format(alert.ts),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )),
          if (_alerts.length > 5)
            Text(
              '+ ${_alerts.length - 5} more notifications',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    if (_dailyWaterUsage.isEmpty) return const SizedBox.shrink();
    
    return _buildSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Water Usage Trend', Icons.show_chart, isDark),
          const SizedBox(height: 24),
          _buildBarChart(isDark),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    final sortedEntries = _dailyWaterUsage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxY = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY * 1.2 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)}L',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        sortedEntries[value.toInt()].key,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}L',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: List.generate(
            sortedEntries.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: sortedEntries[index].value,
                  color: FamingaBrandColors.primaryOrange,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: FamingaBrandColors.primaryOrange, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FamingaBrandColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleListItem({
    required String zoneName,
    required String time,
    required String duration,
    required String water,
    required String status,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildStatusIndicator(status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zoneName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  '$time • $duration',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            water,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FamingaBrandColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'running':
        color = FamingaBrandColors.primaryOrange;
        break;
      case 'stopped':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'threshold':
        return Icons.warning;
      case 'valve':
        return Icons.water_drop;
      case 'offline':
        return Icons.signal_wifi_off;
      default:
        return Icons.notifications;
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'high':
      case 'error':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return FamingaBrandColors.primaryOrange;
    }
  }
}
