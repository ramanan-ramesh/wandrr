import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';

import 'sight.dart';

class ItineraryPlanDataModelImplementation extends ItineraryPlanData
    implements LeafRepositoryItem<ItineraryPlanData> {
  static const String _sightsField = 'sights';
  static const String _notesField = 'notes';
  static const String _checkListsField = 'checkLists';

  @override
  List<SightFacade> get sights =>
      List.from(_sights.map((sight) => sight.clone()));
  final List<SightFacade> _sights;

  @override
  List<String> get notes => List.from(_notes);
  final List<String> _notes;

  @override
  List<CheckListFacade> get checkLists =>
      List.from(_checkLists.map((checkList) => checkList.clone()));
  final List<CheckListFacade> _checkLists;

  ItineraryPlanDataModelImplementation({
    required super.tripId,
    required super.day,
    required List<SightFacade> sights,
    required List<String> notes,
    required List<CheckListFacade> checkLists,
    super.id,
  })  : _sights = sights,
        _notes = notes,
        _checkLists = checkLists,
        super(sights: [], notes: [], checkLists: []);

  factory ItineraryPlanDataModelImplementation.fromModelFacade(
      ItineraryPlanData planDataFacade) {
    return ItineraryPlanDataModelImplementation(
      tripId: planDataFacade.tripId,
      id: planDataFacade.id,
      day: planDataFacade.day,
      sights: planDataFacade.sights
          .map(SightModelImplementation.fromModelFacade)
          .toList(),
      notes: List.from(planDataFacade.notes),
      checkLists: planDataFacade.checkLists
          .map(CheckListModelImplementation.fromModelFacade)
          .toList(),
    );
  }

  factory ItineraryPlanDataModelImplementation.fromDocumentSnapshot({
    required String tripId,
    required DocumentSnapshot documentSnapshot,
    required DateTime day,
  }) {
    final data = documentSnapshot.data();
    if (data is! Map<String, dynamic>) {
      throw Exception('Document data is invalid');
    }

    return ItineraryPlanDataModelImplementation(
      tripId: tripId,
      id: documentSnapshot.id,
      day: day,
      sights: (data[_sightsField] as List?)
              ?.map((json) => SightModelImplementation.fromJson(
                  json as Map<String, dynamic>, day, tripId))
              .toList() ??
          [],
      notes: (data[_notesField] as List?)
              ?.map((noteValue) => noteValue.toString())
              .toList() ??
          [],
      checkLists: (data[_checkListsField] as List?)
              ?.map((json) => CheckListModelImplementation.fromDocumentData(
                  documentData: json, tripId: tripId))
              .toList() ??
          [],
    );
  }

  DocumentReference<Map<String, dynamic>> get documentReference {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .doc(id ?? day.itineraryDateFormat);
  }

  Map<String, dynamic> toJson() {
    return {
      if (_sights.isNotEmpty)
        _sightsField: _sights
            .map((sight) => (sight as SightModelImplementation).toJson())
            .toList(),
      if (_notes.isNotEmpty) _notesField: _notes,
      if (_checkLists.isNotEmpty)
        _checkListsField: _checkLists
            .map((checkList) =>
                (checkList as CheckListModelImplementation).toJson())
            .toList(),
    };
  }

  @override
  ItineraryPlanData get facade => this;
}
