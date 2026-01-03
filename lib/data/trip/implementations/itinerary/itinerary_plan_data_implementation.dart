import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';

/// Extension for DateTime formatting
extension _DateExt on DateTime {
  String get itineraryDateFormat => '$day$month$year';
}

/// Repository implementation for ItineraryPlanData model.
/// Wraps ItineraryPlanData model with Firestore-specific serialization.
// ignore: must_be_immutable
class ItineraryPlanDataRepositoryItem
    implements LeafRepositoryItem<ItineraryPlanData> {
  final ItineraryPlanData _planData;

  @override
  String? id;

  ItineraryPlanDataRepositoryItem.fromModel(ItineraryPlanData planData)
      : _planData = planData,
        id = planData.id;

  /// Factory constructor for creating from a model facade
  factory ItineraryPlanDataRepositoryItem.fromModelFacade(
    ItineraryPlanData planDataFacade,
  ) {
    return ItineraryPlanDataRepositoryItem.fromModel(planDataFacade);
  }

  factory ItineraryPlanDataRepositoryItem.fromDocumentSnapshot({
    required String tripId,
    required DocumentSnapshot documentSnapshot,
    required DateTime day,
  }) {
    final planData = ItineraryPlanDataFirestoreConverter.fromFirestore(
      documentSnapshot,
      tripId,
      day,
    );
    return ItineraryPlanDataRepositoryItem.fromModel(planData);
  }

  /// Creates an empty plan data for a given day
  factory ItineraryPlanDataRepositoryItem.empty({
    required String tripId,
    required DateTime day,
  }) {
    return ItineraryPlanDataRepositoryItem.fromModel(
      ItineraryPlanData.newEntry(tripId: tripId, day: day),
    );
  }

  @override
  DocumentReference<Map<String, dynamic>> get documentReference =>
      FirebaseFirestore.instance
          .collection(FirestoreCollections.tripCollectionName)
          .doc(_planData.tripId)
          .collection(FirestoreCollections.itineraryDataCollectionName)
          .doc(id ?? _planData.day.itineraryDateFormat);

  @override
  Map<String, dynamic> toJson() =>
      ItineraryPlanDataFirestoreConverter.toFirestore(_planData);

  @override
  ItineraryPlanData get facade => _planData.copyWith(id: id);
}

// Legacy alias for backward compatibility
typedef ItineraryPlanDataModelImplementation = ItineraryPlanDataRepositoryItem;
