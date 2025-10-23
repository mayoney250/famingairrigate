import 'package:flutter/material.dart';

/// Official Faminga Brand Colors
/// STRICTLY ENFORCED - Never deviate from these colors
class FamingaBrandColors {
  // Private constructor to prevent instantiation
  FamingaBrandColors._();

  /// Main brand color - Primary Orange
  /// Used for: Primary buttons, icons, highlights, active states
  static const Color primaryOrange = Color(0xFFD47B0F);

  /// Clean white - Pure white
  /// Used for: Card backgrounds, clean UI surfaces
  static const Color white = Color(0xFFFFFFFF);

  /// Dark Green - Professional touch
  /// Used for: Text, secondary buttons, professional elements
  static const Color darkGreen = Color(0xFF2D4D31);

  /// Cream - Light backgrounds
  /// Used for: Page backgrounds, soft surfaces
  static const Color cream = Color(0xFFFFF5EA);

  /// Black - Strong contrast
  /// Used for: Primary text, strong emphasis
  static const Color black = Color(0xFF000000);

  // Semantic color usage (derived from brand colors)
  
  /// Primary button color
  static const Color primaryButton = primaryOrange;
  
  /// Secondary button color
  static const Color secondaryButton = darkGreen;
  
  /// Background light
  static const Color backgroundLight = cream;
  
  /// Background dark
  static const Color backgroundDark = darkGreen;
  
  /// Text primary
  static const Color textPrimary = darkGreen;
  
  /// Text secondary (for less emphasized text)
  static const Color textSecondary = Color(0xFF757575);
  
  /// Text inverse (on dark backgrounds)
  static const Color textInverse = white;
  
  /// Icon color
  static const Color iconColor = primaryOrange;
  
  /// Card background
  static const Color cardBackground = white;
  
  /// Status success
  static const Color statusSuccess = darkGreen;
  
  /// Status warning/error
  static const Color statusWarning = primaryOrange;

  // Additional UI colors
  
  /// Border color
  static const Color borderColor = Color(0xFFE5E5E5);
  
  /// Disabled color
  static const Color disabled = Color(0xFFB0B0B0);
  
  /// Shadow color
  static const Color shadow = Color(0x1A000000);
}

