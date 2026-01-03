import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

/// Repository implementation for Location model.
/// Wraps Location model with Firestore-specific serialization.
// ignore: must_be_immutable
class LocationRepositoryItem implements LeafRepositoryItem<Location> {
  final Location _location;

  @override
  String? id;

  LocationRepositoryItem.fromModel(Location location)
      : _location = location,
        id = location.id;

  static LocationRepositoryItem fromDocumentSnapshot({
    required DocumentSnapshot documentSnapshot,
  }) {
    final json = documentSnapshot.data() as Map<String, dynamic>;
    final location = LocationFirestoreConverter.fromFirestore(
      json,
      id: documentSnapshot.id,
    );
    return LocationRepositoryItem.fromModel(location);
  }

  /// Creates from JSON (for embedded locations in transit/lodging)
  static LocationRepositoryItem fromJson({
    required Map<String, dynamic> json,
  }) {
    final location = LocationFirestoreConverter.fromFirestore(json);
    return LocationRepositoryItem.fromModel(location);
  }

  @override
  DocumentReference<Object?> get documentReference => throw UnimplementedError(
      'Location does not have a standalone document reference');

  @override
  Map<String, dynamic> toJson() =>
      LocationFirestoreConverter.toFirestore(_location);

  @override
  Location get facade => _location.copyWith(id: id);
}

// Legacy alias for backward compatibility
typedef LocationModelImplementation = LocationRepositoryItem;
