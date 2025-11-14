import 'package:equatable/equatable.dart';

import 'bounding_box.dart';
import 'location.dart';
import 'location_context.dart';

class GeoLocationApiContext with EquatableMixin implements LocationContext {
  static const _classField = 'class';
  static const _typeField = 'type';
  static const _displayAddress = 'display_address';
  static const String _contintent = 'continent';
  static const String _country = 'country';
  static const String _state = 'state';
  static const String _city = 'city';
  static const String _town = 'town';
  static const String _hamlet = 'hamlet';
  static const String _village = 'village';
  static const String _station = 'station';
  static const String _railway = 'railway';
  static const String _restaurant = 'restaurant';
  static const String _fastFood = 'fast_food';
  static const String _hostel = 'hostel';
  static const String _busStop = 'bus_stop';
  static const String _busStation = 'bus_station';
  static const String _address = 'address';
  static const String _county = 'county';
  static const String _aerodrome = 'aerodrome';
  static const String _administrative = 'administrative';
  static const String _boundary = 'boundary';
  static const String _name = 'name';
  static const String _tourism = 'tourism';
  static const String _attraction = 'attraction';
  static const String _apartments = 'apartments';
  static const String _residential = 'residential';
  static const String _hotel = 'hotel';
  static const _locationTypeField = 'locationType';

  final String _nodeClass;
  final String _nodeType;

  @override
  final LocationType locationType;

  final String? country;

  @override
  final String? city;

  final String? state;

  @override
  final String name;

  final String? address;

  final String placeId;
  static const String _placeIdField = 'place_id';

  final BoundingBox boundingBox;
  static const String _boundingBoxField = 'boundingbox';

  static GeoLocationApiContext fromApi(Map<String, dynamic> locationJson) {
    var boundingBoxValue = locationJson[_boundingBoxField] as List;
    var boundingBox = BoundingBox(
        maxLat: double.parse(boundingBoxValue[1].toString()),
        minLat: double.parse(boundingBoxValue[0].toString()),
        maxLon: double.parse(boundingBoxValue[3].toString()),
        minLon: double.parse(boundingBoxValue[2].toString()));
    String locationClass = locationJson[_classField];
    String locationType = locationJson[_typeField];
    if (locationType == _contintent) {
      return GeoLocationApiContext._fromApi(
          name: locationJson[_address][_name],
          locationType: LocationType.continent,
          nodeClass: locationClass,
          nodeType: locationType,
          placeId: locationJson[_placeIdField],
          boundingBox: boundingBox,
          address: locationJson[_displayAddress]);
    } else if (locationType == _country) {
      return GeoLocationApiContext._fromApi(
          name: locationJson[_address][_country],
          locationType: LocationType.country,
          nodeClass: locationClass,
          boundingBox: boundingBox,
          placeId: locationJson[_placeIdField],
          nodeType: locationType,
          address: locationJson[_displayAddress]);
    } else if (locationType == _state) {
      var state = locationJson[_address][_name];
      var country = locationJson[_address][_country];
      return GeoLocationApiContext._fromApi(
          country: country,
          name: state,
          locationType: LocationType.state,
          placeId: locationJson[_placeIdField],
          nodeClass: locationClass,
          boundingBox: boundingBox,
          nodeType: locationType,
          address: locationJson[_displayAddress]);
    } else if (locationType == _city ||
        locationType == _town ||
        locationType == _village ||
        locationType == _hamlet) {
      var city = locationJson[_address][_name];
      var state = locationJson[_address][_state];
      var country = locationJson[_address][_country];
      return GeoLocationApiContext._fromApi(
          country: country,
          state: state,
          name: city,
          placeId: locationJson[_placeIdField],
          boundingBox: boundingBox,
          locationType: LocationType.city,
          nodeClass: locationClass,
          nodeType: locationType,
          city: city,
          address: locationJson[_displayAddress]);
    } else if (locationType == _station) {
      if (locationClass == _railway) {
        return _createGenericPlaceFromApi(
            LocationType.railwayStation, locationJson);
      }
    } else if (locationType == _busStation) {
      return _createGenericPlaceFromApi(LocationType.busStation, locationJson);
    } else if (locationType == _restaurant ||
        locationType == _fastFood ||
        locationType == _hotel) {
      return _createGenericPlaceFromApi(LocationType.restaurant, locationJson);
    } else if (locationType == _hostel ||
        locationType == _apartments ||
        locationType == _residential) {
      return _createGenericPlaceFromApi(LocationType.lodging, locationJson);
    } else if (locationType == _aerodrome) {
      return _createGenericPlaceFromApi(LocationType.airport, locationJson);
    } else if (locationType == _administrative) {
      if (locationClass == _boundary) {
        return _createGenericPlaceFromApi(LocationType.region, locationJson);
      }
    } else if (locationType == _busStop) {
      return _createGenericPlaceFromApi(LocationType.busStop, locationJson);
    } else if (locationType == _tourism) {
      if (locationClass == _attraction) {
        return _createGenericPlaceFromApi(
            LocationType.attraction, locationJson);
      }
    }
    return _createGenericPlaceFromApi(LocationType.place, locationJson);
  }

