import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class DownloadDataScreen extends StatefulWidget {
  const DownloadDataScreen({super.key});

  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}

class _DownloadDataScreenState extends State<DownloadDataScreen> {
  String _selectedPeriod = 'Daily';
  DateTimeRange? _customRange;

  // Example data: replace with your app’s real data
  final List<Map<String, dynamic>> irrigationLogs = [
    {
      'field': 'Field A',
      'crop': 'Tomatoes',
      'growthStage': 'Flowering',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'waterUsed': 1200 // in liters
    },
    {
      'field': 'Field B',
      'crop': 'Maize',
      'growthStage': 'Vegetative',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'waterUsed': 900
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download My Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Report Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: ['Daily', 'Weekly', 'Monthly', 'Custom'].map((period) {
                return DropdownMenuItem(value: period, child: Text(period));
              }).toList(),
              onChanged: (value) async {
                if (value == 'Custom') {
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
            const SizedBox(height: 20),
            const Text(
              'Data Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: irrigationLogs.length,
                itemBuilder: (context, index) {
                  final log = irrigationLogs[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text('${log['field']} - ${log['crop']}'),
                      subtitle: Text(
                          'Stage: ${log['growthStage']}, Water used: ${log['waterUsed']} L'),
                      trailing: Text(
                        DateFormat('yyyy-MM-dd').format(log['date']),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final dateRangeText = _selectedPeriod == 'Custom' && _customRange != null
        ? '${DateFormat('yyyy-MM-dd').format(_customRange!.start)} to ${DateFormat('yyyy-MM-dd').format(_customRange!.end)}'
        : _selectedPeriod;

    // Filter logs based on period
    final filteredLogs = irrigationLogs.where((log) {
      if (_selectedPeriod == 'Daily') {
        return log['date'].isAfter(DateTime.now().subtract(const Duration(days: 1)));
      } else if (_selectedPeriod == 'Weekly') {
        return log['date'].isAfter(DateTime.now().subtract(const Duration(days: 7)));
      } else if (_selectedPeriod == 'Monthly') {
        return log['date'].isAfter(DateTime.now().subtract(const Duration(days: 30)));
      } else if (_selectedPeriod == 'Custom' && _customRange != null) {
        return log['date'].isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
            log['date'].isBefore(_customRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Faminga Irrigation Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Report Period: $dateRangeText', style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Field', 'Crop', 'Growth Stage', 'Date', 'Water Used (L)'],
              data: filteredLogs.map((log) {
                return [
                  log['field'],
                  log['crop'],
                  log['growthStage'],
                  DateFormat('yyyy-MM-dd').format(log['date']),
                  log['waterUsed'].toString()
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Summary: Total water used: ${filteredLogs.fold<num>(0, (sum, log) => sum + (log['waterUsed'] ?? 0)).toInt()} L',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF report generated successfully!')),
    );
  }
}




































