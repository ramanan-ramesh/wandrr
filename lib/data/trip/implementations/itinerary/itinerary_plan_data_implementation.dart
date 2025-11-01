import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/check_list.dart';
import 'package:wandrr/data/trip/implementations/itinerary/note.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';

import 'sight.dart';

class ItineraryPlanDataModelImplementation extends ItineraryPlanData
    implements LeafRepositoryItem<ItineraryPlanData> {
  static const String _sightsField = 'sights';
  static const String _notesField = 'notes';
  static const String _checkListsField = 'checkLists';

  ItineraryPlanDataModelImplementation({
    required super.tripId,
    required super.day,
    required super.sights,
    required super.notes,
    required super.checkLists,
    super.id,
  });

  factory ItineraryPlanDataModelImplementation.fromModelFacade(
      ItineraryPlanData planDataFacade) {
    return ItineraryPlanDataModelImplementation(
      tripId: planDataFacade.tripId,
      id: planDataFacade.id,
      day: planDataFacade.day,
      sights: planDataFacade.sights
          .map(SightModelImplementation.fromModelFacade)
          .toList(),
      notes: planDataFacade.notes
          .map(NoteModelImplementation.fromModelFacade)
          .toList(),
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
      sights: (data[_sightsField] as List<dynamic>?)
              ?.map((json) => SightModelImplementation.fromJson(
                  json as Map<String, dynamic>, day, tripId))
              .toList() ??
          [],
      notes: (data[_notesField] as List<dynamic>?)
              ?.map((json) => NoteModelImplementation.fromDocumentSnapshot(
                  documentSnapshot: documentSnapshot, tripId: tripId))
              .toList() ??
          [],
      checkLists: (data[_checkListsField] as List<dynamic>?)
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
      _sightsField: sights.isEmpty
          ? null
          : sights
              .map((sight) => (sight as SightModelImplementation).toJson())
              .toList(),
      _notesField: notes.isEmpty
          ? null
          : notes
              .map((note) => (note as NoteModelImplementation).toJson())
              .toList(),
      _checkListsField: checkLists.isEmpty
          ? null
          : checkLists
              .map((checkList) =>
                  (checkList as CheckListModelImplementation).toJson())
              .toList(),
    };
  }

  @override
  ItineraryPlanData get facade => this;
}