  @override
  GeoLocationApiContext clone() => GeoLocationApiContext._fromApi(
      locationType: locationType,
      nodeClass: _nodeClass,
      boundingBox: boundingBox.clone(),
      placeId: placeId,
      nodeType: _nodeType,
      name: name,
      address: address);

  static GeoLocationApiContext _createGenericPlaceFromApi(
      LocationType locationType, Map<String, dynamic> locationJson) {
    var boundingBoxValue = locationJson[_boundingBoxField] as List;
    var boundingBox = BoundingBox(
        maxLat: double.parse(boundingBoxValue[1].toString()),
        minLat: double.parse(boundingBoxValue[0].toString()),
        maxLon: double.parse(boundingBoxValue[3].toString()),
        minLon: double.parse(boundingBoxValue[2].toString()));
    var city = locationJson[_address][_city] ?? locationJson[_address][_county];
    var state = locationJson[_address][_state];
    var country = locationJson[_address][_country];
    var name = locationJson[_address][_name];
    return GeoLocationApiContext._fromApi(
        nodeClass: locationJson[_classField],
        nodeType: locationJson[_typeField],
        placeId: locationJson[_placeIdField],
        boundingBox: boundingBox,
        locationType: locationType,
        city: city,
        state: state,
        country: country,
        name: name,
        address: locationJson[_displayAddress]);
  }

  static GeoLocationApiContext fromDocument(Map<String, dynamic> json) =>
      GeoLocationApiContext._fromDocument(
          placeId: json[_placeIdField],
          address: json[_address],
          locationType: json[_locationTypeField],
          nodeClass: json[_classField],
          nodeType: json[_typeField],
          name: json[_name],
          country: json[_country],
          boundingBox: BoundingBox.fromDocument(json[_boundingBoxField]),
          city: json[_city],
          state: json[_state]);

  @override
  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    json[_typeField] = _nodeType;
    json[_locationTypeField] = locationType.name;
    json[_classField] = _nodeClass;
    json[_name] = name;
    json[_address] = address;
    json[_boundingBoxField] = boundingBox.toJson();
    json[_placeIdField] = placeId;
    if (state != null) {
      json[_state] = state;
    }
    if (country != null) {
      json[_country] = country;
    }
    if (city != null) {
      json[_city] = city;
    }
    return json;
  }

  GeoLocationApiContext._fromApi({
    required this.locationType,
    required String nodeClass,
    required this.placeId,
    required String nodeType,
    required this.boundingBox,
    required this.name,
    required this.address,
    this.country,
    this.city,
    this.state,
  })  : _nodeType = nodeType,
        _nodeClass = nodeClass;

  GeoLocationApiContext._fromDocument({
    required String locationType,
    required String nodeClass,
    required String nodeType,
    required this.boundingBox,
    required this.name,
    required this.address,
    required this.placeId,
    this.country,
    this.city,
    this.state,
  })  : _nodeType = nodeType,
        _nodeClass = nodeClass,
        locationType = LocationType.values
            .firstWhere((element) => element.name == locationType);

  @override
  List<Object?> get props => [
        _nodeClass,
        _nodeType,
        locationType,
        country,
        city,
        state,
        name,
        address,
        placeId,
        boundingBox
      ];
}
