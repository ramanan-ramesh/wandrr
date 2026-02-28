import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_state.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Enum to identify conflict section types
enum ConflictSectionType { stays, transits, sights }

/// A BlocBuilder wrapper that rebuilds only when conflicts of a specific type are added/removed.
///
/// This builder listens for [ConflictsAdded], [ConflictsRemoved], and [ConflictsUpdated] states
/// and only rebuilds when the number of conflicts of the specified [sectionType] changes.
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
    return BlocBuilder<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      buildWhen: (previous, current) {
        // Rebuild when conflicts are added/removed (section visibility may change)
        if (current is ConflictsAdded<T> || current is ConflictsRemoved<T>) {
          return true;
        }

        // For ConflictsUpdated, check if the conflict count changed for this section
        if (current is ConflictsUpdated<T>) {
          final previousCount = _getConflictCount(previous);
          final currentCount = _getConflictCount(current);
          return previousCount != currentCount;
        }

        // Don't rebuild on ConflictItemUpdated - individual items handle their own updates
        return false;
      },
      builder: (context, state) {
        final plan = state.currentPlan;
        if (plan == null) {
          return const SizedBox.shrink();
        }

        final changes = _getChangesForSection(plan);
        return builder(context, changes);
      },
    );
  }

  int _getConflictCount(TripEntityEditorState<T> state) {
    final plan = state.currentPlan;
    if (plan == null) return 0;

    switch (sectionType) {
      case ConflictSectionType.stays:
        return plan.stayChanges.length;
      case ConflictSectionType.transits:
        return plan.transitChanges.length;
      case ConflictSectionType.sights:
        return plan.sightChanges.length;
    }
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

/// A BlocBuilder wrapper that rebuilds only when a specific conflict item is updated.
///
/// This builder listens for [ConflictItemUpdated] states and only rebuilds when
/// the [change] matches the updated change in the state.
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
        // Rebuild when this specific item is updated
        if (current is ConflictItemUpdated<T>) {
          return _isSameChange(current.updatedChange, change);
        }
        return false;
      },
      builder: (context, state) {
        return builder(context, change);
      },
    );
  }

  bool _isSameChange(EntityChangeBase a, EntityChangeBase b) {
    // Compare by original entity ID since that's the stable identifier
    return a.original.id == b.original.id;
  }
}

/// A listener that responds to conflict item updates for a specific change.
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
          return current.updatedChange.original.id == change.original.id;
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
}

/// Extension methods for easily checking conflict types
extension ConflictChangeTypeExtension on EntityChangeBase {
  bool get isStayChange => modified is LodgingFacade;

  bool get isTransitChange => modified is TransitFacade;

  bool get isSightChange => modified is SightFacade;
}
