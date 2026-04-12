import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip_entity_editor/bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/states.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

// =============================================================================
// CONFLICT SECTION BUILDER
// =============================================================================

/// Rebuilds only when the plan's structural change ([PlanUpdated] or [PlanCleared])
/// includes this section's entity type.
///
/// On rebuild, reads the current list directly from
/// `context.tripEntityUpdatePlan<T>()` — no data is carried in the state.
class ConflictSectionBuilder<T extends TripEntity> extends StatelessWidget {
  /// The entity type this section represents (e.g. LodgingFacade, TransitFacade, SightFacade).
  final Type entityType;
  final Widget Function(BuildContext context, List<EntityChangeBase> changes)
      builder;

  const ConflictSectionBuilder({
    required this.entityType,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      buildWhen: (_, current) {
        if (current is PlanCleared<T>) {
          return true;
        }
        if (current is PlanUpdated<T>) {
          return current.affectedSections.contains(entityType);
        }
        return false;
      },
      builder: (context, _) {
        final changes = _changesFor(context);
        if (changes.isEmpty) {
          return const SizedBox.shrink();
        }
        return builder(context, changes);
      },
    );
  }

  List<EntityChangeBase> _changesFor(BuildContext context) {
    final plan = context.tripEntityUpdatePlan<T>();
    if (plan == null) {
      return const [];
    }
    if (entityType == LodgingFacade) {
      return plan.stayChanges.cast<EntityChangeBase>();
    } else if (entityType == TransitFacade) {
      return plan.transitChanges.cast<EntityChangeBase>();
    } else if (entityType == SightFacade) {
      return plan.sightChanges.cast<EntityChangeBase>();
    }
    return const [];
  }
}

// =============================================================================
// CONFLICT ITEM BUILDER
// =============================================================================

/// Rebuilds a single conflict item only when [PlanItemsUpdated] includes this
/// item's entity type AND the plan still contains an entry with this [entityId].
///
/// Reads the latest change from `context.tripEntityUpdatePlan<T>()` directly.
class ConflictItemBuilder<T extends TripEntity> extends StatelessWidget {
  final String entityId;

  /// The entity type this item represents (e.g. LodgingFacade, TransitFacade, SightFacade).
  final Type entityType;
  final Widget Function(BuildContext context, EntityChangeBase change) builder;

  const ConflictItemBuilder({
    required this.entityId,
    required this.entityType,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      buildWhen: (_, current) {
        if (current is PlanItemsUpdated<T>) {
          return current.affectedSections.contains(entityType);
        }
        return false;
      },
      builder: (context, _) {
        final change = _findChange(context);
        if (change == null) {
          return const SizedBox.shrink();
        }
        return builder(context, change);
      },
    );
  }

  EntityChangeBase? _findChange(BuildContext context) {
    final plan = context.tripEntityUpdatePlan<T>();
    if (plan == null) {
      return null;
    }
    final List<EntityChangeBase> list;
    if (entityType == LodgingFacade) {
      list = plan.stayChanges.cast<EntityChangeBase>();
    } else if (entityType == TransitFacade) {
      list = plan.transitChanges.cast<EntityChangeBase>();
    } else if (entityType == SightFacade) {
      list = plan.sightChanges.cast<EntityChangeBase>();
    } else {
      return null;
    }
    return list.where((c) => c.original.id == entityId).firstOrNull;
  }
}

// =============================================================================
// CONFLICT ITEM LISTENER
// =============================================================================

/// Side-effect listener that fires when [PlanItemsUpdated] touches this item's
/// entity type (for snackbars, animations, etc.).
class ConflictItemListener<T extends TripEntity> extends StatelessWidget {
  final String entityId;

  /// The entity type this listener tracks (e.g. LodgingFacade, TransitFacade, SightFacade).
  final Type entityType;
  final void Function(BuildContext context, EntityChangeBase change) onUpdated;
  final Widget child;

  const ConflictItemListener({
    required this.entityId,
    required this.entityType,
    required this.onUpdated,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      listenWhen: (_, current) =>
          current is PlanItemsUpdated<T> &&
          current.affectedSections.contains(entityType),
      listener: (context, _) {
        final plan = context.tripEntityUpdatePlan<T>();
        if (plan == null) {
          return;
        }
        final List<EntityChangeBase> list;
        if (entityType == LodgingFacade) {
          list = plan.stayChanges.cast<EntityChangeBase>();
        } else if (entityType == TransitFacade) {
          list = plan.transitChanges.cast<EntityChangeBase>();
        } else if (entityType == SightFacade) {
          list = plan.sightChanges.cast<EntityChangeBase>();
        } else {
          return;
        }
        final change = list.where((c) => c.original.id == entityId).firstOrNull;
        if (change != null) {
          onUpdated(context, change);
        }
      },
      child: child,
    );
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

extension ConflictChangeTypeExtension on EntityChangeBase {
  bool get isStayChange => original is LodgingFacade;
  bool get isTransitChange => original is TransitFacade;
  bool get isSightChange => original is SightFacade;
}
