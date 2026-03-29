import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

// =============================================================================
// TRIP ENTITY EDITOR STATES
// =============================================================================
//
// All conflict states extend TripEntityEditorState<T> directly (T = editable
// entity type).  There is NO second type parameter for the conflict entity
// type: emitting ConflictsAdded<TransitFacade> from a
// Bloc<…, TripEntityEditorState<LodgingFacade>> is a genuine type error in
// Dart's invariant generics system.
//
// Instead the plan-change states carry a [ConflictSectionChange] bitmask so
// each section widget and item widget can decide cheaply whether to rebuild,
// while still reading actual data from `bloc.currentPlan` /
// `context.tripEntityUpdatePlan<T>()`.
//
// State taxonomy:
//   [TripEntityInitialized]      – initial
//   [PlanUpdated]                – plan structure changed (sections added/removed)
//   [PlanItemsUpdated]           – items changed in-place (times / delete flag)
//   [PlanCleared]                – plan gone, all conflicts resolved
//   [ConflictPlanConfirmed]      – user confirmed plan
//   [ConflictedEntityTimeRangeError] – invalid time on a conflicted item
//   [EntitySubmitted]            – final submission
// =============================================================================

/// Which sections of the plan have structurally changed (items added/removed).
/// Used as a bitmask in [PlanUpdated] and [PlanItemsUpdated].
enum ConflictSection { stays, transits, sights, expenses }

/// Base state for [TripEntityEditorBloc<T>].
abstract class TripEntityEditorState<T extends TripEntity> {
  const TripEntityEditorState();
}

// ---------------------------------------------------------------------------
// Non-conflict states
// ---------------------------------------------------------------------------

/// Initial state right after construction.
class TripEntityInitialized<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final T editableEntity;
  const TripEntityInitialized(this.editableEntity);
}

/// Emitted when the user confirms the conflict plan.
class ConflictPlanConfirmed<T extends TripEntity>
    extends TripEntityEditorState<T> {
  const ConflictPlanConfirmed();
}

/// Emitted when final submission happens.
class EntitySubmitted<T extends TripEntity> extends TripEntityEditorState<T> {
  final T editableEntity;

  /// Plan at time of submission – carried here since submission consumes it once.
  final TripEntityUpdatePlan<T>? currentPlan;

  const EntitySubmitted(this.editableEntity, this.currentPlan);
}

/// Emitted when editing a conflicted entity results in an unresolvable conflict.
/// UI Response: show error snackbar; revert the conflicted entity's time values.
class ConflictedEntityTimeRangeError<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;
  final String errorMessage;
  final dynamic oldTimeValues;
  const ConflictedEntityTimeRangeError(
      this.change, this.errorMessage, this.oldTimeValues);
}

// ---------------------------------------------------------------------------
// Plan-change states
// ---------------------------------------------------------------------------

/// Emitted when one or more conflict sections gain or lose items (structural
/// change: the set of conflicting entity IDs changed).
///
/// [affectedSections] tells each section widget whether it needs to rebuild.
/// The widget reads the actual list from `context.tripEntityUpdatePlan<T>()`.
///
/// UI Response:
/// - Section widgets whose [ConflictSection] is in [affectedSections] rebuild.
/// - The conflict banner / page-visibility logic also reacts to this state.
class PlanUpdated<T extends TripEntity> extends TripEntityEditorState<T> {
  /// Sections whose item-set changed (additions or removals).
  final Set<ConflictSection> affectedSections;

  const PlanUpdated(this.affectedSections);
}

/// Emitted when existing conflict items are modified in-place (time changed,
/// deletion toggled, clamping applied) without any structural change.
///
/// [affectedSections] tells each item widget which section was touched.
/// Each item widget reads the updated change from the plan by its own ID.
///
/// UI Response:
/// - Item widgets whose section is in [affectedSections] check their own ID
///   and rebuild only if their item was among the changed ones.
class PlanItemsUpdated<T extends TripEntity> extends TripEntityEditorState<T> {
  /// Sections that contain at least one modified item.
  final Set<ConflictSection> affectedSections;

  const PlanItemsUpdated(this.affectedSections);
}

/// Emitted when the plan is completely cleared (no conflicts remain).
///
/// UI Response: hide conflict resolution page, collapse all sections.
class PlanCleared<T extends TripEntity> extends TripEntityEditorState<T> {
  const PlanCleared();
}
