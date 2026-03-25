import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/states.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Enum to identify conflict section types
enum ConflictSectionType { stays, transits, sights }

// =============================================================================
// CONFLICT SECTION BUILDER
// =============================================================================

/// A [BlocSelector] wrapper that rebuilds only when conflicts of a specific type
/// are added or removed from the plan.
///
/// This builder listens for state changes and only rebuilds when:
/// - The conflict count for this [sectionType] changes
/// - The plan transitions from null to non-null or vice versa
///
/// Individual conflict items are NOT rebuilt here - they use [ConflictItemBuilder]
/// to respond only to [ConflictItemUpdated] states that match their entity ID.
///
/// ## Performance Characteristics
/// - Section rebuilds: O(1) comparison of conflict counts
/// - No item-level rebuilds on section changes
/// - Respects SOLID: Single responsibility (section visibility only)
class ConflictSectionBuilder<T extends TripEntity> extends StatelessWidget {
  final ConflictSectionType sectionType;
  final Widget Function(BuildContext context, List<EntityChangeBase> changes)
      builder;

  const ConflictSectionBuilder({
    super.key,
    required this.sectionType,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // Use BlocSelector for optimal performance - only rebuilds when the
    // conflict count for this section type changes
    return BlocSelector<TripEntityEditorBloc<T>, TripEntityEditorState<T>,
        _SectionData>(
      selector: _selectSectionData,
      builder: (context, sectionData) {
        if (!sectionData.hasChanges) {
          return const SizedBox.shrink();
        }
        return builder(context, sectionData.changes);
      },
    );
  }

  /// Extracts only the data relevant to this section for comparison.
  /// BlocSelector uses equality (==) to determine if rebuild is needed.
  _SectionData _selectSectionData(TripEntityEditorState<T> state) {
    final plan = state.currentPlan;
    if (plan == null) {
      return const _SectionData.empty();
    }

    final changes = _getChangesForSection(plan);
    return _SectionData(
      count: changes.length,
      changes: changes,
    );
  }

  List<EntityChangeBase> _getChangesForSection(dynamic plan) {
    switch (sectionType) {
      case ConflictSectionType.stays:
        return plan.stayChanges.cast<EntityChangeBase>();
      case ConflictSectionType.transits:
        return plan.transitChanges.cast<EntityChangeBase>();
      case ConflictSectionType.sights:
        return plan.sightChanges.cast<EntityChangeBase>();
    }
  }
}

/// Data class for section state comparison.
/// Only rebuilds when count changes (additions/removals).
class _SectionData {
  final int count;
  final List<EntityChangeBase> changes;

  const _SectionData({
    required this.count,
    required this.changes,
  });

  const _SectionData.empty()
      : count = 0,
        changes = const [];

  bool get hasChanges => count > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SectionData &&
          runtimeType == other.runtimeType &&
          count == other.count;

  @override
  int get hashCode => count.hashCode;
}

// =============================================================================
// CONFLICT ITEM BUILDER
// =============================================================================

/// A [BlocBuilder] wrapper that rebuilds only when a specific conflict item is updated.
///
/// This builder listens for [ConflictItemUpdated] states and only rebuilds when:
/// - The updated change matches this item's entity type AND ID
///
/// ## Matching Logic
/// Two changes are considered the same if:
/// 1. They have the same entity type (Stay/Transit/Sight)
/// 2. They have the same original entity ID
///
/// This ensures that updating a Transit doesn't cause Stay items to rebuild.
///
/// ## Performance Characteristics
/// - Rebuild check: O(1) type + ID comparison
/// - Only rebuilds the exact item that was updated
/// - Respects SOLID: Single responsibility (item-level updates only)
class ConflictItemBuilder<T extends TripEntity> extends StatelessWidget {
  final EntityChangeBase change;
  final Widget Function(BuildContext context, EntityChangeBase change) builder;

