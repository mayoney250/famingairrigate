import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/irrigation_model.dart';
import '../../services/irrigation_service.dart';

class IrrigationListScreen extends StatefulWidget {
  const IrrigationListScreen({super.key});

  @override
  State<IrrigationListScreen> createState() => _IrrigationListScreenState();
}

class _IrrigationListScreenState extends State<IrrigationListScreen> {
  final IrrigationService _irrigationService = IrrigationService();
  bool _isLoading = false;
  List<IrrigationModel> _irrigationSystems = [];

  @override
  void initState() {
    super.initState();
    _loadIrrigationSystems();
  }

  Future<void> _loadIrrigationSystems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.userId;

      if (userId != null) {
        final systems = await _irrigationService.getUserIrrigationSystems(
          userId,
        );
        setState(() {
          _irrigationSystems = systems;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load irrigation systems',
        backgroundColor: FamingaBrandColors.statusWarning,
        colorText: FamingaBrandColors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamingaBrandColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Irrigation Systems'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIrrigationSystems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: FamingaBrandColors.primaryOrange,
              ),
            )
          : _irrigationSystems.isEmpty
              ? _buildEmptyState()
              : _buildIrrigationList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add irrigation system
        },
        icon: const Icon(Icons.add),
        label: const Text('Add System'),
        backgroundColor: FamingaBrandColors.primaryOrange,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.water_drop_outlined,
            size: 80,
            color: FamingaBrandColors.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            'No irrigation systems yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: FamingaBrandColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first irrigation system to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FamingaBrandColors.disabled,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _irrigationSystems.length,
      itemBuilder: (context, index) {
        final system = _irrigationSystems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              // TODO: Navigate to irrigation detail
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          system.systemName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: system.isActive
                              ? FamingaBrandColors.statusSuccess
                                  .withValues(alpha: 0.1)
                              : FamingaBrandColors.disabled.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          system.isActive ? 'Active' : 'Inactive',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: system.isActive
                                        ? FamingaBrandColors.statusSuccess
                                        : FamingaBrandColors.disabled,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.water,
                    'Type',
                    system.irrigationType,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.water_drop,
                    'Source',
                    system.waterSource,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.settings,
                    'Mode',
                    system.isAutomated ? 'Automated' : 'Manual',
                  ),
                  if (system.totalWaterUsed != null &&
                      system.totalWaterUsed! > 0) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.opacity,
                      'Water Used',
                      '${system.totalWaterUsed!.toStringAsFixed(2)} m³',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: FamingaBrandColors.primaryOrange,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FamingaBrandColors.disabled,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

