import 'package:flutter/material.dart';
import '../config/colors.dart';

/// Notification template with consistent branding
class NotificationTemplate {
  final String titlePrefix;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String category;

  const NotificationTemplate({
    required this.titlePrefix,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.category,
  });
}

/// Notification templates for all types - Faminga branded
class NotificationTemplates {
  // Test Notifications
  static const test = NotificationTemplate(
    titlePrefix: '🧪',
    icon: Icons.science,
    color: Color(0xFF9C27B0), // Purple
    backgroundColor: Color(0xFFF3E5F5),
    category: 'Test',
  );

  // Irrigation Status - Primary Green/Orange theme
  static const irrigationStarted = NotificationTemplate(
    titlePrefix: '▶️',
    icon: Icons.play_circle_filled,
    color: FamingaBrandColors.primaryOrange,
    backgroundColor: Color(0xFFFFF3E0),
    category: 'Irrigation',
  );

  static const irrigationCompleted = NotificationTemplate(
    titlePrefix: '✅',
    icon: Icons.check_circle,
    color: FamingaBrandColors.darkGreen,
    backgroundColor: Color(0xFFE8F5E9),
    category: 'Irrigation',
  );

  static const irrigationStopped = NotificationTemplate(
    titlePrefix: '⏹️',
    icon: Icons.stop_circle,
    color: Color(0xFFFF9800), // Orange
    backgroundColor: Color(0xFFFFF3E0),
    category: 'Irrigation',
  );

  static const irrigationFailed = NotificationTemplate(
    titlePrefix: '❌',
    icon: Icons.error,
    color: Color(0xFFD32F2F), // Red
    backgroundColor: Color(0xFFFFEBEE),
    category: 'Irrigation',
  );

  // AI Recommendations - Smart/Tech themed
  static const aiIrrigate = NotificationTemplate(
    titlePrefix: '🤖💧',
    icon: Icons.psychology,
    color: Color(0xFF2196F3), // Blue
    backgroundColor: Color(0xFFE3F2FD),
    category: 'AI Recommendation',
  );

  static const aiHold = NotificationTemplate(
    titlePrefix: '🤖⏸️',
    icon: Icons.pause_circle_filled,
    color: Color(0xFF607D8B), // Blue Grey
    backgroundColor: Color(0xFFECEFF1),
    category: 'AI Recommendation',
  );

  static const aiAlert = NotificationTemplate(
    titlePrefix: '🤖⚠️',
    icon: Icons.warning_amber,
    color: Color(0xFFFF9800), // Orange
    backgroundColor: Color(0xFFFFF3E0),
    category: 'AI Alert',
  );

  // Sensor Alerts - Critical/Warning themed
  static const irrigationNeeded = NotificationTemplate(
    titlePrefix: '💧',
    icon: Icons.water_drop,
    color: Color(0xFF2196F3), // Blue
    backgroundColor: Color(0xFFE3F2FD),
    category: 'Sensor Alert',
  );

  static const waterLow = NotificationTemplate(
    titlePrefix: '⚠️',
    icon: Icons.water_drop_outlined,
    color: Color(0xFFFF9800), // Orange
    backgroundColor: Color(0xFFFFF3E0),
    category: 'Sensor Alert',
  );

  static const sensorOffline = NotificationTemplate(
    titlePrefix: '📴',
    icon: Icons.sensors_off,
    color: Color(0xFFD32F2F), // Red
    backgroundColor: Color(0xFFFFEBEE),
    category: 'Sensor Alert',
  );

  // Schedule & Weather - Informational
  static const scheduleReminder = NotificationTemplate(
    titlePrefix: '⏰',
    icon: Icons.schedule,
    color: FamingaBrandColors.primaryOrange,
    backgroundColor: Color(0xFFFFF3E0),
    category: 'Schedule',
  );

  static const rainForecast = NotificationTemplate(
    titlePrefix: '🌧️',
    icon: Icons.cloud,
    color: Color(0xFF2196F3), // Blue
    backgroundColor: Color(0xFFE3F2FD),
    category: 'Weather',
  );

  // Generic
  static const generic = NotificationTemplate(
    titlePrefix: '🔔',
    icon: Icons.notifications,
    color: FamingaBrandColors.textSecondary,
    backgroundColor: Color(0xFFF5F5F5),
    category: 'General',
  );

  /// Get template for notification type
  static NotificationTemplate getTemplate(String type) {
    switch (type.toLowerCase()) {
      // Test
      case 'test':
        return test;

      // Irrigation
      case 'irrigationstarted':
      case 'irrigation_started':
        return irrigationStarted;

      case 'irrigationcompleted':
      case 'irrigation_completed':
        return irrigationCompleted;

      case 'irrigationstopped':
      case 'irrigation_stopped':
        return irrigationStopped;

      case 'irrigationfailed':
      case 'irrigation_failed':
        return irrigationFailed;

      // AI
      case 'aiirrigate':
      case 'ai_irrigate':
        return aiIrrigate;

      case 'aihold':
      case 'ai_hold':
        return aiHold;

      case 'aialert':
      case 'ai_alert':
        return aiAlert;

      // Sensors
      case 'irrigationneeded':
      case 'irrigation_needed':
        return irrigationNeeded;

      case 'waterlow':
      case 'water_low':
        return waterLow;

      case 'sensoroffline':
      case 'sensor_offline':
        return sensorOffline;

      // Schedule & Weather
      case 'schedulereminder':
      case 'schedule_reminder':
        return scheduleReminder;

      case 'rainforecast':
      case 'rain_forecast':
        return rainForecast;

      // Default
      default:
        return generic;
    }
  }

  /// Get formatted title with emoji prefix
  static String getFormattedTitle(String type, String baseTitle) {
    final template = getTemplate(type);
    return '${template.titlePrefix} $baseTitle';
  }

  /// Get all notification categories
  static List<String> get categories => [
        'Test',
        'Irrigation',
        'AI Recommendation',
        'AI Alert',
        'Sensor Alert',
        'Schedule',
        'Weather',
        'General',
      ];
}

/// Notification severity levels
enum NotificationSeverity {
  info,
  low,
  medium,
  high,
  critical,
}

/// Severity configuration
class SeverityConfig {
  final Color color;
  final IconData icon;
  final String label;

  const SeverityConfig({
    required this.color,
    required this.icon,
    required this.label,
  });

  static SeverityConfig getConfig(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const SeverityConfig(
          color: Color(0xFFD32F2F),
          icon: Icons.warning,
          label: 'CRITICAL',
        );
      case 'high':
        return const SeverityConfig(
          color: Color(0xFFFF5722),
          icon: Icons.error_outline,
          label: 'HIGH',
        );
      case 'medium':
        return const SeverityConfig(
          color: Color(0xFFFF9800),
          icon: Icons.warning_amber_outlined,
          label: 'MEDIUM',
        );
      case 'low':
        return const SeverityConfig(
          color: Color(0xFF4CAF50),
          icon: Icons.info_outline,
          label: 'LOW',
        );
      default:
        return const SeverityConfig(
          color: Color(0xFF2196F3),
          icon: Icons.notifications_outlined,
          label: 'INFO',
        );
    }
  }
}