  const ConflictItemBuilder({
    super.key,
    required this.change,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      buildWhen: (previous, current) {
        // Only rebuild when this specific item is updated
        if (current is ConflictItemUpdated<T>) {
          return _isSameChange(current.updatedChange, change);
        }
        return false;
      },
      builder: (context, state) {
        // Get the latest version of this change from the plan if available
        final latestChange = _getLatestChange(state) ?? change;
        return builder(context, latestChange);
      },
    );
  }

  /// Checks if two changes refer to the same entity by type and ID.
  bool _isSameChange(EntityChangeBase a, EntityChangeBase b) {
    // First check type compatibility
    if (!_isSameType(a, b)) return false;

    // Then check ID match
    final aId = a.original.id;
    final bId = b.original.id;
    return aId != null && bId != null && aId == bId;
  }

  /// Checks if two changes have the same entity type.
  bool _isSameType(EntityChangeBase a, EntityChangeBase b) {
    // Check original entity types to ensure matching
    final aOriginal = a.original;
    final bOriginal = b.original;

    if (aOriginal is LodgingFacade && bOriginal is LodgingFacade) return true;
    if (aOriginal is TransitFacade && bOriginal is TransitFacade) return true;
    if (aOriginal is SightFacade && bOriginal is SightFacade) return true;

    return false;
  }

  /// Gets the latest version of this change from the current plan.
  /// This ensures the widget displays the most up-to-date data.
  EntityChangeBase? _getLatestChange(TripEntityEditorState<T> state) {
    final plan = state.currentPlan;
    if (plan == null) return null;

    final id = change.original.id;
    if (id == null) return null;

    // Search in the appropriate list based on entity type
    if (change.original is LodgingFacade) {
      return plan.stayChanges.cast<EntityChangeBase>().firstWhere(
            (c) => c.original.id == id,
            orElse: () => change,
          );
    } else if (change.original is TransitFacade) {
      return plan.transitChanges.cast<EntityChangeBase>().firstWhere(
            (c) => c.original.id == id,
            orElse: () => change,
          );
    } else if (change.original is SightFacade) {
      return plan.sightChanges.cast<EntityChangeBase>().firstWhere(
            (c) => c.original.id == id,
            orElse: () => change,
          );
    }

    return null;
  }
}

// =============================================================================
// CONFLICT ITEM LISTENER
// =============================================================================

/// A [BlocListener] that responds to conflict item updates for a specific change.
///
/// Use this to show snackbars, trigger animations, or perform other side effects
/// when a specific conflict item is updated.
class ConflictItemListener<T extends TripEntity> extends StatelessWidget {
  final EntityChangeBase change;
  final void Function(BuildContext context, EntityChangeBase change) onUpdated;
  final Widget child;

  const ConflictItemListener({
    super.key,
    required this.change,
    required this.onUpdated,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      listenWhen: (previous, current) {
        if (current is ConflictItemUpdated<T>) {
          return _isSameChange(current.updatedChange, change);
        }
        return false;
      },
      listener: (context, state) {
        if (state is ConflictItemUpdated<T>) {
          onUpdated(context, state.updatedChange);
        }
      },
      child: child,
    );
  }

  bool _isSameChange(EntityChangeBase a, EntityChangeBase b) {
    // Check type compatibility
    final aOriginal = a.original;
    final bOriginal = b.original;

    if (aOriginal is LodgingFacade && bOriginal is! LodgingFacade) return false;
    if (aOriginal is TransitFacade && bOriginal is! TransitFacade) return false;
    if (aOriginal is SightFacade && bOriginal is! SightFacade) return false;

    // Check ID match
    return a.original.id == b.original.id;
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension methods for easily checking conflict types
extension ConflictChangeTypeExtension on EntityChangeBase {
  bool get isStayChange => modified is LodgingFacade;

  bool get isTransitChange => modified is TransitFacade;

  bool get isSightChange => modified is SightFacade;
}
