import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_events.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_state.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_section_builder.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/entity_change_message_provider.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/unified_entity_change_editor.dart';

/// A subpage for resolving timeline conflicts within an entity editor.
/// Supports live conflict detection - when resolving one conflict creates another.
class ConflictResolutionSubpage<T extends TripEntity> extends StatefulWidget {
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
  State<ConflictResolutionSubpage<T>> createState() =>
      _ConflictResolutionSubpageState<T>();
}

class _ConflictResolutionSubpageState<T extends TripEntity>
    extends State<ConflictResolutionSubpage<T>> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return BlocBuilder<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      buildWhen: (previous, current) {
        // Only rebuild the entire page when conflicts are added or removed
        // Individual sections handle their own updates via ConflictSectionBuilder
        return current is ConflictsAdded<T> || current is ConflictsRemoved<T>;
      },
      builder: (context, state) {
        final plan = state.currentPlan;
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
            // Conflict editor with optimized section builders
            _OptimizedConflictEditor<T>(
              plan: plan,
              isMetadataUpdate:
                  context.editableEntity<T>() is TripMetadataFacade,
              onTimeRangeUpdated: (change) {
                context.addTripEntityEditorEvent<T>(
                    UpdateConflictedEntityTimeRange(change));
                _handleConflictChanged();
              },
              onDeletionToggled: (change) {
                context.addTripEntityEditorEvent<T>(
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
      },
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
        context.addTripEntityEditorEvent<T>(const ConfirmConflictPlan());
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

/// An optimized conflict editor that uses [ConflictSectionBuilder] for each section.
///
/// Each section only rebuilds when:
/// - Conflicts of that type are added/removed (section count changes)
/// - The section uses [ConflictItemBuilder] internally for individual item updates
class _OptimizedConflictEditor<T extends TripEntity> extends StatelessWidget {
  final TripEntityUpdatePlan<T> plan;
  final bool isMetadataUpdate;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;

  const _OptimizedConflictEditor({
    required this.plan,
    required this.isMetadataUpdate,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final messageContext = isMetadataUpdate
        ? MessageContext.metadataUpdate
        : MessageContext.timelineConflict;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stays section - rebuilds only when stay conflicts are added/removed
        ConflictSectionBuilder<T>(
          sectionType: ConflictSectionType.stays,
          builder: (context, changes) {
            if (changes.isEmpty) return const SizedBox.shrink();
            return _StaySectionContent<T>(
              plan: plan,
              messageContext: messageContext,
              onTimeRangeUpdated: onTimeRangeUpdated,
              onDeletionToggled: onDeletionToggled,
            );
          },
        ),

        // Transits section - rebuilds only when transit conflicts are added/removed
        ConflictSectionBuilder<T>(
          sectionType: ConflictSectionType.transits,
          builder: (context, changes) {
            if (changes.isEmpty) return const SizedBox.shrink();
            return _TransitSectionContent<T>(
              plan: plan,
              messageContext: messageContext,
              onTimeRangeUpdated: onTimeRangeUpdated,
              onDeletionToggled: onDeletionToggled,
            );
          },
        ),

        // Sights section - rebuilds only when sight conflicts are added/removed
        ConflictSectionBuilder<T>(
          sectionType: ConflictSectionType.sights,
          builder: (context, changes) {
            if (changes.isEmpty) return const SizedBox.shrink();
            return _SightSectionContent<T>(
              plan: plan,
              messageContext: messageContext,
              onTimeRangeUpdated: onTimeRangeUpdated,
              onDeletionToggled: onDeletionToggled,
            );
          },
        ),

        // Expenses section (only for TripMetadataUpdatePlan)
        if (isMetadataUpdate && plan is TripMetadataUpdatePlan)
          _ExpensesSectionWrapper<T>(
            plan: plan as TripMetadataUpdatePlan,
            messageContext: messageContext,
          ),
      ],
    );
  }
}

/// Section content for stays with individual item builders
class _StaySectionContent<T extends TripEntity> extends StatelessWidget {
  final TripEntityUpdatePlan<T> plan;
  final MessageContext messageContext;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;

  const _StaySectionContent({
    required this.plan,
    required this.messageContext,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedEntityChangeSection<T>(
      sectionType: ConflictSectionType.stays,
      plan: plan,
      messageContext: messageContext,
      onTimeRangeUpdated: onTimeRangeUpdated,
      onDeletionToggled: onDeletionToggled,
    );
  }
}

/// Section content for transits with individual item builders
class _TransitSectionContent<T extends TripEntity> extends StatelessWidget {
  final TripEntityUpdatePlan<T> plan;
  final MessageContext messageContext;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;

  const _TransitSectionContent({
    required this.plan,
    required this.messageContext,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedEntityChangeSection<T>(
      sectionType: ConflictSectionType.transits,
      plan: plan,
      messageContext: messageContext,
      onTimeRangeUpdated: onTimeRangeUpdated,
      onDeletionToggled: onDeletionToggled,
    );
  }
}

/// Section content for sights with individual item builders
class _SightSectionContent<T extends TripEntity> extends StatelessWidget {
  final TripEntityUpdatePlan<T> plan;
  final MessageContext messageContext;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;

  const _SightSectionContent({
    required this.plan,
    required this.messageContext,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedEntityChangeSection<T>(
      sectionType: ConflictSectionType.sights,
      plan: plan,
      messageContext: messageContext,
      onTimeRangeUpdated: onTimeRangeUpdated,
      onDeletionToggled: onDeletionToggled,
    );
  }
}

/// Wrapper for expenses section
class _ExpensesSectionWrapper<T extends TripEntity> extends StatelessWidget {
  final TripMetadataUpdatePlan plan;
  final MessageContext messageContext;

  const _ExpensesSectionWrapper({
    required this.plan,
    required this.messageContext,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.expenseChanges.isEmpty) return const SizedBox.shrink();

    // For now, we use the existing UnifiedEntityChangeEditor for expenses
    // as they have a different structure
    return UnifiedEntityChangeEditor.forMetadataUpdate(
      updatePlan: plan,
      onTimeRangeUpdated: (_) {},
      onDeletionToggled: (_) {},
    );
  }
}
