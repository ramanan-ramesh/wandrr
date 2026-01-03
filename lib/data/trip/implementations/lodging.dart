import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/lodging.dart';

/// Repository implementation for Lodging model.
/// Wraps Lodging model with Firestore-specific serialization.
// ignore: must_be_immutable
class LodgingRepositoryItem implements LeafRepositoryItem<Lodging> {
  final Lodging _lodging;

  @override
  String? id;

  LodgingRepositoryItem.fromModel(Lodging lodging)
      : _lodging = lodging,
        id = lodging.id;

  /// Factory constructor for creating from a model facade
  factory LodgingRepositoryItem.fromModelFacade({
    required Lodging lodgingModelFacade,
  }) {
    return LodgingRepositoryItem.fromModel(lodgingModelFacade);
  }

  static LodgingRepositoryItem fromDocumentSnapshot({
    required String tripId,
    required DocumentSnapshot documentSnapshot,
  }) {
    final documentData = documentSnapshot.data() as Map<String, dynamic>;
    final lodging = LodgingFirestoreConverter.fromFirestore(
      documentData,
      tripId,
      documentSnapshot.id,
    );
    return LodgingRepositoryItem.fromModel(lodging);
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(_lodging.tripId)
      .collection(FirestoreCollections.lodgingCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() =>
      LodgingFirestoreConverter.toFirestore(_lodging);

  @override
  Lodging get facade {
    if (id != null) {
      return _lodging.copyWith(id: id!);
    }
    return _lodging;
  }
}

// Legacy alias for backward compatibility
typedef LodgingModelImplementation = LodgingRepositoryItem;
