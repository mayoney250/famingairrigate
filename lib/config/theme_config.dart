import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class ThemeConfig {
  // Private constructor
  ThemeConfig._();

  /// Light Theme Configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: FamingaBrandColors.primaryOrange,
      secondary: FamingaBrandColors.darkGreen,
      surface: FamingaBrandColors.white,
      error: FamingaBrandColors.statusWarning,
      onPrimary: FamingaBrandColors.white,
      onSecondary: FamingaBrandColors.white,
      onSurface: FamingaBrandColors.textPrimary,
      onError: FamingaBrandColors.white,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: FamingaBrandColors.backgroundLight,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: FamingaBrandColors.white,
      foregroundColor: FamingaBrandColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: FamingaBrandColors.iconColor,
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.textPrimary,
      ),
    ),
    
    // Text Theme
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: FamingaBrandColors.textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: FamingaBrandColors.textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: FamingaBrandColors.textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: FamingaBrandColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: FamingaBrandColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: FamingaBrandColors.textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: FamingaBrandColors.textPrimary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: FamingaBrandColors.textPrimary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: FamingaBrandColors.textPrimary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: FamingaBrandColors.textPrimary,
      ),
    ),
    
    // Card Theme
    cardTheme: const CardThemeData(
      color: FamingaBrandColors.cardBackground,
      elevation: 2,
      shadowColor: FamingaBrandColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FamingaBrandColors.primaryButton,
        foregroundColor: FamingaBrandColors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FamingaBrandColors.primaryOrange,
        side: const BorderSide(
          color: FamingaBrandColors.primaryOrange,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FamingaBrandColors.primaryOrange,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FamingaBrandColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FamingaBrandColors.borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FamingaBrandColors.borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FamingaBrandColors.primaryOrange,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FamingaBrandColors.statusWarning,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FamingaBrandColors.statusWarning,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: FamingaBrandColors.disabled,
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: FamingaBrandColors.iconColor,
      size: 24,
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FamingaBrandColors.primaryOrange,
      foregroundColor: FamingaBrandColors.white,
      elevation: 4,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: FamingaBrandColors.white,
      selectedItemColor: FamingaBrandColors.primaryOrange,
      unselectedItemColor: FamingaBrandColors.disabled,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: FamingaBrandColors.borderColor,
      thickness: 1,
      space: 1,
    ),
  );

  /// Dark Theme Configuration
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: FamingaBrandColors.primaryOrange,
      secondary: FamingaBrandColors.darkGreen,
      surface: Color(0xFF1E1E1E),
      error: FamingaBrandColors.statusWarning,
      onPrimary: FamingaBrandColors.white,
      onSecondary: FamingaBrandColors.white,
      onSurface: FamingaBrandColors.white,
      onError: FamingaBrandColors.white,
    ),
    
    scaffoldBackgroundColor: FamingaBrandColors.backgroundDark,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: FamingaBrandColors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: FamingaBrandColors.primaryOrange,
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: FamingaBrandColors.white,
      ),
    ),
    
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

