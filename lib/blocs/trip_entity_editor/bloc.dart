import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_detectors.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_result.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_scanner.dart';
import 'package:wandrr/data/trip/services/conflict_detection/entity_change.dart';
import 'package:wandrr/data/trip/services/conflict_detection/time_range.dart';
import 'package:wandrr/data/trip/services/conflict_detection/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/services/transit_journey_service.dart';

import 'events.dart';
import 'states.dart';

/// BLoC for editing trip entities with conflict detection and resolution.
///
/// Conflict detection runs synchronously on the main isolate — it operates on
/// already-loaded in-memory collections (microseconds of work).
///
/// The plan itself is never stored in state; always read via
/// `bloc.currentPlan` or `context.tripEntityUpdatePlan<T>()`.
class TripEntityEditorBloc<TEntity extends TripEntity<Enum>>
    extends Bloc<TripEntityEditorEvent, TripEntityEditorState<TEntity>> {
  final TripDataFacade _tripData;
  final TEntity? originalEntity;
  final TEntity editableEntity;

  bool get _isNewEntity => originalEntity == null;

  TripEntityUpdatePlan<TEntity>? get currentPlan => _currentPlan;
  TripEntityUpdatePlan<TEntity>? _currentPlan;

  /// For journey editing: the latest full set of legs from the most recent
  /// [UpdateJourney] event.
  List<TransitFacade> _latestJourneyLegs = [];

  /// Journey service instantiated once from tripData. Only used when TEntity
  /// is TransitFacade, but kept lazy to avoid unnecessary allocation.
  TransitJourneyServiceFacade get _journeyService =>
      TransitJourneyServiceFacade(_tripData.transitCollection);

  TripEntityEditorBloc._({
    required TripDataFacade tripData,
    required TEntity? original,
    required TEntity editable,
  })  : _tripData = tripData,
        originalEntity = original,
        editableEntity = editable,
        super(TripEntityInitialized<TEntity>(editable)) {
    on<UpdateEntity<TEntity>>(_onUpdateEntity);
    on<UpdateJourney>(_onUpdateJourney);
    on<UpdateConflictedEntityTimeRange>(_onUpdateConflictedEntityTimeRange);
    on<ToggleConflictedEntityDeletion>(_onToggleConflictedEntityDeletion);
    on<ConfirmConflictPlan>(_onConfirmConflictPlan);
    on<SubmitEntity>(_onSubmitEntity);
  }

  TripEntityEditorBloc.forCreation({
    required TripDataFacade tripData,
    required TEntity entity,
  }) : this._(tripData: tripData, original: null, editable: entity);

  TripEntityEditorBloc.forEditing({
    required TripDataFacade tripData,
    required TEntity entity,
  }) : this._(
            tripData: tripData,
            original: entity,
            editable: entity.clone() as TEntity);

  // ===========================================================================
  // EVENT HANDLERS
  // ===========================================================================

  /// Unified handler for Stay, TripMetadata, and ItineraryPlanData updates.
  /// Reads time ranges directly from editableEntity (already mutated by the editor).
  void _onUpdateEntity(
    UpdateEntity<TEntity> event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    final validationErrors = editableEntity.getValidationErrors();
    emit(EntityValidationUpdated<TEntity>(validationErrors: validationErrors));
    if (validationErrors.isNotEmpty) {
      _currentPlan = null;
      return;
    }

    TripEntityUpdatePlan<TEntity>? newPlan;

    if (editableEntity is LodgingFacade) {
      final stay = editableEntity as LodgingFacade;
      if (stay.checkinDateTime != null && stay.checkoutDateTime != null) {
        newPlan = _detectStayConflicts(stay) as TripEntityUpdatePlan<TEntity>?;
      }
    } else if (editableEntity is TripMetadataFacade) {
      final meta = editableEntity as TripMetadataFacade;
      if (meta.startDate != null && meta.endDate != null) {
        newPlan =
            _detectMetadataConflicts(meta) as TripEntityUpdatePlan<TEntity>?;
      }
    } else if (editableEntity is ItineraryPlanData) {
      final itinerary = editableEntity as ItineraryPlanData;
      final sights = List<SightFacade>.from(itinerary.sights);

      newPlan =
          _detectItineraryConflicts(sights) as TripEntityUpdatePlan<TEntity>?;
    }

    _handlePlanUpdate(newPlan, emit);
  }

  /// Unified handler for transit journey updates. Uses the bloc-level journey
  /// service to validate all legs (per-leg + cross-leg sequence) before running
  /// conflict detection. Conflict detection is skipped when there are errors.
  void _onUpdateJourney(
    UpdateJourney event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (editableEntity is! TransitFacade) {
      return;
    }

    // Collect per-leg validation errors from every leg (deduplicated).
    final perLegErrors = <Enum>{};
    for (final leg in event.legs) {
      perLegErrors.addAll(leg.getValidationErrors());
    }

    // Cross-leg journey sequence errors (e.g. sequenceViolation).
    // Filter out the umbrella legHasErrors entry — specific per-leg errors replace it.
    final crossLegErrors = _journeyService
        .validateJourney(event.legs)
        .where((e) => e != JourneyValidationError.legHasErrors);

    final allErrors = [...perLegErrors, ...crossLegErrors];
    emit(EntityValidationUpdated<TEntity>(validationErrors: allErrors));
    if (allErrors.isNotEmpty) {
      _currentPlan = null;
      return;
    }

    // Keep legs up to date so reconciliation can check against all of them.
    _latestJourneyLegs = List.from(event.legs);

    final newPlan =
        _detectJourneyConflicts(event.legs, removedLegIds: event.removedLegIds)
            as TripEntityUpdatePlan<TEntity>?;
    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateConflictedEntityTimeRange(
    UpdateConflictedEntityTimeRange event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (_currentPlan == null) {
      return;
    }

    final result = _buildScanner().resolveConflictedEntityTimeChange(
      modifiedChange: event.change,
      editableEntityRange: _getEditableEntityTimeRange(),
      editableEntity: editableEntity,
      existingStayChanges: _currentPlan!.stayChanges,
      existingTransitChanges: _currentPlan!.transitChanges,
      existingSightChanges: _currentPlan!.sightChanges,
      editingJourneyLegs: _latestJourneyLegs,
    );

    if (!result.isValid) {
      emit(ConflictedEntityTimeRangeError<TEntity>(
          event.change, result.conflictingEntity!, event.change.original));
      return;
    }

    // Merge any newly discovered inter-conflicts.
    _mergeNewConflicts(result.newConflicts);

    emit(const ConflictPlanUpdated());
  }

  void _onToggleConflictedEntityDeletion(
    ToggleConflictedEntityDeletion event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (_currentPlan == null) {
      return;
    }

    final newIsDeleted = !event.change.isMarkedForDeletion;
    if (newIsDeleted) {
      event.change.markForDeletion();
    } else {
      event.change.restore();
    }
    for (final change in _currentPlan!.expenseChanges) {
      if (change.original.id == event.change.original.id) {
        if (newIsDeleted) {
          change.markForDeletion();
        } else {
          change.restore();
        }
        break;
      }
    }

    emit(const ConflictPlanUpdated());
  }

  void _onConfirmConflictPlan(
    ConfirmConflictPlan event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    _currentPlan?.confirm();
    emit(const ConflictPlanConfirmed());
  }

  void _onSubmitEntity(
    SubmitEntity event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    emit(EntitySubmitted<TEntity>(editableEntity, _currentPlan));
  }

  // ===========================================================================
  // SCANNER FACTORY
  // ===========================================================================

  UnifiedConflictScanner _buildScanner() => UnifiedConflictScanner(
        tripData: TripConflictDataSnapshot.fromTripData(_tripData),
      );

  // ===========================================================================
  // PLAN MANAGEMENT
  // ===========================================================================

  /// Updates the current plan reference and emits [ConflictPlanUpdated].
  ///
  /// Before replacing [_currentPlan], the fresh [newPlan] is reconciled against
  /// any existing plan so that conflicts already resolved by the user are
  /// preserved rather than reset to auto-clamped values.
  void _handlePlanUpdate(
    TripEntityUpdatePlan<TEntity>? newPlan,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    final effectivePlan =
        (newPlan != null && newPlan.hasConflicts) ? newPlan : null;

    if (effectivePlan != null && _currentPlan != null) {
      _reconcileWithExistingPlan(effectivePlan);
    }

    _currentPlan = (effectivePlan != null && effectivePlan.hasConflicts)
        ? effectivePlan
        : null;

    if (_currentPlan != null) {
      emit(const ConflictPlanUpdated());
    }
  }

  /// Merges [newConflicts] into the current plan.
  void _mergeNewConflicts(Iterable<EntityChangeBase> newConflicts) {
    if (newConflicts.isEmpty || _currentPlan == null) {
      return;
    }

    for (final change in newConflicts) {
      if (change is StayChange) {
        _currentPlan!.stayChanges.add(change);
      } else if (change is TransitChange) {
        _currentPlan!.transitChanges.add(change);
      } else if (change is SightChange) {
        _currentPlan!.sightChanges.add(change);
      }
    }
  }

  // ===========================================================================
  // CONFLICT RECONCILIATION
  // ===========================================================================

  /// Reconciles [newPlan] against [_currentPlan] to preserve user-resolved
  /// states for entities that still conflict with the editing entity.
  ///
  /// For each conflict entity in [newPlan] whose ID is already present in
  /// [_currentPlan]:
  /// - If the existing (user-modified) change does **not** conflict with the
  ///   current editing entity / journey legs → the user's resolution is still
  ///   valid; substitute the fresh auto-clamp with the existing change.
  /// - If the existing change **does** conflict with the editing entity → the
  ///   editing entity has moved such that the user's previous adjustment is now
  ///   invalid.  Keep the fresh auto-clamp so the resolution UI resets to a
  ///   safe, non-conflicting suggestion.
  ///
  /// Entities in [newPlan] that were never in [_currentPlan] are left as-is
  /// (fresh auto-clamp for newly introduced conflicts).
  void _reconcileWithExistingPlan(TripEntityUpdatePlan<TEntity> newPlan) {
    _reconcileChangeList<LodgingFacade>(
        newPlan.stayChanges, _currentPlan!.stayChanges);
    _reconcileChangeList<TransitFacade>(
        newPlan.transitChanges, _currentPlan!.transitChanges);
    _reconcileChangeList<SightFacade>(
        newPlan.sightChanges, _currentPlan!.sightChanges);
  }

  void _reconcileChangeList<T extends TripEntity<Enum>>(
      List<DateTimeChange<T>> newChanges,
      List<DateTimeChange<T>> existingChanges) {
    final existingById = <String, DateTimeChange<T>>{
      for (final c in existingChanges)
        if (c.original.id != null) c.original.id!: c,
    };

    // Iterate in reverse so index-based removal is safe.
    for (var i = newChanges.length - 1; i >= 0; i--) {
      final id = newChanges[i].original.id;
      final existing = id != null ? existingById[id] : null;
      if (existing == null) {
        continue; // new conflict — keep fresh detection
      }

      if (!_existingChangeStillConflicts(existing)) {
        newChanges[i] = existing;
      }
    }
  }

  /// Returns `true` if [existingChange]'s **modified** (user-resolved) entity
  /// still conflicts with the current editing context (journey legs or single
  /// entity).
  ///
  /// Uses [ConflictRules.isConflicting] with the editing entity as *source* so
  /// that entity-type-specific rules (e.g. Stay-vs-Transit vs
  /// Transit-vs-Stay) are applied consistently with the scanner's own scans.
  ///
  /// A `true` result means the user's previous adjustment is now invalid
  /// because the editing entity's range has moved into the conflict entity's
  /// modified time window.  The caller should discard the existing change and
  /// fall back to the fresh auto-clamp.
  ///
  /// A `false` result means the modified time is still clear of the editing
  /// entity; the user's resolution can be preserved.
  bool _existingChangeStillConflicts(EntityChangeBase existingChange) {
    // Extract the modified (resolved) entity and its time range.
    TripEntity? modified;
    TimeRange? modifiedRange;

    if (existingChange is StayChange) {
      final stay = existingChange.modified;
      modified = stay;
      if (stay.checkinDateTime != null && stay.checkoutDateTime != null) {
        modifiedRange = TimeRange(
            start: stay.checkinDateTime!, end: stay.checkoutDateTime!);
      }
    } else if (existingChange is TransitChange) {
      final transit = existingChange.modified;
      modified = transit;
      if (transit.departureDateTime != null &&
          transit.arrivalDateTime != null) {
        modifiedRange = TimeRange(
            start: transit.departureDateTime!, end: transit.arrivalDateTime!);
      }
    } else if (existingChange is SightChange) {
      final sight = existingChange.modified;
      modified = sight;
      if (sight.visitTime != null) {
        modifiedRange = TimeRange(
            start: sight.visitTime!,
            end: sight.visitTime!.add(const Duration(minutes: 1)));
      }
    }

    if (modified == null || modifiedRange == null) {
      return true; // conservative: treat as conflicting if range is unknown
    }

    // For journey editing check against ALL current legs; otherwise check
    // against the single editing entity.
    //
    // _getEditableEntityTimeRange() returns null for TransitFacade when
    // journey legs are present, so the fallback list will be empty and
    // the method conservatively returns false (no targets = no conflicts).
    final targets = _latestJourneyLegs.isNotEmpty
        ? _latestJourneyLegs
            .where(
                (l) => l.departureDateTime != null && l.arrivalDateTime != null)
            .map((l) => (
                  entity: l as TripEntity,
                  range: TimeRange(
                      start: l.departureDateTime!, end: l.arrivalDateTime!)
                ))
            .toList()
        : [
            if (_getEditableEntityTimeRange() case final r?)
              (entity: editableEntity as TripEntity, range: r)
          ];

    // editingEntity is the source so entity-type-specific ConflictRules
    // branches (e.g. _isStayVsTransitOrSightConflict) match the scanner's own
    // per-entity scan logic.
    for (final target in targets) {
      if (ConflictRules.isConflicting(
          modifiedRange.analyzePosition(target.range),
          target.entity,
          modified)) {
        return true;
      }
    }
    return false;
  }

  // ===========================================================================
  // CONFLICT DETECTION
  // ===========================================================================

  TripEntityUpdatePlan<LodgingFacade>? _detectStayConflicts(
      LodgingFacade stay) {
    final conflicts = StayConflictDetector(stay: stay, scanner: _buildScanner())
        .detectConflicts();
    if (conflicts == null) {
      return null;
    }
    return _createTripEntityUpdatePlan(
        conflicts, (originalEntity ?? editableEntity) as LodgingFacade, stay);
  }

  TripEntityUpdatePlan<TransitFacade>? _detectJourneyConflicts(
      List<TransitFacade> legs,
      {Set<String> removedLegIds = const {}}) {
    final conflicts = JourneyConflictDetector(
            legs: legs,
            scanner: _buildScanner(),
            isNewEntity: _isNewEntity,
            removedLegIds: removedLegIds)
        .detectConflicts();
    if (conflicts == null) {
      return null;
    }
    return _createTripEntityUpdatePlan(
        conflicts,
        (originalEntity ?? editableEntity) as TransitFacade,
        legs.isNotEmpty
            ? legs.first
            : (originalEntity ?? editableEntity) as TransitFacade);
  }

  TripEntityUpdatePlan<ItineraryPlanData>? _detectItineraryConflicts(
      List<SightFacade> sights) {
    final conflicts = ItineraryConflictDetector(
            sights: sights, scanner: _buildScanner(), isNewEntity: _isNewEntity)
        .detectConflicts();
    if (conflicts == null) {
      return null;
    }
    return _createTripEntityUpdatePlan(
        conflicts,
        (originalEntity ?? editableEntity) as ItineraryPlanData,
        editableEntity as ItineraryPlanData);
  }

  TripEntityUpdatePlan<TripMetadataFacade>? _detectMetadataConflicts(
      TripMetadataFacade metadata) {
    final conflicts = _buildScanner().scanForMetadataUpdate(
        oldMetadata: _tripData.tripMetadata, newMetadata: metadata);
    if (conflicts == null) {
      return null;
    }
    final tripEntityUpdatePlan = _createTripEntityUpdatePlan(
        conflicts, conflicts.oldMetadata, conflicts.newMetadata);
    tripEntityUpdatePlan.expenseChanges
        .addAll(conflicts.expenseEntities.map(_toExpenseChange));
    return tripEntityUpdatePlan;
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  TimeRange? _getEditableEntityTimeRange() {
    if (editableEntity is LodgingFacade) {
      final s = editableEntity as LodgingFacade;
      if (s.checkinDateTime != null && s.checkoutDateTime != null) {
        return TimeRange(start: s.checkinDateTime!, end: s.checkoutDateTime!);
      }
    } else if (editableEntity is TransitFacade) {
      // For journey editing _latestJourneyLegs is the authoritative source of
      // the current leg times; editableEntity is an initial snapshot and is
      // stale after the first UpdateJourney event.  Return null so callers
      // that need the journey's effective range consult _latestJourneyLegs
      // directly
      return null;
    } else if (editableEntity is TripMetadataFacade) {
      final m = editableEntity as TripMetadataFacade;
      if (m.startDate != null && m.endDate != null) {
        return TimeRange(start: m.startDate!, end: m.endDate!);
      }
    }
    return null;
  }

  // ===========================================================================
  // MAPPING HELPERS
  // ===========================================================================

  static DateTimeChange<T> _createTripEntityChange<T extends TripEntity<Enum>>(
      ConflictResult<T> conflict) {
    if (conflict.canBeClampedToResolve) {
      return DateTimeChange<T>.forClamping(
          original: conflict.entity,
          modified: conflict.clampedEntity!,
          timelinePosition: conflict.position);
    } else {
      return DateTimeChange<T>.forDeletion(
          original: conflict.entity, timelinePosition: conflict.position);
    }
  }

  TripEntityUpdatePlan<T>
      _createTripEntityUpdatePlan<T extends TripEntity<Enum>>(
          AggregatedConflicts conflicts, T oldEntity, T newEntity) {
    return TripEntityUpdatePlan<T>(
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      oldEntity: oldEntity,
      newEntity: newEntity,
      transitChanges:
          conflicts.transitConflicts.map(_createTripEntityChange).toList(),
      stayChanges:
          conflicts.stayConflicts.map(_createTripEntityChange).toList(),
      sightChanges:
          conflicts.sightConflicts.map(_createTripEntityChange).toList(),
    );
  }

  ExpenseSplitChange _toExpenseChange(ExpenseBearingTripEntity<Enum> entity) =>
      ExpenseSplitChange(
          original: entity,
          modified: entity.clone() as ExpenseBearingTripEntity<Enum>);
}
