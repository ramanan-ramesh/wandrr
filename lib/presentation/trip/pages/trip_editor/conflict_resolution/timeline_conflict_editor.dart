import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

import 'conflicting_sights_section.dart';
import 'conflicting_stays_section.dart';
import 'conflicting_transits_section.dart';

/// Editor for resolving timeline conflicts when editing transits, stays, or sights.
/// This is a reusable component that can be embedded in different contexts.
///
/// Note: This class is deprecated. Use ConflictResolutionSubpage instead.
@Deprecated('Use ConflictResolutionSubpage instead')
class TimelineConflictEditor extends StatefulWidget {
  final TripEntityUpdatePlan conflictPlan;
  final VoidCallback onChanged;
  final DateTime tripStartDate;
  final DateTime tripEndDate;

  const TimelineConflictEditor({
    super.key,
    required this.conflictPlan,
    required this.onChanged,
    required this.tripStartDate,
    required this.tripEndDate,
  });

  @override
  State<TimelineConflictEditor> createState() => _TimelineConflictEditorState();
}

class _TimelineConflictEditorState extends State<TimelineConflictEditor> {
  @override
  Widget build(BuildContext context) {
    final plan = widget.conflictPlan;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConflictSummaryHeader(context, isLightTheme),
        const SizedBox(height: 16),
        _buildConflictWarning(context, isLightTheme),
        const SizedBox(height: 8),
        if (plan.transitChanges.isNotEmpty)
          ConflictingTransitsSection(
            conflictingTransits: plan.transitChanges.toList(),
            tripStartDate: widget.tripStartDate,
            tripEndDate: widget.tripEndDate,
            onChanged: widget.onChanged,
          ),
        if (plan.stayChanges.isNotEmpty)
          ConflictingStaysSection(
            conflictingStays: plan.stayChanges.toList(),
            tripStartDate: widget.tripStartDate,
            tripEndDate: widget.tripEndDate,
            onChanged: widget.onChanged,
          ),
        if (plan.sightChanges.isNotEmpty)
          ConflictingSightsSection(
            conflictingSights: plan.sightChanges.toList(),
            tripStartDate: widget.tripStartDate,
            tripEndDate: widget.tripEndDate,
            onChanged: widget.onChanged,
          ),
      ],
    );
  }

  Widget _buildConflictSummaryHeader(BuildContext context, bool isLightTheme) {
    final plan = widget.conflictPlan;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLightTheme
              ? [
                  AppColors.warning.withValues(alpha: 0.15),
                  AppColors.warningLight.withValues(alpha: 0.08),
                ]
              : [
                  AppColors.warning.withValues(alpha: 0.3),
                  AppColors.warningLight.withValues(alpha: 0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLightTheme ? AppColors.warning : AppColors.warningLight,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline Conflicts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.warning
                            : AppColors.warningLight,
                      ),
                ),
                Text(
                  '${plan.totalConflicts} item${plan.totalConflicts > 1 ? 's' : ''} need attention',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictWarning(BuildContext context, bool isLightTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.infoLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Items marked for deletion will be removed. Update times to keep them.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLightTheme
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
