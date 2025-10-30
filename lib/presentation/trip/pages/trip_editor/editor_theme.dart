import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Common theming utilities for trip editor pages
/// Provides consistent styling across TravelEditor, LodgingEditor, etc.
class EditorTheme {
  // Spacing constants
  static const double _cardBorderRadiusBig = 28.0;
  static const double _cardBorderRadiusSmall = 24.0;
  static const double _sectionBorderRadius = 16.0;
  static const double _innerBorderRadius = 12.0;

  static const double cardMarginHorizontalBig = 24.0;
  static const double cardMarginHorizontalSmall = 16.0;
  static const double cardMarginVerticalBig = 16.0;
  static const double cardMarginVerticalSmall = 12.0;

  static const double _sectionMarginHorizontal = 20.0;
  static const double _sectionMarginVertical = 12.0;
  static const double _sectionPadding = 16.0;

  static const double _iconContainerPadding = 8.0;
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 20.0;

  // Border widths
  static const double _cardBorderWidth = 2.0;
  static const double _sectionBorderWidth = 1.5;

  // Shadow blur radii
  static const double _cardShadowBlurBig = 20.0;
  static const double _cardShadowBlurSmall = 16.0;
  static const double _standardShadowBlur = 8.0;

  // Shadow offsets
  static Offset _cardShadowOffsetBig = const Offset(0, 10);
  static Offset _cardShadowOffsetSmall = const Offset(0, 8);
  static Offset _standardShadowOffset = const Offset(0, 4);
  static Offset _badgeShadowOffset = const Offset(2, 2);

  /// Get card border radius based on layout size
  static double getCardBorderRadius(bool isBigLayout) {
    return isBigLayout ? _cardBorderRadiusBig : _cardBorderRadiusSmall;
  }

  /// Build card decoration with gradient and shadows
  static BoxDecoration buildCardDecoration({
    required bool isLightTheme,
    required bool isBigLayout,
    double? borderRadius,
  }) {
    final radius = borderRadius ?? getCardBorderRadius(isBigLayout);
    return BoxDecoration(
      gradient: _buildCardGradient(isLightTheme),
      borderRadius: BorderRadius.circular(radius),
      border: _buildCardBorder(isLightTheme),
      boxShadow: [_buildCardShadow(isLightTheme, isBigLayout)],
    );
  }

  static LinearGradient buildPrimaryGradient(bool isLightTheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLightTheme
          ? [AppColors.brandPrimary, AppColors.brandPrimaryDark]
          : [AppColors.brandPrimaryLight, AppColors.brandPrimaryDark],
    );
  }

  static BoxShadow buildBadgeShadow(bool isLightTheme) {
    return BoxShadow(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.4),
      blurRadius: _standardShadowBlur,
      offset: _badgeShadowOffset,
    );
  }

  /// Build section container with standard styling
  static Widget buildSection({
    required BuildContext context,
    required Widget child,
  }) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _sectionMarginHorizontal,
        vertical: _sectionMarginVertical,
      ),
      padding: const EdgeInsets.all(_sectionPadding),
      decoration: _buildSectionDecoration(isLightTheme),
      child: child,
    );
  }

  /// Build section header with icon and title
  static Widget buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    bool useLargeText = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        const SizedBox(width: 8),
        Text(
          title,
          style: (useLargeText
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Get text field decoration
  static InputDecoration buildTextFieldDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_innerBorderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }

  static LinearGradient _buildCardGradient(bool isLightTheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLightTheme
          ? [
              AppColors.brandPrimaryLight.withValues(alpha: 0.15),
              AppColors.brandAccent.withValues(alpha: 0.08),
            ]
          : [
              AppColors.darkSurface,
              AppColors.darkSurfaceVariant,
            ],
    );
  }

  static Border _buildCardBorder(bool isLightTheme) {
    return Border.all(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.3)
          : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
      width: _cardBorderWidth,
    );
  }

  static BoxShadow _buildCardShadow(bool isLightTheme, bool isBigLayout) {
    return BoxShadow(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.3),
      blurRadius: isBigLayout ? _cardShadowBlurBig : _cardShadowBlurSmall,
      offset: isBigLayout ? _cardShadowOffsetBig : _cardShadowOffsetSmall,
    );
  }

  static BoxDecoration _buildSectionDecoration(bool isLightTheme) {
    return BoxDecoration(
      color: isLightTheme
          ? Colors.white.withValues(alpha: 0.7)
          : AppColors.darkSurface.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(_sectionBorderRadius),
      border: Border.all(
        color: isLightTheme
            ? AppColors.brandPrimary.withValues(alpha: 0.2)
            : AppColors.brandPrimaryLight.withValues(alpha: 0.2),
        width: _sectionBorderWidth,
      ),
    );
  }
}
