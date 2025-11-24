import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/l10n_extensions.dart';

class SensorDetailScreen extends StatefulWidget {
  const SensorDetailScreen({super.key});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final sensor = Get.arguments as Map<String, dynamic>?;
    final name = sensor?['name'] ?? 'Sensor';
    final status = (sensor?['status'] ?? 'Offline') as String;
    final isOnline = status.toLowerCase() == 'online';
    final lastSeen = sensor?['lastSeen'] ?? 'Just now';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Readings'),
            Tab(text: 'Info'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? scheme.secondary.withOpacity(0.1)
                      : scheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: isOnline ? scheme.secondary : scheme.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingsTab(context, sensor),
          _buildInfoTab(context, sensor, lastSeen),
        ],
      ),
    );
  }

  Widget _buildReadingsTab(BuildContext context, Map<String, dynamic>? sensor) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: scheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Live',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, color: scheme.secondary, size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    'Latest reading: ${sensor?['value'] ?? '--'}   •   Updated every 5s   •   Source: device',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 24,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.timeline, color: scheme.primary),
                title: Text(
                  'Value: ${(sensor?['value'] ?? '--')}',
                  style: textTheme.bodyLarge,
                ),
                subtitle: Text(
                  'Time: ${DateTime.now().subtract(Duration(minutes: index * 5))}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(BuildContext context, Map<String, dynamic>? sensor, String lastSeen) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.info_outline, color: scheme.primary),
            title: Text(
              'Type',
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              sensor?['type'] ?? '--',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(Icons.place_outlined, color: scheme.primary),
            title: Text(
              'Location',
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              sensor?['location'] ?? '--',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(Icons.bolt_outlined, color: scheme.primary),
            title: Text(
              'Battery',
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              sensor?['battery'] ?? '--',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(Icons.schedule, color: scheme.primary),
            title: Text(
              'Last seen',
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              lastSeen,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


