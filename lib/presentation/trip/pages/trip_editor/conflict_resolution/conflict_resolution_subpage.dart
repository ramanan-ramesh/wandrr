import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_events.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/common/unified_entity_change_editor.dart';

/// A subpage for resolving timeline conflicts within an entity editor.
/// Supports live conflict detection - when resolving one conflict creates another.
class ConflictResolutionSubpage extends StatefulWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onConflictsResolved;
  final VoidCallback? onConflictsChanged;

  const ConflictResolutionSubpage({
    super.key,
    required this.onBackPressed,
    required this.onConflictsResolved,
    this.onConflictsChanged,
  });

  @override
  State<ConflictResolutionSubpage> createState() =>
      _ConflictResolutionSubpageState();
}

class _ConflictResolutionSubpageState extends State<ConflictResolutionSubpage> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final plan = context.tripEntityUpdatePlan;

    if (plan == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, isLightTheme),
        const SizedBox(height: 12),
        _buildStatusBar(context, isLightTheme),
        const SizedBox(height: 12),
        // Conflict editor connected to BLoC
        plan is TripMetadataUpdatePlan
            ? UnifiedEntityChangeEditor.forMetadataUpdate(
                updatePlan: plan,
                onTimeRangeUpdated: (change) {
                  context.addTripEntityEditorEvent(
                      UpdateConflictedEntityTimeRange(change));
                  _handleConflictChanged();
                },
                onDeletionToggled: (change) {
                  context.addTripEntityEditorEvent(
                      ToggleConflictedEntityDeletion(change));
                  _handleConflictChanged();
                },
              )
            : UnifiedEntityChangeEditor.forConflictResolution(
                updatePlan: plan,
                onTimeRangeUpdated: (change) {
                  context.addTripEntityEditorEvent(
                      UpdateConflictedEntityTimeRange(change));
                  _handleConflictChanged();
                },
                onDeletionToggled: (change) {
                  context.addTripEntityEditorEvent(
                      ToggleConflictedEntityDeletion(change));
                  _handleConflictChanged();
                },
              ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: _buildConfirmButton(context, isLightTheme),
        ),
      ],
    );
  }

  void _handleConflictChanged() {
    setState(() {});
    widget.onConflictsChanged?.call();
  }

  Widget _buildHeader(BuildContext context, bool isLightTheme) {
    return InkWell(
      onTap: widget.onBackPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLightTheme
                ? [
                    AppColors.brandPrimary.withValues(alpha: 0.08),
                    AppColors.brandSecondary.withValues(alpha: 0.1),
                  ]
                : [
                    AppColors.brandPrimaryLight.withValues(alpha: 0.15),
                    AppColors.brandSecondaryLight.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.2)
                : AppColors.brandPrimaryLight.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Back to Editor',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLightTheme
                          ? AppColors.brandPrimary
                          : AppColors.brandPrimaryLight,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, bool isLightTheme) {
    final statusColor =
        isLightTheme ? AppColors.warning : AppColors.warningLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Please review and confirm changes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, bool isLightTheme) {
    return FilledButton.icon(
      onPressed: () {
        context.addTripEntityEditorEvent(const ConfirmConflictPlan());
        widget.onConflictsResolved();
      },
      icon: const Icon(Icons.check, size: 18),
      label: const Text('Confirm'),
      style: FilledButton.styleFrom(
        backgroundColor:
            isLightTheme ? AppColors.success : AppColors.successLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
