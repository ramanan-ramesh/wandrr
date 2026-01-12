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
    implements RepositoryDocument<ItineraryPlanData> {
  static const String _sightsField = 'sights';
  static const String _notesField = 'notes';
  static const String _checkListsField = 'checkLists';

  @override
  List<SightFacade> get sights =>
      List.from(_sights.map((sight) => sight.clone()));
  final List<SightModelImplementation> _sights;

  @override
  List<String> get notes => List.from(_notes);
  final List<String> _notes;

  @override
  List<CheckListFacade> get checkLists =>
      List.from(_checkLists.map((checkList) => checkList.clone()));
  final List<CheckListModelImplementation> _checkLists;

  ItineraryPlanDataModelImplementation({
    required super.tripId,
    required super.day,
    required List<SightFacade> sights,
    required List<String> notes,
    required List<CheckListFacade> checkLists,
    super.id,
  })  : _sights = _generateSightModelImplementations(sights, tripId, day),
        _notes = notes,
        _checkLists = List.generate(
            checkLists.length,
            (index) => CheckListModelImplementation.fromModelFacade(
                checkLists[index])),
        super(sights: [], notes: [], checkLists: []);

  factory ItineraryPlanDataModelImplementation.fromModelFacade(
      ItineraryPlanData planDataFacade) {
    return ItineraryPlanDataModelImplementation(
      tripId: planDataFacade.tripId,
      id: planDataFacade.id,
      day: planDataFacade.day,
      sights: _generateSightModelImplementations(
          planDataFacade.sights, planDataFacade.tripId, planDataFacade.day),
      notes: List.from(planDataFacade.notes),
      checkLists: planDataFacade.checkLists
          .map(CheckListModelImplementation.fromModelFacade)
          .toList(),
    );
  }

  factory ItineraryPlanDataModelImplementation.fromDocumentSnapshot({
    required String tripId,
    required Map<String, dynamic> documentData,
    required DateTime day,
  }) {
    final formattedDay = day.itineraryDateFormat;

    final sights = <SightModelImplementation>[];
    final sightDataList = (documentData[_sightsField] as List?) ?? [];
    for (var i = 0; i < sightDataList.length; i++) {
      final sightData = sightDataList[i] as Map<String, dynamic>;
      sights.add(SightModelImplementation.fromJson(
        sightData,
        day,
        i,
        tripId,
      ));
    }

    return ItineraryPlanDataModelImplementation(
      tripId: tripId,
      id: formattedDay,
      day: day,
      sights: sights,
      notes: (documentData[_notesField] as List?)
              ?.map((noteValue) => noteValue.toString())
              .toList() ??
          [],
      checkLists: (documentData[_checkListsField] as List?)
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
        _sightsField: _sights.map((sight) => sight.toJson()).toList(),
      if (_notes.isNotEmpty) _notesField: _notes,
      if (_checkLists.isNotEmpty)
        _checkListsField:
            _checkLists.map((checkList) => checkList.toJson()).toList(),
    };
  }

  @override
  ItineraryPlanData get facade => this;

  static List<SightModelImplementation> _generateSightModelImplementations(
      List<SightFacade> sights, String tripId, DateTime day) {
    return List.generate(
        sights.length,
        (index) => SightModelImplementation.fromModelFacade(SightFacade(
            tripId: tripId,
            id: index.toString(),
            name: sights[index].name,
            day: day,
            description: sights[index].description,
            expense: sights[index].expense,
            location: sights[index].location,
            visitTime: sights[index].visitTime)));
  }
}
