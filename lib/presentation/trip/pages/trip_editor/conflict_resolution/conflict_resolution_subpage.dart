import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/common/entity_change_message_provider.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/common/unified_entity_change_editor.dart';

/// A subpage for resolving timeline conflicts within an entity editor.
/// This is not a bottom sheet but an embedded page that can be navigated to.
/// Uses the unified entity change components for consistency with AffectedEntitiesEditor.
class ConflictResolutionSubpage extends StatefulWidget {
  final TripDataUpdatePlan conflictPlan;
  final VoidCallback onBackPressed;
  final VoidCallback onConflictsResolved;

  const ConflictResolutionSubpage({
    super.key,
    required this.conflictPlan,
    required this.onBackPressed,
    required this.onConflictsResolved,
  });

  @override
  State<ConflictResolutionSubpage> createState() =>
      _ConflictResolutionSubpageState();
}

class _ConflictResolutionSubpageState extends State<ConflictResolutionSubpage> {
  late final EntityChangeMessageProvider _messageProvider;

  @override
  void initState() {
    super.initState();
    _messageProvider = widget.conflictPlan is TripMetadataUpdatePlan
        ? EntityChangeMessageProvider.forMetadataUpdate()
        : EntityChangeMessageProvider.forTimelineConflict();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, isLightTheme),
        const SizedBox(height: 16),
        _buildInfoBanner(context, isLightTheme),
        const SizedBox(height: 16),
        // Use the unified entity change editor for conflict resolution
        // Note: No Expanded here - parent provides scrolling
        widget.conflictPlan is TripMetadataUpdatePlan
            ? UnifiedEntityChangeEditor.forMetadataUpdate(
                updatePlan: widget.conflictPlan as TripMetadataUpdatePlan,
                onChanged: () => setState(() {}),
                onEntityDeletionChanged: (entity, isDeleted) {
                  (widget.conflictPlan as TripMetadataUpdatePlan)
                      .syncExpenseDeletionState(entity, isDeleted);
                  setState(() {});
                },
              )
            : UnifiedEntityChangeEditor.forConflictResolution(
                updatePlan: widget.conflictPlan,
                onChanged: () => setState(() {}),
              ),
        const SizedBox(height: 24),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isLightTheme) {
    return InkWell(
      onTap: widget.onBackPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLightTheme
                ? [
                    AppColors.brandPrimary.withValues(alpha: 0.1),
                    AppColors.brandSecondary.withValues(alpha: 0.15),
                  ]
                : [
                    AppColors.brandPrimaryLight.withValues(alpha: 0.2),
                    AppColors.brandSecondaryLight.withValues(alpha: 0.15),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? AppColors.brandPrimary.withValues(alpha: 0.15)
                    : AppColors.brandPrimaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: isLightTheme
                    ? AppColors.brandPrimary
                    : AppColors.brandPrimaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Back to Editing',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLightTheme
                              ? AppColors.brandPrimary
                              : AppColors.brandPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to return to the editor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, bool isLightTheme) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: isLightTheme ? AppColors.info : AppColors.infoLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _messageProvider.buildSummaryMessage(widget.conflictPlan),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _messageProvider.buildActionMessage(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onBackPressed,
              child: const Text('Back to Editor'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                widget.conflictPlan.acknowledge();
                // Don't dispatch events here - they will be buffered
                // and dispatched when the main FAB is clicked
                widget.onConflictsResolved();
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Changes'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isLightTheme ? AppColors.success : AppColors.successLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
