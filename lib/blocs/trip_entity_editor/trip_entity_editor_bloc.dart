import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'conflict_result.dart';
import 'streamlined_conflict_detectors.dart';
import 'trip_entity_editor_events.dart';
import 'trip_entity_editor_state.dart';
import 'unified_conflict_scanner.dart';

// =============================================================================
// TRIP ENTITY EDITOR BLOC - Streamlined version with SOLID principles
// =============================================================================

/// BLoC for editing trip entities with conflict detection and resolution.
///
/// This bloc follows SOLID principles:
/// - Single Responsibility: Orchestrates entity editing and conflict management
/// - Open/Closed: Extensible through conflict detectors without modification
/// - Liskov Substitution: All detectors implement the same interface
/// - Interface Segregation: Small, focused interfaces for each concern
/// - Dependency Inversion: Depends on abstractions (scanner, detectors)
///
/// Key features:
/// - Unified conflict detection across all entity types
/// - Inter-conflict detection (when editing a conflicted item causes another conflict)
/// - New conflict detection from trip repository when editing conflicted items
/// - Automatic clamping with fallback to deletion marking
/// - Consistent `isNewEntity` handling across all detectors
/// - Emits [ConflictItemUpdated] for each affected change for localized UI updates
class TripEntityEditorBloc<T extends TripEntity>
    extends Bloc<TripEntityEditorEvent, TripEntityEditorState<T>> {
  final TripDataFacade _tripData;
  final UnifiedConflictScanner _scanner;
  final T? originalEntity;
  final T editableEntity;
  final bool isNewEntity;

  TripEntityUpdatePlan<T>? _currentPlan;

  TripEntityUpdatePlan<T>? get currentPlan => _currentPlan;

  // ===========================================================================
  // CONSTRUCTORS
  // ===========================================================================

  TripEntityEditorBloc.forCreation({
    required TripDataFacade tripData,
    required T entity,
  })  : _tripData = tripData,
        _scanner = UnifiedConflictScanner(tripData: tripData),
        originalEntity = null,
        isNewEntity = true,
        editableEntity = entity,
        super(TripEntityInitialized<T>(entity)) {
    _registerHandlers();
  }

  TripEntityEditorBloc.forEditing({
    required TripDataFacade tripData,
    required T entity,
  })  : _tripData = tripData,
        _scanner = UnifiedConflictScanner(tripData: tripData),
        originalEntity = entity,
        isNewEntity = false,
        editableEntity = entity.clone() as T,
        super(TripEntityInitialized<T>(entity.clone() as T)) {
    _registerHandlers();
  }

  void _registerHandlers() {
    on<UpdateEntityTimeRange<T>>(_onUpdateEntityTimeRange);
    on<UpdateJourneyTimeRange>(_onUpdateJourneyTimeRange);
    on<UpdateSightsTimeRange>(_onUpdateSightsTimeRange);
    on<UpdateConflictedEntityTimeRange>(_onUpdateConflictedEntityTimeRange);
    on<ToggleConflictedEntityDeletion>(_onToggleConflictedEntityDeletion);
    on<ConfirmConflictPlan>(_onConfirmConflictPlan);
    on<SubmitEntity>(_onSubmitEntity);
  }

  // ===========================================================================
  // EVENT HANDLERS
  // ===========================================================================

  void _onUpdateEntityTimeRange(
    UpdateEntityTimeRange<T> event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    TripEntityUpdatePlan<T>? newPlan;

    if (editableEntity is LodgingFacade) {
      final stay = editableEntity as LodgingFacade;
      stay.checkinDateTime = event.range.start;
      stay.checkoutDateTime = event.range.end;
      newPlan = _detectStayConflicts(stay) as TripEntityUpdatePlan<T>?;
    } else if (editableEntity is TripMetadataFacade) {
      final meta = editableEntity as TripMetadataFacade;
      meta.startDate = event.range.start;
      meta.endDate = event.range.end;
      newPlan = _detectMetadataConflicts(meta) as TripEntityUpdatePlan<T>?;
    }

    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateJourneyTimeRange(
    UpdateJourneyTimeRange event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (editableEntity is! TransitFacade) return;

    final newPlan =
        _detectJourneyConflicts(event.legs) as TripEntityUpdatePlan<T>?;
    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateSightsTimeRange(
    UpdateSightsTimeRange event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (editableEntity is! ItineraryPlanData) return;

    // Check for intra-day sight overlaps first
    final overlapError = _checkSightOverlaps(event.sights);
    if (overlapError != null) {
      emit(overlapError);
      return;
    }

    final newPlan =
        _detectItineraryConflicts(event.sights) as TripEntityUpdatePlan<T>?;
    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateConflictedEntityTimeRange(
    UpdateConflictedEntityTimeRange event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (_currentPlan == null) return;

    // Use the comprehensive resolution method that handles all conflict types
    final result = _scanner.resolveConflictedEntityTimeChange(
      modifiedChange: event.change,
      editableEntityRange: _getEditableEntityTimeRange(),
      editableEntity: editableEntity,
      existingStayChanges: _currentPlan!.stayChanges,
      existingTransitChanges: _currentPlan!.transitChanges,
      existingSightChanges: _currentPlan!.sightChanges,
    );

    if (!result.isValid) {
      // Conflict with editable entity - emit error
      emit(ConflictedEntityTimeRangeError<T>(
        event.change,
        result.errorMessage!,
        event.change.original,
        _currentPlan,
      ));
      return;
    }

    // Add new conflicts to the plan if any
    _addNewConflictsToPlan(result.newConflicts);

    // Emit updates for each affected change (enables localized UI rebuilds)
    for (final change in result.allUpdatedChanges) {
      emit(ConflictItemUpdated<T>(_currentPlan!, change));
    }
  }

  void _onToggleConflictedEntityDeletion(
    ToggleConflictedEntityDeletion event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (_currentPlan == null) return;

    final newIsDeleted = !event.change.isMarkedForDeletion;
    if (newIsDeleted) {
      event.change.markForDeletion();
    } else {
      event.change.restore();
    }

    _currentPlan!.syncExpenseDeletionState(event.change.original, newIsDeleted);
    emit(ConflictItemUpdated<T>(_currentPlan!, event.change));
  }

  void _onConfirmConflictPlan(
    ConfirmConflictPlan event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (_currentPlan != null) {
      _currentPlan!.confirm();
    }
    emit(ConflictPlanConfirmed<T>(_currentPlan!));
  }

  void _onSubmitEntity(
    SubmitEntity event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    emit(EntitySubmitted<T>(editableEntity, _currentPlan));
  }

  // ===========================================================================
  // PLAN MANAGEMENT
  // ===========================================================================

  void _handlePlanUpdate(
    TripEntityUpdatePlan<T>? newPlan,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (newPlan != null && newPlan.hasConflicts) {
      if (_currentPlan == null) {
        _currentPlan = newPlan;
        emit(ConflictsAdded<T>(_currentPlan!));
      } else {
        _currentPlan!.updateConflicts(
          stays: newPlan.stayChanges,
          transits: newPlan.transitChanges,
          sights: newPlan.sightChanges,
          expenses: newPlan.expenseChanges,
        );
        emit(ConflictsUpdated<T>(_currentPlan!));
      }
    } else {
      if (_currentPlan != null) {
        _currentPlan = null;
        emit(const ConflictsRemoved());
      }
    }
  }

  /// Adds newly discovered conflicts to the current plan.
  void _addNewConflictsToPlan(List<EntityChangeBase> newConflicts) {
    if (newConflicts.isEmpty || _currentPlan == null) return;

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
  // CONFLICT DETECTION - Delegates to specialized detectors
  // ===========================================================================

  TripEntityUpdatePlan<LodgingFacade>? _detectStayConflicts(
      LodgingFacade stay) {
    final detector = StayConflictDetector(
      stay: stay,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return TripEntityUpdatePlan<LodgingFacade>(
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      oldEntity: (originalEntity ?? editableEntity) as LodgingFacade,
      newEntity: stay,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
    );
  }

  TripEntityUpdatePlan<TransitFacade>? _detectJourneyConflicts(
    List<TransitFacade> legs,
  ) {
    final detector = JourneyConflictDetector(
      legs: legs,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    final newTransit = legs.isNotEmpty
        ? legs.first
        : (originalEntity ?? editableEntity) as TransitFacade;

    return TripEntityUpdatePlan<TransitFacade>(
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      oldEntity: (originalEntity ?? editableEntity) as TransitFacade,
      newEntity: newTransit,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
    );
  }

  TripEntityUpdatePlan<ItineraryPlanData>? _detectItineraryConflicts(
    List<SightFacade> sights,
  ) {
    final detector = ItineraryConflictDetector(
      sights: sights,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return TripEntityUpdatePlan<ItineraryPlanData>(
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      oldEntity: (originalEntity ?? editableEntity) as ItineraryPlanData,
      newEntity: editableEntity as ItineraryPlanData,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
    );
  }

  TripEntityUpdatePlan<TripMetadataFacade>? _detectMetadataConflicts(
    TripMetadataFacade metadata,
  ) {
    final conflicts = _scanner.scanForMetadataUpdate(
      oldMetadata: _tripData.tripMetadata,
      newMetadata: metadata,
    );
    if (conflicts == null) return null;

    return TripEntityUpdatePlan<TripMetadataFacade>(
      oldEntity: conflicts.oldMetadata,
      newEntity: conflicts.newMetadata,
      tripStartDate: conflicts.newMetadata.startDate!,
      tripEndDate: conflicts.newMetadata.endDate!,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
      expenseChanges: conflicts.expenseEntities.map(_toExpenseChange).toList(),
    );
  }

  // ===========================================================================
  // VALIDATION HELPERS
  // ===========================================================================

  /// Checks for overlapping sight times within the same itinerary.
  ConflictedEntityTimeRangeError<T>? _checkSightOverlaps(
      List<SightFacade> sights) {
    for (int i = 0; i < sights.length; i++) {
      final s1 = sights[i];
      if (s1.visitTime == null) continue;

      final r1 = TimeRange(
        start: s1.visitTime!,
        end: s1.visitTime!.add(const Duration(minutes: 1)),
      );

      for (int j = i + 1; j < sights.length; j++) {
        final s2 = sights[j];
        if (s2.visitTime == null) continue;

        final r2 = TimeRange(
          start: s2.visitTime!,
          end: s2.visitTime!.add(const Duration(minutes: 1)),
        );

        if (r1.overlapsWith(r2)) {
          return ConflictedEntityTimeRangeError<T>(
            SightChange.forClamping(
              original: s2,
              modified: s2,
              timelinePosition: EntityTimelinePosition.isOverlapping,
            ),
            "Sights cannot overlap on the same day",
            s2.clone(),
            _currentPlan,
          );
        }
      }
    }
    return null;
  }

  /// Gets the time range of the editable entity.
  TimeRange? _getEditableEntityTimeRange() {
    if (editableEntity is LodgingFacade) {
      final stay = editableEntity as LodgingFacade;
      if (stay.checkinDateTime != null && stay.checkoutDateTime != null) {
        return TimeRange(
            start: stay.checkinDateTime!, end: stay.checkoutDateTime!);
      }
    } else if (editableEntity is TransitFacade) {
      final transit = editableEntity as TransitFacade;
      if (transit.departureDateTime != null &&
          transit.arrivalDateTime != null) {
        return TimeRange(
            start: transit.departureDateTime!, end: transit.arrivalDateTime!);
      }
    } else if (editableEntity is TripMetadataFacade) {
      final meta = editableEntity as TripMetadataFacade;
      if (meta.startDate != null && meta.endDate != null) {
        return TimeRange(start: meta.startDate!, end: meta.endDate!);
      }
    }
    return null;
  }

  // ===========================================================================
  // MAPPING HELPERS - Convert ConflictResult to EntityChange
  // ===========================================================================

  TransitChange _toTransitChange(TransitConflict conflict) {
    return conflict.canBeClampedToResolve
        ? TransitChange.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : TransitChange.forDeletion(
            original: conflict.entity,
            timelinePosition: conflict.position,
          );
  }

  StayChange _toStayChange(StayConflict conflict) {
    return conflict.canBeClampedToResolve
        ? StayChange.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : StayChange.forDeletion(
            original: conflict.entity,
            timelinePosition: conflict.position,
          );
  }

  SightChange _toSightChange(SightConflict conflict) {
    return conflict.canBeClampedToResolve
        ? SightChange.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : SightChange.forDeletion(
            original: conflict.entity,
            timelinePosition: conflict.position,
          );
  }

  ExpenseSplitChange _toExpenseChange(ExpenseBearingTripEntity entity) {
    return ExpenseSplitChange(original: entity, modified: entity.clone());
  }
}
