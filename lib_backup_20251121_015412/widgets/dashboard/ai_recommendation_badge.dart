import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../../services/irrigation_ai_service.dart';
import '../../models/ai_recommendation_model.dart';
import '../../config/colors.dart';

/// Standalone AI Recommendation Badge Widget
/// Fetches and displays irrigation advice without requiring provider changes
class AIRecommendationBadge extends StatefulWidget {
  final String userId;
  final String fieldId;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final String cropType;
  final VoidCallback? onRecommendationReceived;

  const AIRecommendationBadge({
    Key? key,
    required this.userId,
    required this.fieldId,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.cropType,
    this.onRecommendationReceived,
  }) : super(key: key);

  @override
  State<AIRecommendationBadge> createState() => _AIRecommendationBadgeState();
}

class _AIRecommendationBadgeState extends State<AIRecommendationBadge> {
  late IrrigationAIService _aiService;
  AIRecommendation? _recommendation;
  bool _loading = false;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _aiService = IrrigationAIService();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    // Debounce: don't call more than once every 30 seconds
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(seconds: 30)) {
      return;
    }

    setState(() => _loading = true);
    try {
      _lastFetchTime = DateTime.now();
      final rec = await _aiService.getIrrigationAdvice(
        userId: widget.userId,
        fieldId: widget.fieldId,
        soilMoisture: widget.soilMoisture,
        temperature: widget.temperature,
        humidity: widget.humidity,
        cropType: widget.cropType,
      );

      if (mounted) {
        setState(() {
          _recommendation = rec;
          _loading = false;
        });
        widget.onRecommendationReceived?.call();
      }
    } catch (e) {
      dev.log('Error fetching AI recommendation: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AIRecommendationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if key sensor data changed significantly
    if ((oldWidget.soilMoisture - widget.soilMoisture).abs() > 5 ||
        (oldWidget.temperature - widget.temperature).abs() > 2) {
      _fetchRecommendation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _recommendation == null) {
      return SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    FamingaBrandColors.primaryOrange),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI advice',
              style: TextStyle(fontSize: 10, color: FamingaBrandColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_recommendation == null) {
      return const SizedBox.shrink();
    }

    return _buildRecommendationChip(_recommendation!);
  }

  Widget _buildRecommendationChip(AIRecommendation rec) {
    final recommendation = rec.recommendation.toLowerCase();
    Color bgColor;
    Color textColor;
    IconData icon;

    if (recommendation.contains('irrigate')) {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icons.opacity;
    } else if (recommendation.contains('hold')) {
      bgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade700;
      icon = Icons.pause_circle_outline;
    } else if (recommendation.contains('alert')) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.warning_rounded;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Tooltip(
        message: rec.reasoning,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 6),
                Text(
                  rec.recommendation,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'AI (${(rec.confidence * 100).toInt()}%)',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
