import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip_entity_editor/bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/events.dart';
import 'package:wandrr/blocs/trip_entity_editor/states.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_section_builder.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/entity_change_message_provider.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/unified_entity_change_editor.dart';

/// A subpage for resolving timeline conflicts within an entity editor.
///
/// Uses optimized, localized rebuilds:
/// - Static layout (header, status bar, confirm button) doesn't rebuild on state changes
/// - Each section (stays, transits, sights) rebuilds only when conflicts of that type change
/// - Each conflict item rebuilds only when that specific item is updated
class ConflictResolutionSubpage<T extends TripEntity> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    // Static layout - doesn't rebuild on state changes
    // Each child uses its own targeted BlocSelector/Builder for localized rebuilds
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ConflictResolutionHeader<T>(
          isLightTheme: isLightTheme,
          onBackPressed: onBackPressed,
        ),
        const SizedBox(height: 12),
        _ConflictResolutionStatusBar(isLightTheme: isLightTheme),
        const SizedBox(height: 12),
        // Dynamic conflict sections - each rebuilds independently
        _DynamicConflictSections<T>(
          onConflictsChanged: onConflictsChanged,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: _ConflictConfirmButton<T>(
            isLightTheme: isLightTheme,
            onConflictsResolved: onConflictsResolved,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STATIC COMPONENTS - No BLoC listening, pure UI
// =============================================================================

/// Header with back button - static, no state listening needed
class _ConflictResolutionHeader<T extends TripEntity> extends StatelessWidget {
  final bool isLightTheme;
  final VoidCallback onBackPressed;

  const _ConflictResolutionHeader({
    required this.isLightTheme,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBackPressed,
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
}

/// Status bar - static, no state listening needed
class _ConflictResolutionStatusBar extends StatelessWidget {
  final bool isLightTheme;

  const _ConflictResolutionStatusBar({required this.isLightTheme});

  @override
  Widget build(BuildContext context) {
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
}

/// Confirm button - static, triggers BLoC event on press
class _ConflictConfirmButton<T extends TripEntity> extends StatelessWidget {
  final bool isLightTheme;
  final VoidCallback onConflictsResolved;

  const _ConflictConfirmButton({
    required this.isLightTheme,
    required this.onConflictsResolved,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        context.addTripEntityEditorEvent<T>(const ConfirmConflictPlan());
        onConflictsResolved();
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

// =============================================================================
// DYNAMIC CONFLICT SECTIONS - Localized BLoC listening
// =============================================================================

/// Container for all conflict sections with optimized state listening.
///
/// Uses [BlocSelector] to only rebuild when conflict counts change.
/// Each section type is generated dynamically based on its conflict count.
class _DynamicConflictSections<T extends TripEntity> extends StatelessWidget {
  final VoidCallback? onConflictsChanged;

  const _DynamicConflictSections({this.onConflictsChanged});

  @override
  Widget build(BuildContext context) {
    final isMetadataUpdate = context.editableEntity<T>() is TripMetadataFacade;
    final messageContext = isMetadataUpdate
        ? MessageContext.metadataUpdate
        : MessageContext.timelineConflict;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stays section - rebuilds only when stay conflict count changes
        _DynamicConflictSection<T>(
          sectionType: ConflictSectionType.stays,
          messageContext: messageContext,
          onConflictsChanged: onConflictsChanged,
        ),

        // Transits section - rebuilds only when transit conflict count changes
        _DynamicConflictSection<T>(
          sectionType: ConflictSectionType.transits,
          messageContext: messageContext,
          onConflictsChanged: onConflictsChanged,
        ),

        // Sights section - rebuilds only when sight conflict count changes
        _DynamicConflictSection<T>(
          sectionType: ConflictSectionType.sights,
          messageContext: messageContext,
          onConflictsChanged: onConflictsChanged,
        ),

        // Expenses section (only for TripMetadataUpdatePlan)
        if (isMetadataUpdate) _ExpensesSectionSelector<T>(),
      ],
    );
  }
}

/// A single conflict section that rebuilds only when conflicts of its type change.
///
/// Uses [ConflictSectionBuilder] which internally uses [BlocBuilder] with targeted
/// buildWhen logic for section-level changes. Items within use [ConflictItemBuilder]
/// for individual item updates.
class _DynamicConflictSection<T extends TripEntity> extends StatelessWidget {
  final ConflictSectionType sectionType;
  final MessageContext messageContext;
  final VoidCallback? onConflictsChanged;

  const _DynamicConflictSection({
    required this.sectionType,
    required this.messageContext,
    this.onConflictsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConflictSectionBuilder<T>(
      sectionType: sectionType,
      builder: (context, changes) {
        if (changes.isEmpty) return const SizedBox.shrink();

        // Get the current plan - safe since we're inside ConflictSectionBuilder
        // which only builds when plan exists
        final plan = context.read<TripEntityEditorBloc<T>>().state.currentPlan;
        if (plan == null) return const SizedBox.shrink();

        return OptimizedEntityChangeSection<T>(
          sectionType: sectionType,
          plan: plan,
          messageContext: messageContext,
          onTimeRangeUpdated: (change) {
            context.addTripEntityEditorEvent<T>(
                UpdateConflictedEntityTimeRange(change));
            onConflictsChanged?.call();
          },
          onDeletionToggled: (change) {
            context.addTripEntityEditorEvent<T>(
                ToggleConflictedEntityDeletion(change));
            onConflictsChanged?.call();
          },
        );
      },
    );
  }
}

/// Expenses section selector - only rebuilds when expense changes exist
class _ExpensesSectionSelector<T extends TripEntity> extends StatelessWidget {
  const _ExpensesSectionSelector();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TripEntityEditorBloc<T>, TripEntityEditorState<T>,
        TripMetadataUpdatePlan?>(
      selector: (state) {
        final plan = state.currentPlan;
        if (plan == null) return null;
        if (plan is TripMetadataUpdatePlan && plan.expenseChanges.isNotEmpty) {
          // Explicit cast to satisfy the selector return type
          return plan as TripMetadataUpdatePlan;
        }
        return null;
      },
      builder: (context, metadataPlan) {
        if (metadataPlan == null) return const SizedBox.shrink();

        return UnifiedEntityChangeEditor.forMetadataUpdate(
          updatePlan: metadataPlan,
          onTimeRangeUpdated: (_) {},
          onDeletionToggled: (_) {},
        );
      },
    );
  }
}
