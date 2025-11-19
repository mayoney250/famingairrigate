import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../utils/l10n_extensions.dart';

class DownloadDataScreen extends StatefulWidget {
  const DownloadDataScreen({super.key});

  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}

class _DownloadDataScreenState extends State<DownloadDataScreen> {
  String _selectedPeriod = 'Daily';
  DateTimeRange? _customRange;

  // ------- Replace this with REAL DATA from your DB/Hive/Firebase --------
  final List<Map<String, dynamic>> irrigationLogs = [
    {
      'field': 'Field A',
      'crop': 'Tomatoes',
      'growthStage': 'Flowering',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'waterUsed': 1200
    },
    {
      'field': 'Field B',
      'crop': 'Maize',
      'growthStage': 'Vegetative',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'waterUsed': 900
    },
  ];

  // ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filterLogs();
    final summary = _generateReportData(filteredLogs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download My Irrigation Report'),
        elevation: 3,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.agriculture, size: 40, color: Colors.green),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Farmer-Friendly Irrigation Report',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Get insights into your farm\'s water usage, crop performance, and practical recommendations to optimize irrigation.',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Report Period Selection Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Report Period',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isExpanded: true,
                          items: ['Daily', 'Weekly', 'Monthly', 'Custom']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (value) async {
                            if (value == "Custom") {
                              DateTimeRange? picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _customRange = picked;
                                  _selectedPeriod = 'Custom';
                                });
                              }
                            } else {
                              setState(() {
                                _selectedPeriod = value!;
                                _customRange = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (_customRange != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected: ${DateFormat('dd MMM yyyy').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customRange!.end)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryItem(
                          'Total Water',
                          '${summary['totalWater'].toStringAsFixed(0)} L',
                          Icons.water_drop,
                        ),
                        _buildSummaryItem(
                          'Fields',
                          '${summary['fieldsCount']}',
                          Icons.landscape,
                        ),
                        _buildSummaryItem(
                          'Events',
                          '${summary['eventCount']}',
                          Icons.event,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Data Preview Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.preview, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Data Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filteredLogs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No irrigation data found for the selected period.\nTry selecting a different time range.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.grass, color: Colors.green),
                              ),
                              title: Text(
                                "${log['field']} • ${log['crop']}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Stage: ${log['growthStage']}\nWater: ${log['waterUsed']} L",
                              ),
                              trailing: Text(
                                DateFormat('dd/MM').format(log['date']),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Download Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _exportPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.download, size: 24),
                label: const Text(
                  'Generate & Download PDF Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }



  // -------------------------------------------------------------------------------------
  // FILTER LOGS BASED ON PERIOD
  // -------------------------------------------------------------------------------------
  List<Map<String, dynamic>> _filterLogs() {
    return irrigationLogs.where((log) {
      final date = log['date'] as DateTime;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'Daily':
          return date.isAfter(now.subtract(const Duration(days: 1)));

        case 'Weekly':
          return date.isAfter(now.subtract(const Duration(days: 7)));

        case 'Monthly':
          return date.isAfter(now.subtract(const Duration(days: 30)));

        case 'Custom':
          if (_customRange == null) return false;
          return date.isAfter(_customRange!.start) &&
              date.isBefore(_customRange!.end.add(const Duration(days: 1)));

        default:
          return true;
      }
    }).toList();
  }

  // -------------------------------------------------------------------------------------
  // GENERATE PDF WITH COMPREHENSIVE FARMER-FRIENDLY REPORT
  // -------------------------------------------------------------------------------------
  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final filtered = _filterLogs();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to generate report.")),
      );
      return;
    }

    // ========== COLLECT DATA FOR REPORT ==========
    final reportData = _generateReportData(filtered);

    // ========== DETERMINE PERIOD TEXT ==========
    final periodText = _selectedPeriod == "Custom" && _customRange != null
        ? "${DateFormat('dd MMM yyyy').format(_customRange!.start)} to ${DateFormat('dd MMM yyyy').format(_customRange!.end)}"
        : _getPeriodLabel(_selectedPeriod);

    // ========== BUILD PDF PAGES ==========
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => _buildReportContent(reportData, periodText),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.success)),
    );
  }

  // -------------------------------------------------------------------------------------
  // BUILD COMPLETE REPORT CONTENT
  // -------------------------------------------------------------------------------------
  List<pw.Widget> _buildReportContent(
    Map<String, dynamic> data,
    String periodText,
  ) {
    return [
      // ===== REPORT TITLE & DATE RANGE =====
      pw.Text(
        "Faminga Irrigation Report",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 28,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        "Farmer-Friendly Analysis & Recommendations",
        style: pw.TextStyle(
          fontSize: 13,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Divider(thickness: 2, color: PdfColors.green800),
      pw.SizedBox(height: 8),

      // Period info
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Report Period:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.Text(
            periodText,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Generated:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
      pw.SizedBox(height: 16),

      // ===== FARM SUMMARY OVERVIEW =====
      pw.Text(
        "📊 Farm Summary Overview",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green800, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              "Total Water Used:",
              "${data['totalWater'].toStringAsFixed(0)} Liters",
            ),
            _buildSummaryRow(
              "Number of Irrigated Fields:",
              "${data['fieldsCount']}",
            ),
            _buildSummaryRow(
              "Irrigation Events Recorded:",
              "${data['eventCount']}",
            ),
            _buildSummaryRow(
              "Most Irrigated Field:",
              data['topField'],
            ),
            _buildSummaryRow(
              "Most Irrigated Crop:",
              data['topCrop'],
            ),
            _buildSummaryRow(
              "Average Water per Event:",
              "${data['avgWaterPerEvent'].toStringAsFixed(0)} L",
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),

      // ===== DETAILED IRRIGATION TABLE =====
      pw.Text(
        "📋 Detailed Irrigation Records",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(
          color: PdfColors.grey400,
          width: 0.5,
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.2),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.2),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.green800),
            children: [
              _buildTableHeaderCell("Date"),
              _buildTableHeaderCell("Field"),
              _buildTableHeaderCell("Crop"),
              _buildTableHeaderCell("Stage"),
              _buildTableHeaderCell("Water (L)"),
            ],
          ),
          // Data rows
          ...data['logs'].map<pw.TableRow>((log) {
            return pw.TableRow(
              children: [
                _buildTableCell(DateFormat('dd MMM').format(log['date'])),
                _buildTableCell(log['field']),
                _buildTableCell(log['crop']),
                _buildTableCell(log['growthStage']),
                _buildTableCell("${log['waterUsed']}"),
              ],
            );
          }).toList(),
        ],
      ),
      pw.SizedBox(height: 14),

      // ===== INSIGHTS & ANALYSIS =====
      pw.Text(
        "💡 Insights & Analysis",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue800, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ...data['insights'].map<pw.Widget>((insight) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "• ${insight['title']}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    insight['description'],
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      pw.SizedBox(height: 14),

      // ===== WEATHER IMPACT NOTES =====
      pw.Text(
        "🌤️ Weather Impact & Observations",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.orange800, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              data['weatherNotes'],
              style: const pw.TextStyle(fontSize: 10, height: 1.4),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),

      // ===== RECOMMENDATIONS FOR FARMER =====
      pw.Text(
        "🌱 Recommendations for Better Irrigation",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green800, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Suggested Irrigation Adjustments:",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            ...data['irrigationAdjustments']
                .map<pw.Widget>((adj) => pw.Text(
                      "• $adj",
                      style: const pw.TextStyle(fontSize: 10, height: 1.3),
                    ))
                .toList(),
            pw.SizedBox(height: 10),
            pw.Text(
              "Water-Saving Tips:",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            ...data['savingsTips']
                .map<pw.Widget>((tip) => pw.Text(
                      "• $tip",
                      style: const pw.TextStyle(fontSize: 10, height: 1.3),
                    ))
                .toList(),
            pw.SizedBox(height: 10),
            pw.Text(
              "Crop-Specific Advice:",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            ...data['cropAdvice']
                .map<pw.Widget>((advice) => pw.Text(
                      "• $advice",
                      style: const pw.TextStyle(fontSize: 10, height: 1.3),
                    ))
                .toList(),
          ],
        ),
      ),
      pw.SizedBox(height: 16),

      // Footer
      pw.Divider(thickness: 1, color: PdfColors.grey400),
      pw.SizedBox(height: 4),
      pw.Text(
        "This report was generated by Faminga Irrigation Management System. For questions or support, contact your agricultural advisor.",
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey700,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    ];
  }

  // -------------------------------------------------------------------------------------
  // GENERATE COMPREHENSIVE REPORT DATA
  // -------------------------------------------------------------------------------------
  Map<String, dynamic> _generateReportData(List<Map<String, dynamic>> logs) {
    // Basic calculations
    final totalWater = logs.fold<int>(0, (sum, log) => sum + (log['waterUsed'] as int));
    final fieldsSet = logs.map((log) => log['field']).toSet();
    final cropsSet = logs.map((log) => log['crop']).toSet();
    final avgWaterPerEvent = logs.isNotEmpty ? totalWater / logs.length : 0;

    // Most irrigated field and crop
    final topField = _getTopField(logs);
    final topCrop = _getTopCrop(logs);

    // Field-wise water usage
    final fieldWaterUsage = <String, int>{};
    for (var log in logs) {
      fieldWaterUsage[log['field']] =
          (fieldWaterUsage[log['field']] ?? 0) + (log['waterUsed'] as int);
    }

    // Crop-wise water usage
    final cropWaterUsage = <String, int>{};
    for (var log in logs) {
      cropWaterUsage[log['crop']] =
          (cropWaterUsage[log['crop']] ?? 0) + (log['waterUsed'] as int);
    }

    // Generate insights
    final insights = _generateInsights(logs, fieldWaterUsage, cropWaterUsage);

    // Generate weather notes
    final weatherNotes = _generateWeatherNotes(logs);

    // Generate recommendations
    final recommendations = _generateRecommendations(logs, fieldWaterUsage);

    return {
      'totalWater': totalWater,
      'fieldsCount': fieldsSet.length,
      'eventCount': logs.length,
      'topField': topField,
      'topCrop': topCrop,
      'avgWaterPerEvent': avgWaterPerEvent,
      'logs': logs,
      'insights': insights,
      'weatherNotes': weatherNotes,
      'irrigationAdjustments': recommendations['adjustments'],
      'savingsTips': recommendations['savings'],
      'cropAdvice': recommendations['advice'],
    };
  }

  // -------------------------------------------------------------------------------------
  // GENERATE INSIGHTS
  // -------------------------------------------------------------------------------------
  List<Map<String, String>> _generateInsights(
    List<Map<String, dynamic>> logs,
    Map<String, int> fieldWaterUsage,
    Map<String, int> cropWaterUsage,
  ) {
    final insights = <Map<String, String>>[];

    // Insight 1: Average water usage
    if (logs.isNotEmpty) {
      final avgWater = logs.fold<int>(0, (sum, log) => sum + (log['waterUsed'] as int)) /
          logs.length;
      insights.add({
        'title': 'Average Water Usage per Event',
        'description':
            'Your fields receive an average of ${avgWater.toStringAsFixed(0)}L per irrigation event. This helps ensure consistent watering patterns.'
      });
    }

    // Insight 2: Water usage variation
    if (fieldWaterUsage.length > 1) {
      final maxUsage = fieldWaterUsage.values.reduce((a, b) => a > b ? a : b);
      final minUsage = fieldWaterUsage.values.reduce((a, b) => a < b ? a : b);
      final ratio = maxUsage / minUsage;

      if (ratio > 2.0) {
        insights.add({
          'title': 'Significant Variation in Field Water Usage',
          'description':
              'There is a ${ratio.toStringAsFixed(1)}x difference between the most and least irrigated fields. Consider checking soil types or field conditions.'
        });
      }
    }

    // Insight 3: Crop-specific usage
    if (cropWaterUsage.length > 1) {
      final crops = cropWaterUsage.entries.toList();
      crops.sort((a, b) => b.value.compareTo(a.value));
      final topCrop = crops.first;
      insights.add({
        'title': 'Highest Water-Demanding Crop',
        'description':
            '${topCrop.key} is consuming the most water (${topCrop.value}L total). This is typical during growth and flowering stages.'
      });
    }

    // Insight 4: Daily frequency
    if (logs.isNotEmpty) {
      final daysInPeriod =
          logs.last['date'].difference(logs.first['date']).inDays + 1;
      final eventsPerDay = logs.length / daysInPeriod;
      insights.add({
        'title': 'Irrigation Frequency',
        'description':
            'You irrigate an average of ${eventsPerDay.toStringAsFixed(1)} times per day. Adjust based on soil moisture and weather conditions.'
      });
    }

    return insights;
  }

  // -------------------------------------------------------------------------------------
  // GENERATE WEATHER NOTES
  // -------------------------------------------------------------------------------------
  String _generateWeatherNotes(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return 'No weather data available. Monitor rainfall and temperature to optimize irrigation timing.';
    }

    // Simulate weather impact analysis
    return 'During the reporting period, consider the following weather factors:\n\n'
        '• Rainfall: Higher rainfall typically reduces irrigation needs. If recent rains occurred, you may reduce water amounts.\n'
        '• Temperature: Hot and dry periods require more frequent irrigation and higher water volumes.\n'
        '• Soil Moisture: Use available soil moisture sensors to adjust irrigation timing and reduce water waste.\n'
        '• Wind: Strong winds increase evaporation; increase irrigation slightly during windy periods.\n\n'
        'Monitor weather forecasts and soil conditions to fine-tune your irrigation schedule for maximum efficiency.';
  }

  // -------------------------------------------------------------------------------------
  // GENERATE RECOMMENDATIONS
  // -------------------------------------------------------------------------------------
  Map<String, List<String>> _generateRecommendations(
    List<Map<String, dynamic>> logs,
    Map<String, int> fieldWaterUsage,
  ) {
    final adjustments = <String>[];
    final savings = <String>[];
    final advice = <String>[];

    // Adjustments based on usage patterns
    if (fieldWaterUsage.isNotEmpty) {
      final avgUsage =
          fieldWaterUsage.values.fold<int>(0, (sum, v) => sum + v) /
              fieldWaterUsage.length;

      final highUsageFields = fieldWaterUsage.entries
          .where((e) => e.value > avgUsage * 1.3)
          .toList();

      if (highUsageFields.isNotEmpty) {
        for (var field in highUsageFields) {
          adjustments.add(
              '${field.key} is using ${((field.value / avgUsage - 1) * 100).toStringAsFixed(0)}% more water than average. Check for soil compaction or leaks.');
        }
      }

      final lowUsageFields = fieldWaterUsage.entries
          .where((e) => e.value < avgUsage * 0.7)
          .toList();

      if (lowUsageFields.isNotEmpty) {
        for (var field in lowUsageFields) {
          adjustments.add(
              '${field.key} is receiving less water than other fields. Verify if this is intentional or if irrigation system needs adjustment.');
        }
      }
    }

    // Savings tips (always useful)
    savings.addAll([
      'Use soil moisture sensors to irrigate only when needed, reducing water waste by 15-30%.',
      'Schedule irrigation during early morning or late evening to reduce evaporation loss.',
      'Group fields with similar water needs and irrigate together to optimize system efficiency.',
      'Monitor rainfall forecasts and skip irrigation 1-2 days after significant rain.',
      'Check for leaks in irrigation lines; even small leaks can waste hundreds of liters monthly.',
      'Mulch fields where possible to reduce soil evaporation and water requirements.',
    ]);

    // Crop-specific advice
    final uniqueCrops = logs.map((log) => log['crop']).toSet();
    for (var crop in uniqueCrops) {
      advice.addAll(_getCropSpecificAdvice(crop));
    }

    return {
      'adjustments': adjustments.isEmpty
          ? ['Your irrigation pattern looks balanced. Continue monitoring soil moisture regularly.']
          : adjustments,
      'savings': savings,
      'advice': advice.isEmpty ? _getGenericCropAdvice() : advice,
    };
  }

  // -------------------------------------------------------------------------------------
  // CROP-SPECIFIC ADVICE
  // -------------------------------------------------------------------------------------
  List<String> _getCropSpecificAdvice(String crop) {
    final cropLower = crop.toLowerCase();

    if (cropLower.contains('tomato')) {
      return [
        'Tomatoes need 25-35mm of water per week. Increase frequency during flowering and fruit development.',
        'Avoid wetting leaves during irrigation to prevent fungal diseases.',
      ];
    } else if (cropLower.contains('maize')) {
      return [
        'Maize (corn) requires deep watering, especially during tasseling and silking stages.',
        'Reduce irrigation once grain reaches maturity to improve grain quality.',
      ];
    } else if (cropLower.contains('rice')) {
      return [
        'Rice fields should maintain 5-10cm water depth during most of the growing season.',
        'Drain fields 2-3 weeks before harvest to improve grain quality.',
      ];
    } else if (cropLower.contains('vegetable')) {
      return [
        'Most vegetables prefer consistent moisture without waterlogging.',
        'Water at the base of plants; avoid overhead irrigation when possible.',
      ];
    } else if (cropLower.contains('bean')) {
      return [
        'Beans need moderate water, especially during flowering. Overwatering causes foliage at the expense of pods.',
      ];
    }

    return _getGenericCropAdvice();
  }

  List<String> _getGenericCropAdvice() {
    return [
      'Monitor soil moisture regularly using simple tests (squeeze test) or sensors.',
      'Most crops need 25-50mm of water per week depending on stage and weather.',
      'Water deeply but less frequently to encourage deep root growth.',
    ];
  }

  // -------------------------------------------------------------------------------------
  // HELPER METHODS FOR TABLE RENDERING
  // -------------------------------------------------------------------------------------
  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'Daily':
        return 'Last 24 Hours';
      case 'Weekly':
        return 'Last 7 Days';
      case 'Monthly':
        return 'Last 30 Days';
      default:
        return period;
    }
  }

  // -------------------------------------------------------------------------------------
  // HELPER: MOST IRRIGATED FIELD
  // -------------------------------------------------------------------------------------
  String _getTopField(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return "N/A";

    final Map<String, int> usage = {};

    for (var log in logs) {
      usage[log['field']] = (usage[log['field']] ?? 0) + (log['waterUsed'] as int);
    }

    final top = usage.entries.reduce((a, b) => a.value > b.value ? a : b);
    return "${top.key} (${top.value} L)";
  }

  // -------------------------------------------------------------------------------------
  // HELPER: MOST IRRIGATED CROP
  // -------------------------------------------------------------------------------------
  String _getTopCrop(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return "N/A";

    final Map<String, int> usage = {};

    for (var log in logs) {
      usage[log['crop']] = (usage[log['crop']] ?? 0) + (log['waterUsed'] as int);
    }

    final top = usage.entries.reduce((a, b) => a.value > b.value ? a : b);
    return "${top.key} (${top.value} L)";
  }
}
