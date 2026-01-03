import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Repository implementation for TripMetadata model.
/// Wraps TripMetadata model with Firestore-specific serialization.
// ignore: must_be_immutable
class TripMetadataRepositoryItem implements LeafRepositoryItem<TripMetadata> {
  TripMetadata _tripMetadata;

  @override
  String? id;

  // Expose properties for backward compatibility
  String get name => _tripMetadata.name;

  String get thumbnailTag => _tripMetadata.thumbnailTag;

  List<String> get contributors => _tripMetadata.contributors;

  Money get budget => _tripMetadata.budget;

  DateTime? get startDate => _tripMetadata.startDate;

  DateTime? get endDate => _tripMetadata.endDate;

  TripMetadataRepositoryItem.fromModel(TripMetadata tripMetadata)
      : _tripMetadata = tripMetadata,
        id = tripMetadata.id;

  /// Factory constructor for creating from a model facade
  factory TripMetadataRepositoryItem.fromModelFacade({
    required TripMetadata tripMetadataModelFacade,
  }) {
    return TripMetadataRepositoryItem.fromModel(tripMetadataModelFacade);
  }

  static TripMetadataRepositoryItem fromDocumentSnapshot(
    DocumentSnapshot documentSnapshot,
  ) {
    final tripMetadata =
        TripMetadataFirestoreConverter.fromFirestore(documentSnapshot);
    return TripMetadataRepositoryItem.fromModel(tripMetadata);
  }

  @override
  DocumentReference get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripMetadataCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() =>
      TripMetadataFirestoreConverter.toFirestore(_tripMetadata);

  @override
  TripMetadata get facade {
    if (id != null) {
      return _tripMetadata.copyWith(id: id!);
    }
    return _tripMetadata;
  }

  /// Clone the underlying model
  TripMetadata clone() => _tripMetadata.copyWith();

  /// Update the internal model with new values using copyWith
  void updateFrom(TripMetadata tripMetadata) {
    _tripMetadata = tripMetadata;
    id = tripMetadata.id;
  }
}

// Legacy alias for backward compatibility
typedef TripMetadataModelImplementation = TripMetadataRepositoryItem;
