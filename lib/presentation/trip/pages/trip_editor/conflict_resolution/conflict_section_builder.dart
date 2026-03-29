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

/// Which section a [ConflictSectionType] maps to in [ConflictSection].
enum ConflictSectionType { stays, transits, sights }

extension _SectionTypeExt on ConflictSectionType {
  ConflictSection get asSection => switch (this) {
        ConflictSectionType.stays => ConflictSection.stays,
        ConflictSectionType.transits => ConflictSection.transits,
        ConflictSectionType.sights => ConflictSection.sights,
      };
}

// =============================================================================
// CONFLICT SECTION BUILDER
// =============================================================================

/// Rebuilds only when the plan's structural change ([PlanUpdated] or [PlanCleared])
/// includes this section's [ConflictSection].
///
/// On rebuild, reads the current list directly from
/// `context.tripEntityUpdatePlan<T>()` — no data is carried in the state.
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
      buildWhen: (_, current) {
        if (current is PlanCleared<T>) return true;
        if (current is PlanUpdated<T>) {
          return current.affectedSections.contains(sectionType.asSection);
        }
        return false;
      },
      builder: (context, _) {
        final changes = _changesFor(context);
        if (changes.isEmpty) return const SizedBox.shrink();
        return builder(context, changes);
      },
    );
  }

  List<EntityChangeBase> _changesFor(BuildContext context) {
    final plan = context.tripEntityUpdatePlan<T>();
    if (plan == null) return const [];
    return switch (sectionType) {
      ConflictSectionType.stays => plan.stayChanges.cast<EntityChangeBase>(),
      ConflictSectionType.transits =>
        plan.transitChanges.cast<EntityChangeBase>(),
      ConflictSectionType.sights => plan.sightChanges.cast<EntityChangeBase>(),
    };
  }
}

// =============================================================================
// CONFLICT ITEM BUILDER
// =============================================================================

/// Rebuilds a single conflict item only when [PlanItemsUpdated] includes this
/// item's section AND the plan still contains an entry with this [entityId].
///
/// Reads the latest change from `context.tripEntityUpdatePlan<T>()` directly.
class ConflictItemBuilder<T extends TripEntity> extends StatelessWidget {
  final String entityId;
  final ConflictSectionType sectionType;
  final Widget Function(BuildContext context, EntityChangeBase change) builder;

  const ConflictItemBuilder({
    super.key,
    required this.entityId,
    required this.sectionType,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      buildWhen: (_, current) {
        if (current is PlanItemsUpdated<T>) {
          return current.affectedSections.contains(sectionType.asSection);
        }
        return false;
      },
      builder: (context, _) {
        final change = _findChange(context);
        if (change == null) return const SizedBox.shrink();
        return builder(context, change);
      },
    );
  }

  EntityChangeBase? _findChange(BuildContext context) {
    final plan = context.tripEntityUpdatePlan<T>();
    if (plan == null) return null;
    final list = switch (sectionType) {
      ConflictSectionType.stays => plan.stayChanges as List<EntityChangeBase>,
      ConflictSectionType.transits =>
        plan.transitChanges as List<EntityChangeBase>,
      ConflictSectionType.sights => plan.sightChanges as List<EntityChangeBase>,
    };
    return list.where((c) => c.original.id == entityId).firstOrNull;
  }
}

// =============================================================================
// CONFLICT ITEM LISTENER
// =============================================================================

/// Side-effect listener that fires when [PlanItemsUpdated] touches this item's
/// section (for snackbars, animations, etc.).
class ConflictItemListener<T extends TripEntity> extends StatelessWidget {
  final String entityId;
  final ConflictSectionType sectionType;
  final void Function(BuildContext context, EntityChangeBase change) onUpdated;
  final Widget child;

  const ConflictItemListener({
    super.key,
    required this.entityId,
    required this.sectionType,
    required this.onUpdated,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
      listenWhen: (_, current) =>
          current is PlanItemsUpdated<T> &&
          current.affectedSections.contains(sectionType.asSection),
      listener: (context, _) {
        final plan = context.tripEntityUpdatePlan<T>();
        if (plan == null) return;
        final list = switch (sectionType) {
          ConflictSectionType.stays =>
            plan.stayChanges as List<EntityChangeBase>,
          ConflictSectionType.transits =>
            plan.transitChanges as List<EntityChangeBase>,
          ConflictSectionType.sights =>
            plan.sightChanges as List<EntityChangeBase>,
        };
        final change = list.where((c) => c.original.id == entityId).firstOrNull;
        if (change != null) onUpdated(context, change);
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
