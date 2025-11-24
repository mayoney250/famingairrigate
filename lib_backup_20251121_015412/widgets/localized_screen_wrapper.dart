import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Wraps a screen to ensure it rebuilds when language changes
/// This fixes the issue where only some screens update on language change
/// 
/// Usage:
/// ```dart
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return LocalizedScreenWrapper(
///       builder: (context) => _buildScreen(context),
///     );
///   }
/// }
/// ```
class LocalizedScreenWrapper extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const LocalizedScreenWrapper({
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to language changes and rebuild when language changes
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        // The child rebuilds whenever LanguageProvider notifies
        // This ensures AppLocalizations.of(context) always returns the current locale
        return builder(context);
      },
    );
  }
}
