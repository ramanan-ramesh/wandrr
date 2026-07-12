import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_document.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/location/location_context.dart';
import 'package:wandrr/data/trip/models/location/timezone_resolver.dart';

// ignore: must_be_immutable
class LocationModelImplementation extends LocationFacade
    implements CollectionItem<LocationFacade> {
  static const String _contextField = 'context';
  static const String _latitudeLongitudeField = 'latLon';
  static const String _timezoneIdField = 'timezoneId';

  /// Resolves and persists a timezone id the first time a location is turned
  /// into a repository item, so subsequent reads never need to re-infer it
  /// from coordinates. Locations that already carry a resolved id (e.g.
  /// cloned from another persisted location) keep it unchanged.
  LocationModelImplementation.fromModelFacade(
      {required LocationFacade locationModelFacade, String? parentId})
      : super(
            latitude: locationModelFacade.latitude,
            longitude: locationModelFacade.longitude,
            context: locationModelFacade.context,
            id: locationModelFacade.id,
            timezoneId:
                TimezoneResolver.resolveTimezoneId(locationModelFacade));

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
        timezoneId: json[_timezoneIdField] as String?,
        parentId: parentId,
        collectionName: collectionName);
  }

  @override
  Map<String, dynamic> toJson() {
    var geoPoint = GeoPoint(latitude, longitude);
    return {
      _latitudeLongitudeField: geoPoint,
      _contextField: context.toJson(),
      if (timezoneId != null) _timezoneIdField: timezoneId,
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
        context: locationContext,
        timezoneId: json[_timezoneIdField] as String?);
  }

  @override
  LocationFacade get facade => clone();

  LocationModelImplementation._(
      {required super.latitude,
      required super.longitude,
      required super.context,
      super.id,
      super.timezoneId,
      String? collectionName,
      String? parentId});
}
