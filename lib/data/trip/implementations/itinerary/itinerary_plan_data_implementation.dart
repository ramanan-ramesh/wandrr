import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/check_list.dart';
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
      if (sights.isNotEmpty)
        _sightsField: sights
            .map((sight) => (sight as SightModelImplementation).toJson())
            .toList(),
      if (notes.isNotEmpty) _notesField: notes,
      if (checkLists.isNotEmpty)
        _checkListsField: checkLists
            .map((checkList) =>
                (checkList as CheckListModelImplementation).toJson())
            .toList(),
    };
  }

  @override
  ItineraryPlanData get facade => this;
}
