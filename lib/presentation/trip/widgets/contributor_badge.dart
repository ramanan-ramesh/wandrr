import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Widget to display a contributor name with an indicator if they're no longer a tripmate.
/// Uses a compact icon-based design to save horizontal space.
class ContributorBadge extends StatelessWidget {
  final String contributorName;
  final String currentUserName;
  final List<String> currentContributors;
  final String? localizedYouText;

  const ContributorBadge({
    super.key,
    required this.contributorName,
    required this.currentUserName,
    required this.currentContributors,
    this.localizedYouText,
  });

  bool get isCurrentUser => contributorName == currentUserName;

  bool get isNoLongerTripmate => !currentContributors.contains(contributorName);

  String get displayName {
    if (isCurrentUser) {
      return localizedYouText ?? 'You';
    }
    return contributorName.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    if (isNoLongerTripmate) {
      return _buildRemovedTripmateBadge(context, isLightTheme);
    }

    return _buildNormalBadge(context);
  }

  Widget _buildNormalBadge(BuildContext context) {
    return TextButton.icon(
      onPressed: null,
      label: Text(
        displayName,
        style: TextStyle(
          fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRemovedTripmateBadge(BuildContext context, bool isLightTheme) {
    return Tooltip(
      message: 'No longer a tripmate',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLightTheme
              ? AppColors.warning.withValues(alpha: 0.1)
              : AppColors.warningLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLightTheme
                ? AppColors.warning.withValues(alpha: 0.3)
                : AppColors.warningLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off,
              size: 14,
              color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            ),
            const SizedBox(width: 4),
            Text(
              displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version of ContributorBadge that uses only an icon for removed tripmates
/// Suitable for tight spaces like lists
class CompactContributorBadge extends StatelessWidget {
  final String contributorName;
  final String currentUserName;
  final List<String> currentContributors;
  final String? localizedYouText;
  final TextStyle? textStyle;

  const CompactContributorBadge({
    super.key,
    required this.contributorName,
    required this.currentUserName,
    required this.currentContributors,
    this.localizedYouText,
    this.textStyle,
  });

  bool get isCurrentUser => contributorName == currentUserName;

  bool get isNoLongerTripmate => !currentContributors.contains(contributorName);

  String get displayName {
    if (isCurrentUser) {
      return localizedYouText ?? 'You';
    }
    return contributorName.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final effectiveTextStyle =
        textStyle ?? Theme.of(context).textTheme.bodyMedium;

    if (isNoLongerTripmate) {
      return Tooltip(
        message: '$displayName (no longer a tripmate)',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off,
              size: 14,
              color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            ),
            const SizedBox(width: 2),
            Text(
              displayName,
              style: effectiveTextStyle?.copyWith(
                color:
                    isLightTheme ? AppColors.warning : AppColors.warningLight,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.lineThrough,
                decorationColor: isLightTheme
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.warningLight.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      displayName,
      style: effectiveTextStyle?.copyWith(
        fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
