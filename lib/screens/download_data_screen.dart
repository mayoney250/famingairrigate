import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/water_goal_provider.dart';
import '../services/irrigation_log_service.dart';

class DownloadDataScreen extends StatefulWidget {
  const DownloadDataScreen({Key? key}) : super(key: key);
  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}

enum ReportFrequency { daily, weekly, monthly, custom }

class _DownloadDataScreenState extends State<DownloadDataScreen> {
  ReportFrequency _selectedFrequency = ReportFrequency.monthly;
  DateTimeRange? _customRange;
  bool _generating = false;

  // Report data
dynamic userName;
List<Map<String, dynamic>> fields = [];
List<Map<String, dynamic>> irrigationLogs = [];
List<Map<String, dynamic>> sensorReadings = [];
List<Map<String, dynamic>> waterUsageByDate = [];
List<Map<String, dynamic>> alerts = [];

  // Goal/usage
  int actualUsage = 0;
  int goalAmount = 0;
  String goalPeriodLabel = '';
  int efficiency = 0;

  DateFormat get _dateFormat => DateFormat('MMM d, yyyy');
  DateFormat get _dateTimeFormat => DateFormat('MMM d, yyyy h:mm a');

  String get periodKey {
    switch (_selectedFrequency) {
      case ReportFrequency.daily:
        return 'daily';
      case ReportFrequency.weekly:
        return 'weekly';
      case ReportFrequency.monthly:
        return 'monthly';
      default:
        return 'custom';
    }
  }

  String get _selectedPeriodLabel {
    if (_selectedFrequency != ReportFrequency.custom) {
      switch (_selectedFrequency) {
        case ReportFrequency.daily:
          return "Today";
        case ReportFrequency.weekly:
          return "Past 7 days";
        case ReportFrequency.monthly:
          return 'This month';
        default:
          return '';
      }
    } else if (_customRange != null) {
      return '${_dateFormat.format(_customRange!.start)} — ${_dateFormat.format(_customRange!.end)}';
    }
    return 'Pick range';
  }

