import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/app/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

class LocationModelImplementation extends LocationFacade
    implements LeafRepositoryItem<LocationFacade> {
  static const String _contextField = 'context';
  static const String _latitudeLongitudeField = 'latLon';

  final String _collectionName;
  final String _parentId;

  LocationModelImplementation.fromModelFacade(
      {required LocationFacade locationModelFacade,
      String? collectionName,
      String? parentId})
      : _parentId = parentId ?? '',
        _collectionName =
            collectionName ?? FirestoreCollections.planDataCollectionName,
        super(
            latitude: locationModelFacade.latitude,
            longitude: locationModelFacade.longitude,
            context: locationModelFacade.context,
            id: locationModelFacade.id,
            tripId: locationModelFacade.tripId);

  LocationModelImplementation(
      {required super.latitude,
      required super.longitude,
      required super.context,
      super.id,
      required super.tripId,
      String? collectionName,
      String? parentId})
      : _parentId = parentId ?? '',
        _collectionName =
            collectionName ?? FirestoreCollections.planDataCollectionName;

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(_collectionName)
      .doc(_parentId)
      .collection(FirestoreCollections.placeCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() {
    var geoPoint = GeoPoint(latitude, longitude);
    return {
      _latitudeLongitudeField: geoPoint,
      _contextField: context.toJson(),
    };
  }

  static LocationModelImplementation fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot,
      required String tripId,
      String? parentId,
      String? collectionName}) {
    var json = documentSnapshot.data() as Map<String, dynamic>;
    var geoPoint = json[_latitudeLongitudeField] as GeoPoint;
    var locationContext =
        LocationContext.createInstance(json: json[_contextField]);
    return LocationModelImplementation(
        latitude: geoPoint.latitude,
        longitude: geoPoint.longitude,
        tripId: tripId,
        id: documentSnapshot.id,
        context: locationContext,
        parentId: parentId,
        collectionName: collectionName);
  }

  static LocationModelImplementation fromJson(
      {required Map<String, dynamic> json, required String tripId}) {
    var geoPoint = json[_latitudeLongitudeField] as GeoPoint;
    var locationContext =
        LocationContext.createInstance(json: json[_contextField]);
    return LocationModelImplementation(
        latitude: geoPoint.latitude,
        longitude: geoPoint.longitude,
        tripId: tripId,
        context: locationContext);
  }

  @override
  Future<bool> tryUpdate(LocationFacade toUpdate) async {
    return true;
  }

  @override
  LocationFacade get facade => clone();
}
