import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Repository implementation for Transit model.
/// Wraps Transit model with Firestore-specific serialization.
// ignore: must_be_immutable
class TransitRepositoryItem implements LeafRepositoryItem<Transit> {
  final Transit _transit;

  @override
  String? id;

  TransitRepositoryItem.fromModel(Transit transit)
      : _transit = transit,
        id = transit.id;

  /// Factory constructor for creating from a model facade
  factory TransitRepositoryItem.fromModelFacade({
    required Transit transitModelFacade,
  }) {
    return TransitRepositoryItem.fromModel(transitModelFacade);
  }

  static TransitRepositoryItem fromDocumentSnapshot(
    String tripId,
    DocumentSnapshot documentSnapshot,
  ) {
    final documentData = documentSnapshot.data() as Map<String, dynamic>;
    final transit = TransitFirestoreConverter.fromFirestore(
      documentData,
      tripId,
      documentSnapshot.id,
    );
    return TransitRepositoryItem.fromModel(transit);
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(_transit.tripId)
      .collection(FirestoreCollections.transitCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() =>
      TransitFirestoreConverter.toFirestore(_transit);

  @override
  Transit get facade {
    if (id != null) {
      return _transit.copyWith(id: id!);
    }
    return _transit;
  }
}

// Legacy alias for backward compatibility
typedef TransitImplementation = TransitRepositoryItem;
