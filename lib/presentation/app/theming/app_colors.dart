import 'package:flutter/material.dart';

/// Wandrr App Color Palette
/// Based on the green logo with black text, creating a vibrant and cohesive design system
class AppColors {
  // Brand Colors - Primary Green Palette (inspired by your logo)
  static const Color brandPrimary =
      Color(0xFF009E6D); // Slightly deeper green for AppBar
  static const Color brandPrimaryLight = Color(0xFF4DDBAD); // Light emerald
  static const Color brandPrimaryDark = Color(0xFF00A076); // Dark emerald
  static const Color brandAccent = Color(0xFF00E6A8); // Bright mint accent

  // Secondary Brand Colors
  static const Color brandSecondary =
      Color(0xFF2D3748); // Rich charcoal (instead of pure black)
  static const Color brandSecondaryLight = Color(0xFF4A5568); // Medium charcoal
  static const Color brandSecondaryDark = Color(0xFF1A202C); // Deep charcoal

  // Neutral Palette
  static const Color neutral100 = Color(0xFFF7FAFC); // Off white
  static const Color neutral200 = Color(0xFFEDF2F7); // Light gray
  static const Color neutral300 = Color(0xFFE2E8F0); // Medium light gray
  static const Color neutral400 = Color(0xFFCBD5E0); // Medium gray
  static const Color neutral500 = Color(0xFFA0AEC0); // Medium dark gray
  static const Color neutral600 = Color(0xFF718096); // Dark gray
  static const Color neutral700 = Color(0xFF4A5568); // Very dark gray
  static const Color neutral800 = Color(0xFF2D3748); // Almost black
  static const Color neutral900 = Color(0xFF1A202C); // Rich black

  // Functional Colors
  static const Color success = Color(0xFF38A169); // Success green
  static const Color successLight = Color(0xFF68D391);
  static const Color warning = Color(0xFFED8936); // Warm orange
  static const Color warningLight = Color(0xFFFBD38D);
  static const Color error = Color(0xFFE53E3E); // Error red
  static const Color errorLight = Color(0xFFFEB2B2);
  static const Color info = Color(0xFF3182CE); // Info blue
  static const Color infoLight = Color(0xFF90CDF4);

  // Travel-themed accent colors (for categories, charts, etc.)
  static const List<Color> travelAccents = [
    Color(0xFF667EEA), // Sky blue
    Color(0xFFF093FB), // Sunset pink
    Color(0xFF4FACFE), // Ocean blue
    Color(0xFFFECD3D), // Golden sun
    Color(0xFF43E97B), // Forest green
    Color(0xFFFD79A8), // Tropical pink
    Color(0xFF6C5CE7), // Adventure purple
    Color(0xFFFA7970), // Coral red
  ];

  // Surface colors for light theme
  static const Color lightSurface =
      Color(0xFFFAFAFA); // Subtle off-white for cards
  static const Color lightSurfaceVariant =
      Color(0xFFF1F5F9); // More distinct gray for background
  static const Color lightBackground =
      Color(0xFFF1F5F9); // Same as lightSurfaceVariant

  // Surface colors for dark theme
  static const Color darkSurface = Color(0xFF334155); // Lighter for cards
  static const Color darkSurfaceVariant = Color(0xFF1E293B); // Medium dark
  static const Color darkBackground =
      Color(0xFF0F172A); // Very dark for scaffold

  // Gradient combinations
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandPrimary, brandAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper methods for opacity variations
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Color scheme generators
  static ColorScheme lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: brandPrimary,
    onPrimary: Colors.white,
    primaryContainer: brandPrimaryLight,
    onPrimaryContainer: brandSecondary,
    secondary: brandSecondary,
    onSecondary: Colors.white,
    secondaryContainer: neutral200,
    onSecondaryContainer: brandSecondary,
    tertiary: info,
    onTertiary: Colors.white,
    error: error,
    onError: Colors.white,
    errorContainer: errorLight,
    onErrorContainer: brandSecondary,
    surface: lightBackground, // Use distinct gray background for scaffold
    onSurface: brandSecondary,
    surfaceContainerHighest:
        lightSurface, // Use pure white for containers/cards
    onSurfaceVariant: neutral700,
    outline: neutral400,
    outlineVariant: neutral300,
    shadow: neutral900,
    scrim: neutral900,
    inverseSurface: darkSurface,
    onInverseSurface: neutral100,
    inversePrimary: brandPrimaryLight,
  );

  static ColorScheme darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: brandPrimaryLight,
    onPrimary: brandSecondary,
    primaryContainer: brandPrimaryDark,
    onPrimaryContainer: neutral100,
    secondary: neutral400,
    onSecondary: brandSecondary,
    secondaryContainer: neutral700,
    onSecondaryContainer: neutral200,
    tertiary: infoLight,
    onTertiary: brandSecondary,
    error: errorLight,
    onError: brandSecondary,
    errorContainer: error,
    onErrorContainer: errorLight,
    surface: darkBackground, // Use very dark background for scaffold
    onSurface: neutral100,
    surfaceContainerHighest:
        darkSurface, // Use lighter color for containers/cards
    onSurfaceVariant: neutral300,
    outline: neutral500,
    outlineVariant: neutral600,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: lightSurface,
    onInverseSurface: neutral800,
    inversePrimary: brandPrimary,
  );
}
