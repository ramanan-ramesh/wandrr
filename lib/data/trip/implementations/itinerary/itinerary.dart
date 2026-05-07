import 'dart:async';

import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import 'itinerary_plan_data_implementation.dart';

/// Concrete itinerary. Implements the public [ItineraryFacade] read interface.
///
/// Mutation methods (transit/lodging writes, plan-data application) are
/// package-internal: they are only called from [ItineraryCollection] which
/// stores and manages instances of this type directly.
class ItineraryModelImplementation implements ItineraryFacade {
  @override
  final String tripId;

  @override
  final DateTime day;

  // ── transits ──────────────────────────────────────────────────────────────

  @override
  Iterable<TransitFacade> get transits =>
      _transits.map((t) => t.clone()).toList()
        ..sort((a, b) => a.departureDateTime!.compareTo(b.departureDateTime!));
  final List<TransitFacade> _transits;

  void addTransit(TransitFacade transit) {
    if (!_transits.any((t) => t.id == transit.id)) {
      _transits.add(transit);
    }
  }

  void removeTransit(String transitId) =>
      _transits.removeWhere((t) => t.id == transitId);

  // ── lodging ───────────────────────────────────────────────────────────────

  @override
  LodgingFacade? get checkInLodging => _checkInLodging?.clone();
  LodgingFacade? _checkInLodging;
  set checkInLodging(LodgingFacade? v) => _checkInLodging = v;

  @override
  LodgingFacade? get checkOutLodging => _checkOutLodging?.clone();
  LodgingFacade? _checkOutLodging;
  set checkOutLodging(LodgingFacade? v) => _checkOutLodging = v;

  @override
  LodgingFacade? get fullDayLodging => _fullDayLodging?.clone();
  LodgingFacade? _fullDayLodging;
  set fullDayLodging(LodgingFacade? v) => _fullDayLodging = v;

  // ── plan data ─────────────────────────────────────────────────────────────

  @override
  Stream<CollectionItemChangeMetadata<Changeset<ItineraryPlanData>>>
      get planDataStream => _planDataStreamController.stream;
  final StreamController<
          CollectionItemChangeMetadata<Changeset<ItineraryPlanData>>>
      _planDataStreamController = StreamController.broadcast();

  @override
  ItineraryPlanData get planData => _planData.clone();
  ItineraryPlanDataModelImplementation _planData;

  /// Applies [newPlanData] as the current plan data.
  ///
  /// During the collection's initial load [silent] is `true`: the internal
  /// state is updated but nothing is emitted on [planDataStream].  After the
  /// collection is fully loaded every call emits on the stream so that
  /// subscribers can react to incremental changes.
  ///
  /// [isFromExplicitAction] distinguishes UI-driven writes from remote syncs.
  void applyPlanData(
    ItineraryPlanDataModelImplementation newPlanData, {
    bool isFromExplicitAction = false,
    bool silent = false,
  }) {
    final before = _planData.facade;
    _planData = newPlanData;
    if (!silent) {
      _planDataStreamController.add(CollectionItemChangeMetadata(
          Changeset(before, _planData.facade),
          isFromExplicitAction: isFromExplicitAction));
    }
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────

  Future<void> dispose() async => _planDataStreamController.close();

  // ── TripEntity / Equatable ────────────────────────────────────────────────

  @override
  String get id => day.toIso8601String();

  @override
  ItineraryFacade clone() => ItineraryModelImplementation._(
        tripId: tripId,
        day: day,
        planData: ItineraryPlanDataModelImplementation.fromModelFacade(
            _planData.facade),
        transits: _transits.map((e) => e.clone()).toList(),
        checkInLodging: _checkInLodging?.clone(),
        checkOutLodging: _checkOutLodging?.clone(),
        fullDayLodging: _fullDayLodging?.clone(),
      );

  @override
  List<Object?> get props => [tripId, day, planData, transits, checkInLodging];

  @override
  bool? get stringify => true;

  @override
  Iterable<ItineraryValidationError> getValidationErrors() {
    final errors = <ItineraryValidationError>[];
    if (planData.getValidationErrors().isNotEmpty) {
      errors.add(ItineraryValidationError.planDataInvalid);
    }
    if (fullDayLodging != null &&
        (checkInLodging != null || checkOutLodging != null)) {
      errors.add(ItineraryValidationError.duplicateLodging);
    }
    return errors;
  }

  // ── factory / constructor ─────────────────────────────────────────────────

  static ItineraryModelImplementation createInstance({
    required String tripId,
    required DateTime day,
    required Iterable<TransitFacade> transits,
    required LodgingFacade? checkinLodging,
    required LodgingFacade? checkoutLodging,
    required LodgingFacade? fullDayLodging,
    ItineraryPlanDataModelImplementation? planData,
  }) {
    final planDataId = day.itineraryDateFormat;
    return ItineraryModelImplementation._(
      tripId: tripId,
      day: day,
      planData: planData ??
          ItineraryPlanDataModelImplementation(
            tripId: tripId,
            day: day,
            id: planDataId,
            sights: const [],
            notes: const [],
            checkLists: const [],
          ),
      transits: transits.toList(),
      checkInLodging: checkinLodging,
      checkOutLodging: checkoutLodging,
      fullDayLodging: fullDayLodging,
    );
  }

  ItineraryModelImplementation._({
    required this.tripId,
    required this.day,
    required ItineraryPlanDataModelImplementation planData,
    required List<TransitFacade> transits,
    LodgingFacade? checkInLodging,
    LodgingFacade? checkOutLodging,
    LodgingFacade? fullDayLodging,
  })  : _planData = planData,
        _transits = transits,
        _checkInLodging = checkInLodging,
        _checkOutLodging = checkOutLodging,
        _fullDayLodging = fullDayLodging;
}
