import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';

import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';

import 'conflict_result.dart';
import 'entity_conflict_detectors.dart';
import 'trip_conflict_scanner.dart';
import 'trip_entity_editor_events.dart';
import 'trip_entity_editor_state.dart';

class TripEntityEditorBloc<T extends TripEntity>
    extends Bloc<TripEntityEditorEvent, TripEntityEditorState<T>> {
  final TripDataFacade _tripData;
  final TripConflictScanner _scanner;
  final T? originalEntity;
  final T editableEntity;
  final bool isNewEntity;

  TripEntityUpdatePlan<T>? _currentPlan;
  TripEntityUpdatePlan<T>? get currentPlan => _currentPlan;

  TripEntityEditorBloc.forCreation({
    required TripDataFacade tripData,
    required T entity,
  })  : _tripData = tripData,
        _scanner = TripConflictScanner(tripData: tripData),
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
        _scanner = TripConflictScanner(tripData: tripData),
        originalEntity = entity,
        isNewEntity = false,
        editableEntity = entity.clone() as T,
        super(TripEntityInitialized<T>(entity.clone() as T)) {
    _registerHandlers();
  }

  void _registerHandlers() {
    on<UpdateEntityTimeRange<T>>(_onUpdateEntityTimeRange);
    on<UpdateJourneyTimeRange>(_onUpdateJourneyTimeRange);
    on<UpdateConflictedEntityTimeRange>(_onUpdateConflictedEntityTimeRange);
    on<ToggleConflictedEntityDeletion>(_onToggleConflictedEntityDeletion);
    on<ConfirmConflictPlan>(_onConfirmConflictPlan);
    on<SubmitEntity>(_onSubmitEntity);
  }

  void _onUpdateEntityTimeRange(
    UpdateEntityTimeRange<T> event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (editableEntity is LodgingFacade) {
      final stay = editableEntity as LodgingFacade;
      stay.checkinDateTime = event.range.start;
      stay.checkoutDateTime = event.range.end;
      _currentPlan = _detectStayConflicts(
        (originalEntity ?? editableEntity) as LodgingFacade,
        stay,
        isNewEntity: isNewEntity,
      ) as TripEntityUpdatePlan<T>?;
    } else if (editableEntity is ItineraryPlanData) {
      // Itinerary doesn't have a single time range at the top level
    } else if (editableEntity is TripMetadataFacade) {
      final meta = editableEntity as TripMetadataFacade;
      meta.startDate = event.range.start;
      meta.endDate = event.range.end;
      _currentPlan =
          _detectTripMetadataConflicts(meta) as TripEntityUpdatePlan<T>?;
    }

    final wasExistent = _currentPlan != null;
    if (_currentPlan != null && _currentPlan!.hasConflicts) {
      if (wasExistent) {
        emit(ConflictsUpdated<T>());
      } else {
        emit(ConflictsAdded<T>());
      }
    } else if (wasExistent) {
      _currentPlan = null;
      emit(ConflictsRemoved<T>());
    } else {
      _currentPlan = null;
    }
  }

  void _onUpdateJourneyTimeRange(
    UpdateJourneyTimeRange event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (editableEntity is TransitFacade) {
      _currentPlan = _detectJourneyConflicts(
        (originalEntity ?? editableEntity) as TransitFacade,
        event.legs,
      ) as TripEntityUpdatePlan<T>?;

      final wasExistent = _currentPlan != null;
      if (_currentPlan != null && _currentPlan!.hasConflicts) {
        if (wasExistent) {
          emit(ConflictsUpdated<T>());
        } else {
          emit(ConflictsAdded<T>());
        }
      } else if (wasExistent) {
        _currentPlan = null;
        emit(ConflictsRemoved<T>());
      } else {
        _currentPlan = null;
      }
    }
  }

  void _onUpdateConflictedEntityTimeRange(
    UpdateConflictedEntityTimeRange event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (_currentPlan == null) return;

    final isConflicted = _conflictsWithEditableEntity(event.change);

    if (isConflicted) {
      emit(ConflictedEntityTimeRangeError<T>(
          event.change, "Cannot conflict with the entity being edited"));
    } else {
      event.change.markAsResolved();
      emit(ConflictsUpdated<T>());
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

    emit(ConflictsUpdated<T>());
  }

  void _onConfirmConflictPlan(
    ConfirmConflictPlan event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    if (_currentPlan != null) {
      _currentPlan!.confirm();
    }
    emit(ConflictPlanConfirmed<T>());
  }

  void _onSubmitEntity(
    SubmitEntity event,
    Emitter<TripEntityEditorState<T>> emit,
  ) {
    emit(EntitySubmitted<T>(editableEntity));
  }

  // =========================================================================
  // Internal Detection Methods (moved from EntityConflictCoordinator)
  // =========================================================================

  TripEntityUpdatePlan<TripMetadataFacade>? _detectTripMetadataConflicts(
    TripMetadataFacade editedMetadata,
  ) {
    final conflicts = _scanner.scanForMetadataUpdate(
      oldMetadata: _tripData.tripMetadata,
      newMetadata: editedMetadata,
    );
    if (conflicts == null || conflicts.isEmpty) return null;

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

  TripEntityUpdatePlan<LodgingFacade>? _detectStayConflicts(
    LodgingFacade oldStay,
    LodgingFacade newStay, {
    required bool isNewEntity,
  }) {
    final detector = StayConflictDetector(
      stay: newStay,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts(newStay);
    if (conflicts == null || conflicts.isEmpty) return null;

    return TripEntityUpdatePlan<LodgingFacade>(
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      oldEntity: oldStay,
      newEntity: newStay,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
    );
  }

  TripEntityUpdatePlan<TransitFacade>? _detectJourneyConflicts(
    TransitFacade oldTransit,
    List<TransitFacade> legs,
  ) {
    final detector = JourneyConflictDetector(legs: legs, scanner: _scanner);

    final conflicts = detector.detectConflicts(oldTransit);
    if (conflicts == null || conflicts.isEmpty) return null;

    final newTransit = legs.isNotEmpty ? legs.first : oldTransit;
    return TripEntityUpdatePlan<TransitFacade>(
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      oldEntity: oldTransit,
      newEntity: newTransit,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
    );
  }

  // =========================================================================
  // Time Range Validation logic
  // =========================================================================

  bool _conflictsWithEditableEntity(EntityChangeBase change) {
    TimeRange? referenceRange;
    if (editableEntity is LodgingFacade) {
      final stay = editableEntity as LodgingFacade;
      if (stay.checkinDateTime != null && stay.checkoutDateTime != null) {
        referenceRange = TimeRange(
          start: stay.checkinDateTime!,
          end: stay.checkoutDateTime!,
        );
      }
    } else if (editableEntity is TransitFacade) {
      final transit = editableEntity as TransitFacade;
      if (transit.departureDateTime != null &&
          transit.arrivalDateTime != null) {
        referenceRange = TimeRange(
          start: transit.departureDateTime!,
          end: transit.arrivalDateTime!,
        );
      }
    } else if (editableEntity is TripMetadataFacade) {
      final meta = editableEntity as TripMetadataFacade;
      if (meta.startDate != null && meta.endDate != null) {
        referenceRange = TimeRange(
          start: meta.startDate!,
          end: meta.endDate!,
        );
      }
    }

    if (referenceRange == null) return false;

    TimeRange? changeRange;
    final modified = change.modified;
    if (modified is LodgingFacade) {
      if (modified.checkinDateTime != null &&
          modified.checkoutDateTime != null) {
        changeRange = TimeRange(
            start: modified.checkinDateTime!, end: modified.checkoutDateTime!);
      }
    } else if (modified is TransitFacade) {
      if (modified.departureDateTime != null &&
          modified.arrivalDateTime != null) {
        changeRange = TimeRange(
            start: modified.departureDateTime!, end: modified.arrivalDateTime!);
      }
    } else if (modified is SightFacade) {
      if (modified.visitTime != null) {
        changeRange = TimeRange(
            start: modified.visitTime!,
            end: modified.visitTime!.add(const Duration(minutes: 1)));
      }
    }

    if (changeRange == null) return false;

    final position = changeRange.analyzePosition(referenceRange);

    if (editableEntity is TripMetadataFacade) {
      return position == EntityTimelinePosition.beforeEvent ||
          position == EntityTimelinePosition.afterEvent ||
          position == EntityTimelinePosition.startsBeforeEndsDuring ||
          position == EntityTimelinePosition.startsDuringEndsAfter ||
          position == EntityTimelinePosition.contains;
    } else {
      return position == EntityTimelinePosition.exactBoundaryMatch ||
          position == EntityTimelinePosition.containedIn ||
          position == EntityTimelinePosition.contains ||
          position == EntityTimelinePosition.startsDuringEndsAfter ||
          position == EntityTimelinePosition.startsBeforeEndsDuring;
    }
  }

  // =========================================================================
  // Internal mapping helpers (inlined from ConflictToEntityChangeAdapter)
  // =========================================================================

  TransitChange _toTransitChange(TransitConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return TransitChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
      );
    } else {
      return TransitChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
      );
    }
  }

  StayChange _toStayChange(StayConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return StayChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
      );
    } else {
      return StayChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
      );
    }
  }

  SightChange _toSightChange(SightConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return SightChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
      );
    } else {
      return SightChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
      );
    }
  }

  ExpenseSplitChange _toExpenseChange(ExpenseBearingTripEntity entity) {
    return ExpenseSplitChange(
      original: entity,
      modified: entity.clone(),
    );
  }
}
