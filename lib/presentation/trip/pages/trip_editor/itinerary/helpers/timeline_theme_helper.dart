import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Helper class for getting themed colors in the timeline
class TimelineThemeHelper {
  final BuildContext context;

  bool get _isLightTheme => context.isLightTheme;

  const TimelineThemeHelper(this.context);

  Color getIconBackgroundColor(Color iconColor) {
    return _isLightTheme
        ? iconColor.withValues(alpha: 0.15)
        : iconColor.withValues(alpha: 0.25);
  }

  Color getCardBackgroundColor() {
    return _isLightTheme ? Colors.white : AppColors.darkSurface;
  }

  Color getCardBorderColor() {
    return _isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
  }

  Color getTimelineConnectorColor() {
    return _isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.3);
  }

  Color getTextColor() {
    return _isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
  }

  Color getSubtitleColor() {
    return _isLightTheme ? AppColors.neutral700 : AppColors.neutral400;
  }

  Color getCardShadowColor() {
    return (_isLightTheme ? AppColors.brandPrimary : Colors.black)
        .withValues(alpha: 0.15);
  }

  Color getNotesBackgroundColor() {
    return _isLightTheme ? AppColors.neutral300 : AppColors.neutral700;
  }

  Color getDeleteButtonBackgroundColor() {
    return _isLightTheme
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.error.withValues(alpha: 0.2);
  }

  Color getEmptyStateIconColor() {
    return _isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
  }

  Color getEmptyStateTextColor() {
    return _isLightTheme ? AppColors.neutral600 : AppColors.neutral400;
  }
}
