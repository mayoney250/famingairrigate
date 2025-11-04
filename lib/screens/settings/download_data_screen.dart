import 'package:flutter/material.dart';

class DownloadDataScreen extends StatelessWidget {
  const DownloadDataScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Data')),
      body: const Center(child: Text('This is the Download Data page. A summary of your data and activities will appear here.')),
    );
  }
}

