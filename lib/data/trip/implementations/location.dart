import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/location/location_context.dart';

// ignore: must_be_immutable
class LocationModelImplementation extends LocationFacade
    implements LeafRepositoryItem<LocationFacade> {
  static const String _contextField = 'context';
  static const String _latitudeLongitudeField = 'latLon';

  LocationModelImplementation.fromModelFacade(
      {required LocationFacade locationModelFacade, String? parentId})
      : super(
            latitude: locationModelFacade.latitude,
            longitude: locationModelFacade.longitude,
            context: locationModelFacade.context,
            id: locationModelFacade.id);

  static LocationModelImplementation fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot,
      String? parentId,
      String? collectionName}) {
    var json = documentSnapshot.data() as Map<String, dynamic>;
    var geoPoint = json[_latitudeLongitudeField] as GeoPoint;
    var locationContext =
        LocationContext.createInstance(json: json[_contextField]);
    return LocationModelImplementation._(
        latitude: geoPoint.latitude,
        longitude: geoPoint.longitude,
        id: documentSnapshot.id,
        context: locationContext,
        parentId: parentId,
        collectionName: collectionName);
  }

  @override
  Map<String, dynamic> toJson() {
    var geoPoint = GeoPoint(latitude, longitude);
    return {
      _latitudeLongitudeField: geoPoint,
      _contextField: context.toJson(),
    };
  }

  static LocationModelImplementation fromJson(
      {required Map<String, dynamic> json}) {
    var geoPoint = json[_latitudeLongitudeField] as GeoPoint;
    var locationContext =
        LocationContext.createInstance(json: json[_contextField]);
    return LocationModelImplementation._(
        latitude: geoPoint.latitude,
        longitude: geoPoint.longitude,
        context: locationContext);
  }

  @override
  LocationFacade get facade => clone();

  LocationModelImplementation._(
      {required super.latitude,
      required super.longitude,
      required super.context,
      super.id,
      String? collectionName,
      String? parentId});
}
