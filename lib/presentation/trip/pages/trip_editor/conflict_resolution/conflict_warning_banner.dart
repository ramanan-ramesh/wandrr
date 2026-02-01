import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// A warning banner that shows when conflicts are detected.
/// Provides a button to switch to the conflict resolution view.
class ConflictWarningBanner extends StatelessWidget {
  final TripEntityUpdatePlan? conflictPlan;
  final VoidCallback onViewConflicts;

  /// If true, uses a more compact layout suitable for inline use
  final bool isCompact;

  const ConflictWarningBanner({
    super.key,
    required this.conflictPlan,
    required this.onViewConflicts,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (conflictPlan == null || !conflictPlan!.hasConflicts) {
      return const SizedBox.shrink();
    }

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final plan = conflictPlan!;

    if (isCompact) {
      return _buildCompactBanner(context, plan, isLightTheme);
    }

    return _buildFullBanner(context, plan, isLightTheme);
  }

  Widget _buildCompactBanner(
      BuildContext context, TripEntityUpdatePlan plan, bool isLightTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.warning.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.warningLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${plan.totalConflicts} conflict${plan.totalConflicts > 1 ? 's' : ''} detected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight,
                  ),
            ),
          ),
          TextButton(
            onPressed: onViewConflicts,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              foregroundColor:
                  isLightTheme ? AppColors.warning : AppColors.warningLight,
            ),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBanner(
      BuildContext context, TripEntityUpdatePlan plan, bool isLightTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLightTheme
              ? [
                  AppColors.warning.withValues(alpha: 0.15),
                  AppColors.error.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.warning.withValues(alpha: 0.3),
                  AppColors.errorLight.withValues(alpha: 0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.warningLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.totalConflicts} Conflict${plan.totalConflicts > 1 ? 's' : ''} Detected',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.warning
                            : AppColors.warningLight,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildConflictSummary(plan),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onViewConflicts,
            style: FilledButton.styleFrom(
              backgroundColor: isLightTheme
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.warningLight.withValues(alpha: 0.2),
              foregroundColor:
                  isLightTheme ? AppColors.warning : AppColors.warningLight,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  String _buildConflictSummary(TripEntityUpdatePlan plan) {
    final parts = <String>[];
    if (plan.transitChanges.isNotEmpty) {
      parts.add(
          '${plan.transitChanges.length} transit${plan.transitChanges.length > 1 ? 's' : ''}');
    }
    if (plan.stayChanges.isNotEmpty) {
      parts.add(
          '${plan.stayChanges.length} stay${plan.stayChanges.length > 1 ? 's' : ''}');
    }
    if (plan.sightChanges.isNotEmpty) {
      parts.add(
          '${plan.sightChanges.length} sight${plan.sightChanges.length > 1 ? 's' : ''}');
    }
    return parts.join(', ');
  }
}
