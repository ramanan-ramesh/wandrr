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

import 'conflict_detectors.dart';
import 'conflict_result.dart';
import 'events.dart';
import 'states.dart';
import 'unified_conflict_scanner.dart';

/// BLoC for editing trip entities with conflict detection and resolution.
///
/// Conflict detection runs synchronously on the main isolate — it operates on
/// already-loaded in-memory collections (microseconds of work).
///
/// Plan-change states:
///   [PlanUpdated]     – structural change: sections gained/lost items
///   [PlanItemsUpdated]– in-place change: item times / delete flags changed
///   [PlanCleared]     – plan removed, all conflicts gone
///
/// The plan itself is never stored in state; always read via
/// `bloc.currentPlan` or `context.tripEntityUpdatePlan<T>()`.
class TripEntityEditorBloc<TEntity extends TripEntity>
    extends Bloc<TripEntityEditorEvent, TripEntityEditorState<TEntity>> {
  final TripDataFacade _tripData;
  final TEntity? originalEntity;
  final TEntity editableEntity;

  bool get _isNewEntity => originalEntity == null;

  TripEntityUpdatePlan<TEntity>? get currentPlan => _currentPlan;
  TripEntityUpdatePlan<TEntity>? _currentPlan;

  TripEntityEditorBloc._({
    required TripDataFacade tripData,
    required TEntity? original,
    required TEntity editable,
  })  : _tripData = tripData,
        originalEntity = original,
        editableEntity = editable,
        super(TripEntityInitialized<TEntity>(editable)) {
    on<UpdateEntityTimeRange<TEntity>>(_onUpdateEntityTimeRange);
    on<UpdateJourneyTimeRange>(_onUpdateJourneyTimeRange);
    on<UpdateSightsTimeRange>(_onUpdateSightsTimeRange);
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

  void _onUpdateEntityTimeRange(
    UpdateEntityTimeRange<TEntity> event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    TripEntityUpdatePlan<TEntity>? newPlan;

    if (editableEntity is LodgingFacade) {
      final stay = editableEntity as LodgingFacade;
      stay.checkinDateTime = event.range.start;
      stay.checkoutDateTime = event.range.end;
      newPlan = _detectStayConflicts(stay) as TripEntityUpdatePlan<TEntity>?;
    } else if (editableEntity is TripMetadataFacade) {
      final meta = editableEntity as TripMetadataFacade;
      meta.startDate = event.range.start;
      meta.endDate = event.range.end;
      newPlan =
          _detectMetadataConflicts(meta) as TripEntityUpdatePlan<TEntity>?;
    }

    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateJourneyTimeRange(
    UpdateJourneyTimeRange event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (editableEntity is! TransitFacade) return;
    final newPlan =
        _detectJourneyConflicts(event.legs) as TripEntityUpdatePlan<TEntity>?;
    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateSightsTimeRange(
    UpdateSightsTimeRange event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (editableEntity is! ItineraryPlanData) return;

    final overlapError = _checkSightOverlaps(event.sights);
    if (overlapError != null) {
      emit(overlapError);
      return;
    }

    final newPlan = _detectItineraryConflicts(event.sights)
        as TripEntityUpdatePlan<TEntity>?;
    _handlePlanUpdate(newPlan, emit);
  }

  void _onUpdateConflictedEntityTimeRange(
    UpdateConflictedEntityTimeRange event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (_currentPlan == null) return;

    final result = _buildScanner().resolveConflictedEntityTimeChange(
      modifiedChange: event.change,
      editableEntityRange: _getEditableEntityTimeRange(),
      editableEntity: editableEntity,
      existingStayChanges: _currentPlan!.stayChanges,
      existingTransitChanges: _currentPlan!.transitChanges,
      existingSightChanges: _currentPlan!.sightChanges,
    );

    if (!result.isValid) {
      emit(ConflictedEntityTimeRangeError<TEntity>(
          event.change, result.errorMessage!, event.change.original));
      return;
    }

    // Merge any newly discovered inter-conflicts and emit PlanUpdated for
    // sections that gained items.
    final addedSections = _mergeNewConflicts(result.newConflicts);
    if (addedSections.isNotEmpty) {
      emit(PlanUpdated<TEntity>(addedSections));
    }

    // Emit PlanItemsUpdated for sections whose items were modified in-place.
    final touchedSections = _sectionsOf(result.allUpdatedChanges);
    if (touchedSections.isNotEmpty) {
      emit(PlanItemsUpdated<TEntity>(touchedSections));
    }
  }

  void _onToggleConflictedEntityDeletion(
    ToggleConflictedEntityDeletion event,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    if (_currentPlan == null) return;

    final newIsDeleted = !event.change.isMarkedForDeletion;
    if (newIsDeleted) {
      event.change.markForDeletion();
    } else {
      event.change.restore();
    }
    _currentPlan!.syncExpenseDeletionState(event.change.original, newIsDeleted);

    emit(PlanItemsUpdated<TEntity>(_sectionsOf([event.change])));
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

  /// Compares the incoming [newPlan] against the current plan and emits the
  /// minimal set of states needed to update the UI.
  ///
  /// • Structural changes (ID sets differ) → [PlanUpdated] for affected sections
  /// • Content-only changes (same IDs, different state) → [PlanItemsUpdated]
  /// • All sections gone → [PlanCleared]
  void _handlePlanUpdate(
    TripEntityUpdatePlan<TEntity>? newPlan,
    Emitter<TripEntityEditorState<TEntity>> emit,
  ) {
    final hadPlan = _currentPlan != null;

    // Shallow-copy the old lists BEFORE replacing the plan reference.
    final oldStays = hadPlan
        ? List<StayChange>.of(_currentPlan!.stayChanges)
        : const <StayChange>[];
    final oldTransits = hadPlan
        ? List<TransitChange>.of(_currentPlan!.transitChanges)
        : const <TransitChange>[];
    final oldSights = hadPlan
        ? List<SightChange>.of(_currentPlan!.sightChanges)
        : const <SightChange>[];
    final oldExpenses = hadPlan
        ? List<ExpenseSplitChange>.of(_currentPlan!.expenseChanges)
        : const <ExpenseSplitChange>[];

    _currentPlan = (newPlan != null && newPlan.hasConflicts) ? newPlan : null;

    final newStays = _currentPlan?.stayChanges ?? const [];
    final newTransits = _currentPlan?.transitChanges ?? const [];
    final newSights = _currentPlan?.sightChanges ?? const [];
    final newExpenses = _currentPlan?.expenseChanges ?? const [];

    final structurallyChanged = <ConflictSection>{};
    final contentChanged = <ConflictSection>{};

    _diffSection(oldStays, newStays, ConflictSection.stays, structurallyChanged,
        contentChanged);
    _diffSection(oldTransits, newTransits, ConflictSection.transits,
        structurallyChanged, contentChanged);
    _diffSection(oldSights, newSights, ConflictSection.sights,
        structurallyChanged, contentChanged);
    _diffSection(oldExpenses, newExpenses, ConflictSection.expenses,
        structurallyChanged, contentChanged);

    // If every section is now empty and there was a plan before → cleared.
    if (_currentPlan == null && hadPlan) {
      emit(const PlanCleared());
      return;
    }

    if (structurallyChanged.isNotEmpty)
      emit(PlanUpdated<TEntity>(structurallyChanged));
    if (contentChanged.isNotEmpty)
      emit(PlanItemsUpdated<TEntity>(contentChanged));
  }

  /// Compares [oldItems] to [newItems]:
  /// - ID set differs  → adds [section] to [structural]
  /// - IDs same, content differs → adds [section] to [content]
  void _diffSection<C extends EntityChangeBase>(
    List<C> oldItems,
    List<C> newItems,
    ConflictSection section,
    Set<ConflictSection> structural,
    Set<ConflictSection> content,
  ) {
    final wasEmpty = oldItems.isEmpty;
    final nowEmpty = newItems.isEmpty;

    if (wasEmpty && nowEmpty) return;
    if (wasEmpty != nowEmpty) {
      structural.add(section);
      return;
    }

    // Both non-empty – compare ID sets.
    final oldIds = {for (final c in oldItems) c.original.id};
    final newIds = {for (final c in newItems) c.original.id};
    if (oldIds.length != newIds.length ||
        !oldIds.containsAll(newIds) ||
        !newIds.containsAll(oldIds)) {
      structural.add(section);
      return;
    }

    // Same IDs – check content.
    final oldById = {for (final c in oldItems) c.original.id: c};
    final anyContentDiff = newItems.any((n) {
      final o = oldById[n.original.id];
      return o == null || _changeContentDiffers(o, n);
    });
    if (anyContentDiff) content.add(section);
  }

  /// Returns true when [newC] differs from [oldC] in any UI-observable way.
  bool _changeContentDiffers(EntityChangeBase oldC, EntityChangeBase newC) {
    if (oldC.isDelete != newC.isDelete) return true;
    if (oldC.isClamped != newC.isClamped) return true;
    if (oldC is StayChange && newC is StayChange) {
      return oldC.modified.checkinDateTime != newC.modified.checkinDateTime ||
          oldC.modified.checkoutDateTime != newC.modified.checkoutDateTime;
    }
    if (oldC is TransitChange && newC is TransitChange) {
      return oldC.modified.departureDateTime !=
              newC.modified.departureDateTime ||
          oldC.modified.arrivalDateTime != newC.modified.arrivalDateTime;
    }
    if (oldC is SightChange && newC is SightChange) {
      return oldC.modified.visitTime != newC.modified.visitTime;
    }
    if (oldC is ExpenseSplitChange && newC is ExpenseSplitChange) {
      return oldC.includeInSplitBy != newC.includeInSplitBy;
    }
    return false;
  }

  /// Merges [newConflicts] into the current plan.
  /// Returns the set of sections that received new items.
  Set<ConflictSection> _mergeNewConflicts(
      Iterable<EntityChangeBase> newConflicts) {
    if (newConflicts.isEmpty || _currentPlan == null) return const {};

    final added = <ConflictSection>{};
    for (final change in newConflicts) {
      if (change is StayChange) {
        _currentPlan!.stayChanges.add(change);
        added.add(ConflictSection.stays);
      } else if (change is TransitChange) {
        _currentPlan!.transitChanges.add(change);
        added.add(ConflictSection.transits);
      } else if (change is SightChange) {
        _currentPlan!.sightChanges.add(change);
        added.add(ConflictSection.sights);
      }
    }
    return added;
  }

  /// Returns the set of [ConflictSection]s touched by [changes].
  Set<ConflictSection> _sectionsOf(Iterable<EntityChangeBase> changes) {
    final sections = <ConflictSection>{};
    for (final c in changes) {
      if (c is StayChange)
        sections.add(ConflictSection.stays);
      else if (c is TransitChange)
        sections.add(ConflictSection.transits);
      else if (c is SightChange) sections.add(ConflictSection.sights);
    }
    return sections;
  }

  // ===========================================================================
  // CONFLICT DETECTION
  // ===========================================================================

  TripEntityUpdatePlan<LodgingFacade>? _detectStayConflicts(
      LodgingFacade stay) {
    final conflicts = StayConflictDetector(
            stay: stay, scanner: _buildScanner(), isNewEntity: _isNewEntity)
        .detectConflicts();
    if (conflicts == null) return null;
    return _createTripEntityUpdatePlan(
        conflicts, (originalEntity ?? editableEntity) as LodgingFacade, stay);
  }

  TripEntityUpdatePlan<TransitFacade>? _detectJourneyConflicts(
      List<TransitFacade> legs) {
    final conflicts = JourneyConflictDetector(
            legs: legs, scanner: _buildScanner(), isNewEntity: _isNewEntity)
        .detectConflicts();
    if (conflicts == null) return null;
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
    if (conflicts == null) return null;
    return _createTripEntityUpdatePlan(
        conflicts,
        (originalEntity ?? editableEntity) as ItineraryPlanData,
        editableEntity as ItineraryPlanData);
  }

  TripEntityUpdatePlan<TripMetadataFacade>? _detectMetadataConflicts(
      TripMetadataFacade metadata) {
    final conflicts = _buildScanner().scanForMetadataUpdate(
        oldMetadata: _tripData.tripMetadata, newMetadata: metadata);
    if (conflicts == null) return null;
    final tripEntityUpdatePlan = _createTripEntityUpdatePlan(
        conflicts, conflicts.oldMetadata, conflicts.newMetadata);
    tripEntityUpdatePlan.expenseChanges
      ..addAll(conflicts.expenseEntities.map(_toExpenseChange));
    return tripEntityUpdatePlan;
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  ConflictedEntityTimeRangeError<TEntity>? _checkSightOverlaps(
      List<SightFacade> sights) {
    for (int i = 0; i < sights.length; i++) {
      final s1 = sights[i];
      if (s1.visitTime == null) continue;
      final r1 = TimeRange(
          start: s1.visitTime!,
          end: s1.visitTime!.add(const Duration(minutes: 1)));
      for (int j = i + 1; j < sights.length; j++) {
        final s2 = sights[j];
        if (s2.visitTime == null) continue;
        final r2 = TimeRange(
            start: s2.visitTime!,
            end: s2.visitTime!.add(const Duration(minutes: 1)));
        if (r1.overlapsWith(r2)) {
          return ConflictedEntityTimeRangeError<TEntity>(
            SightChange.forClamping(
                original: s2,
                modified: s2,
                timelinePosition: EntityTimelinePosition.isOverlapping),
            'Sights cannot overlap on the same day',
            s2.clone(),
          );
        }
      }
    }
    return null;
  }

  TimeRange? _getEditableEntityTimeRange() {
    if (editableEntity is LodgingFacade) {
      final s = editableEntity as LodgingFacade;
      if (s.checkinDateTime != null && s.checkoutDateTime != null) {
        return TimeRange(start: s.checkinDateTime!, end: s.checkoutDateTime!);
      }
    } else if (editableEntity is TransitFacade) {
      final t = editableEntity as TransitFacade;
      if (t.departureDateTime != null && t.arrivalDateTime != null) {
        return TimeRange(start: t.departureDateTime!, end: t.arrivalDateTime!);
      }
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

  static DateTimeChange<T> _createTripEntityChange<T extends TripEntity>(
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

  TripEntityUpdatePlan<T> _createTripEntityUpdatePlan<T extends TripEntity>(
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

  ExpenseSplitChange _toExpenseChange(ExpenseBearingTripEntity entity) =>
      ExpenseSplitChange(original: entity, modified: entity.clone());
}