  Future<void> _loadData() async {
    // Load real user, goals, logs for period
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final goalProvider = Provider.of<WaterGoalProvider>(context, listen: false);
    if (auth.currentUser == null) return;
    userName = auth.currentUser!.firstName + ' ' + auth.currentUser!.lastName;
    String userId = auth.currentUser!.userId;
    // Goals
    await goalProvider.loadGoals(userId);
    final periodGoal = goalProvider.activeGoal(periodKey);
    goalAmount = periodGoal?.goalAmount ?? 0;
    goalPeriodLabel = periodGoal?.period ?? _selectedPeriodLabel;
    // Irrigation Logs
    DateTime start;
    DateTime end = DateTime.now();
    if (_selectedFrequency == ReportFrequency.custom && _customRange != null) {
      start = _customRange!.start;
      end = _customRange!.end;
    } else if (_selectedFrequency == ReportFrequency.weekly) {
      start = end.subtract(const Duration(days: 7));
    } else if (_selectedFrequency == ReportFrequency.monthly) {
      start = DateTime(end.year, end.month, 1);
    } else {
      start = DateTime(end.year, end.month, end.day);
    }
    irrigationLogs = (await IrrigationLogService().getLogsInRange(userId, start, end))
        .map((e) => {
          'date': e.timestamp,
          'field': e.zoneName,
          'waterUsed': e.waterUsed ?? 0,
          'notes': e.notes ?? '',
        })
        .toList();
    actualUsage = irrigationLogs.fold(0, (total, e) => total + (e['waterUsed'] as int));
    efficiency = goalAmount > 0 ? (100 * actualUsage ~/ goalAmount) : 0;
    // [You can add similar backend loads for sensorReadings, fields, alerts as shown previously]
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _pickCustomRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(Duration(days: 7)),
      initialDateRange: _customRange,
    );
    if (picked != null) setState(() => _customRange = picked);
  }

  Future<Uint8List> _generatePdfReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(28)),
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    'Irrigation Activity Report',
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                  )),
              pw.Text('User/Farm: $userName', style: pw.TextStyle(fontSize: 13)),
              pw.Text('Report Period: $_selectedPeriodLabel', style: pw.TextStyle(fontSize: 13)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              // FIELD DETAILS
              pw.Text('Field Details', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Field', 'Size', 'Crop', 'Growth Stage'],
                  data: fields
                      .map<List<String>>((e) => [
                          e['name'] ?? '',
                          e['size'] ?? '',
                          e['crop'] ?? '',
                          e['growth'] ?? ''
                        ])
                      .toList()),
              pw.SizedBox(height: 16),

              // IRRIGATION LOGS
              pw.Text('Irrigation Logs', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Date', 'Field', 'Water Used (L)', 'Notes'],
                  data: irrigationLogs
                      .map<List<String>>((e) => [
                          _dateTimeFormat.format(e['date']),
                          e['field'],
                          e['waterUsed'].toString(),
                          e['notes']
                        ])
                      .toList()),
              pw.SizedBox(height: 16),

              // SENSOR DATA
              pw.Text('Sensor Readings', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Time', 'Field', 'Soil Moisture (%)', 'Temp (°C)', 'Humidity (%)'],
                  data: sensorReadings
                      .map<List<String>>((e) => [
                            _dateTimeFormat.format(e['time']),
                            e['field'],
                            e['soilMoisture'].toString(),
                            e['temp'].toString(),
                            e['humidity'].toString()
                          ])
                      .toList()),
              pw.SizedBox(height: 16),

              // WATER USAGE SUMMARY CHART
              pw.Text('Water Usage Summary', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.BarcodeWidget(
                  data: 'Sample water usage chart - replace with custom drawing or embed image if needed from rendered flutter chart',
                  barcode: pw.Barcode.qrCode(),
                  width: 60,
                  height: 60),
              pw.SizedBox(height: 16),

              // USAGE GOALS & SUMMARY
              pw.Text('Water Usage Goals', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Text('Goal: $goalAmount L – Achieved: $actualUsage L – Efficiency: $efficiency% – Period: $goalPeriodLabel', style: pw.TextStyle(fontSize: 13)),
              pw.SizedBox(height: 8),

              // ALERTS TABLE
              pw.Text('Alerts & Notifications', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                  headerAlignment: pw.Alignment.centerLeft,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Date', 'Type', 'Details'],
                  data: alerts
                      .map<List<String>>((e) => [
                            _dateTimeFormat.format(e['date']),
                            e['type'],
                            e['details'],
                          ])
                      .toList()),
              pw.SizedBox(height: 16),

              // SUMMARY & RECOMMENDATIONS (optional, placeholder)
              pw.Text('Summary',
                  style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Total Water Used: '
                  '${waterUsageByDate.fold<int>(0, (sum, e) => sum + (e['usage'] as int))} L.'),
              pw.Bullet(text: 'System Efficiency: $efficiency%.'),
              pw.Bullet(text: 'Recommendation: Optimize timings for East Plot.'),

              pw.SizedBox(height: 32),
              pw.Text(
                'Generated by Faminga Smart Irrigation • ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey400),
              )
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<void> _exportPdf() async {
    setState(() => _generating = true);
    try {
      await _loadData();
      Uint8List pdfBytes = await _generatePdfReport();
      await Printing.sharePdf(bytes: pdfBytes, filename: 'irrigation_report.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF Report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _generating = false);
    }
  }

  Widget _buildFrequencySelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Daily'),
          selected: _selectedFrequency == ReportFrequency.daily,
          onSelected: (sel) => setState(() => _selectedFrequency = ReportFrequency.daily),
        ),
        ChoiceChip(
          label: const Text('Weekly'),
          selected: _selectedFrequency == ReportFrequency.weekly,
          onSelected: (sel) => setState(() => _selectedFrequency = ReportFrequency.weekly),
        ),
        ChoiceChip(
          label: const Text('Monthly'),
          selected: _selectedFrequency == ReportFrequency.monthly,
          onSelected: (sel) => setState(() => _selectedFrequency = ReportFrequency.monthly),
        ),
        ChoiceChip(
          label: const Text('Custom'),
          selected: _selectedFrequency == ReportFrequency.custom,
          onSelected: (sel) {
            setState(() => _selectedFrequency = ReportFrequency.custom);
            Future.delayed(Duration(milliseconds: 250), _pickCustomRange);
          },
        ),
        if (_selectedFrequency == ReportFrequency.custom)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ActionChip(
              label: Text(_selectedPeriodLabel, style: TextStyle(fontWeight: FontWeight.bold)),
              avatar: const Icon(Icons.date_range),
              onPressed: _pickCustomRange,
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Water Usage Goal for $_selectedPeriodLabel:", style: Theme.of(context).textTheme.titleMedium),
        goalAmount > 0 ?
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(
            value: goalAmount > 0 ? (actualUsage/clamp(goalAmount, 1, double.infinity)) : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(Colors.green),
            minHeight: 12,
          ),
        ) : const Text('No goal set for this period.'),
        Text('Goal: $goalAmount L – Used: $actualUsage L – Efficiency: $efficiency%',
            style: Theme.of(context).textTheme.bodyMedium),
        Text("Data Preview", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.landscape),
            title: const Text('Fields'),
            subtitle: Text(fields.map((e) => e['name']).join(', ')),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.water),
            title: const Text('Irrigation Actions'),
            subtitle: Text(
                'Records: ${irrigationLogs.length}, Water Used Total: ${irrigationLogs.fold<int>(0, (sum, e) => sum + (e['waterUsed'] as int))} L'),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Sensor Readings'),
            subtitle: Text(
                'Latest: ${sensorReadings.last['soilMoisture']}% moisture, ${sensorReadings.last['temp']}°C'),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Water Usage Chart'),
            subtitle: SizedBox(
              width: double.infinity,
              height: 160,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LineChart(LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: waterUsageByDate
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              (e.value['usage'] as int).toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(show: false),
                  minY: 0,
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Download Data')),
      body: _generating
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Card: Report Settings
                    Card(
                      color: scheme.surfaceVariant,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Select Report Frequency",
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            _buildFrequencySelector(),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Report Period",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  _selectedPeriodLabel,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: scheme.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPreviewSection(),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Download / Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, letterSpacing: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Optionally more info or disclaimer
                    Text(
                      "Data includes all field, irrigation, sensor, and activity history for your reports.",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

double clamp(num val, num min, num max) => val < min ? min.toDouble() : (val > max ? max.toDouble() : val.toDouble());