import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';

/// Repository implementation for Sight model.
/// Wraps Sight model with Firestore-specific serialization.
// ignore: must_be_immutable
class SightRepositoryItem implements LeafRepositoryItem<Sight> {
  final Sight _sight;

  @override
  String? id;

  SightRepositoryItem.fromModel(Sight sight)
      : _sight = sight,
        id = sight.id;

  static SightRepositoryItem fromJson(
    Map<String, dynamic> json,
    DateTime day,
    String tripId, {
    String? id,
  }) {
    final sight =
        SightFirestoreConverter.fromFirestore(json, day, tripId, id: id ?? '');
    return SightRepositoryItem.fromModel(sight);
  }

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError('Sight is embedded in ItineraryPlanData');

  @override
  Map<String, dynamic> toJson() => SightFirestoreConverter.toFirestore(_sight);

  @override
  Sight get facade {
    if (id != null) {
      return _sight.copyWith(id: id!);
    }
    return _sight;
  }
}

// Legacy alias for backward compatibility
typedef SightModelImplementation = SightRepositoryItem;
