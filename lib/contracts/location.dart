import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/trip_data.dart';

class LocationModelFacade extends Equatable implements TripEntity {
  String tripId;
  double latitude;

  double longitude;

  LocationContext context;

  @override
  String? id;

  LocationModelFacade(
      {required this.latitude,
      required this.longitude,
      required this.context,
      required this.tripId,
      this.id});

  void copyWith(LocationModelFacade locationModelFacade) {
    latitude = locationModelFacade.latitude;
    longitude = locationModelFacade.longitude;
    context = locationModelFacade.context.clone();
    id = locationModelFacade.id;
  }

  LocationModelFacade clone() {
    return LocationModelFacade(
        latitude: latitude,
        longitude: longitude,
        context: context,
        tripId: tripId,
        id: id);
  }

  @override
  String toString() {
    if (context is AirportLocationContext) {
      return context.city!;
    }
    return context.name;
  }

  @override
  List<Object?> get props => [tripId, id, latitude, longitude, context, id];
}

class BoundingBox extends Equatable {
  static const _maxLatField = 'maxLat';
  static const _minLatField = 'minLat';
  static const _maxLonField = 'maxLon';
  static const _minLonField = 'minLon';
  final double maxLat, minLat;
  final double maxLon, minLon;

  BoundingBox(
      {required this.maxLat,
      required this.minLat,
      required this.maxLon,
      required this.minLon});

  BoundingBox clone() {
    return BoundingBox(
        maxLat: maxLat, minLat: minLat, maxLon: maxLon, minLon: minLon);
  }

  static BoundingBox fromDocument(Map<String, dynamic> json) {
    return BoundingBox(
        maxLat: double.parse(json[_maxLatField].toString()),
        minLat: double.parse(json[_minLatField].toString()),
        maxLon: double.parse(json[_maxLonField].toString()),
        minLon: double.parse(json[_minLonField].toString()));
  }

  Map<String, dynamic> toJson() {
    return {
      _maxLatField: maxLat,
      _maxLonField: maxLon,
      _minLonField: minLon,
      _minLatField: minLat
    };
  }

  @override
  List<Object?> get props => [maxLat, minLat, maxLon, minLon];
}

abstract class LocationContext {
  LocationType get locationType;

  String? get city;

  String get name;

  Map<String, dynamic> toJson();

  LocationContext clone();

  static LocationContext createInstance({required Map<String, dynamic> json}) {
    if (json['type'] == 'Airport') {
      return AirportLocationContext.fromDocument(json);
    }

    return GeoLocationApiContext.fromDocument(json);
  }
}

class AirportLocationContext with EquatableMixin implements LocationContext {
  @override
  final LocationType locationType = LocationType.Airport;
  static const _locationTypeField = 'type';

  @override
  final String city;
  static const _cityField = 'city';

  @override
  final String name;
  static const _nameField = 'name';

  final String airportCode;
  static const _iataAirportCodeField = 'iata';
  static const _icaoAirportCodeField = 'icao';
  static const _airportCodeField = 'code';

  AirportLocationContext._(
      {required this.city,
      required this.airportCode,
      required String airportName})
      : name = airportName;

  AirportLocationContext.fromApi(Map<String, dynamic> json)
      : this._(
            city: json[_cityField],
            airportCode: json[_iataAirportCodeField] != null
                ? ((json[_iataAirportCodeField] as String).isNotEmpty
                    ? json[_iataAirportCodeField]
                    : json[_icaoAirportCodeField])
                : json[_icaoAirportCodeField],
            airportName: json[_nameField]);

  AirportLocationContext.fromDocument(Map<String, dynamic> json)
      : this._(
            city: json[_cityField],
            airportCode: json[_airportCodeField],
            airportName: json[_nameField]);

  @override
  Map<String, dynamic> toJson() {
    return {
      _nameField: name,
      _cityField: city,
      _airportCodeField: airportCode,
      _locationTypeField: locationType.name
    };
  }

  @override
  LocationContext clone() {
    return AirportLocationContext._(
        city: city, airportCode: airportCode, airportName: name);
  }

  @override
  List<Object?> get props => [locationType, city, name, airportCode];
}

class GeoLocationApiContext with EquatableMixin implements LocationContext {
  static const classField = 'class';
  static const typeField = 'type';
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
  final LocationType locationType; // This

  final String? country;

  @override
  final String? city; // This

  final String? state;

  @override
  final String name; // This

  final String? address;

  final String placeId;
  static const String _placeIdField = 'place_id';

  @override
  final BoundingBox boundingBox;
  static const String _boundingBoxField = 'boundingbox';

  static GeoLocationApiContext fromApi(Map<String, dynamic> locationJson) {
    var boundingBoxValue = locationJson[_boundingBoxField] as List;
    var boundingBox = BoundingBox(
        maxLat: double.parse(boundingBoxValue[1].toString()),
        minLat: double.parse(boundingBoxValue[0].toString()),
        maxLon: double.parse(boundingBoxValue[3].toString()),
        minLon: double.parse(boundingBoxValue[2].toString()));
    String locationClass = locationJson[classField];
    String locationType = locationJson[typeField];
    if (locationType == _contintent) {
      return GeoLocationApiContext._fromApi(
          name: locationJson[_address][_name],
          locationType: LocationType.Continent,
          nodeClass: locationClass,
          nodeType: locationType,
          placeId: locationJson[_placeIdField],
          boundingBox: boundingBox,
          address: locationJson[_displayAddress]);
    } else if (locationType == _country) {
      return GeoLocationApiContext._fromApi(
          name: locationJson[_address][_country],
          locationType: LocationType.Country,
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
          locationType: LocationType.State,
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
          locationType: LocationType.City,
          nodeClass: locationClass,
          nodeType: locationType,
          address: locationJson[_displayAddress]);
    } else if (locationType == _station) {
      if (locationClass == _railway) {
        return _createGenericPlaceFromApi(
            LocationType.RailwayStation, locationJson);
      }
    } else if (locationType == _busStation) {
      return _createGenericPlaceFromApi(LocationType.BusStation, locationJson);
    } else if (locationType == _restaurant ||
        locationType == _fastFood ||
        locationType == _hotel) {
      return _createGenericPlaceFromApi(LocationType.Restaurant, locationJson);
    } else if (locationType == _hostel ||
        locationType == _apartments ||
        locationType == _residential) {
      return _createGenericPlaceFromApi(LocationType.Lodging, locationJson);
    } else if (locationType == _aerodrome) {
      return _createGenericPlaceFromApi(LocationType.Airport, locationJson);
    } else if (locationType == _administrative) {
      if (locationClass == _boundary) {
        return _createGenericPlaceFromApi(LocationType.Region, locationJson);
      }
    } else if (locationType == _busStop) {
      return _createGenericPlaceFromApi(LocationType.BusStop, locationJson);
    } else if (locationType == _tourism) {
      if (locationClass == _attraction) {
        return _createGenericPlaceFromApi(
            LocationType.Attraction, locationJson);
      }
    }
    return _createGenericPlaceFromApi(LocationType.Place, locationJson);
  }

  @override
  GeoLocationApiContext clone() {
    return GeoLocationApiContext._fromApi(
        locationType: locationType,
        nodeClass: _nodeClass,
        boundingBox: boundingBox.clone(),
        placeId: placeId,
        nodeType: _nodeType,
        name: name,
        address: address);
  }

  static GeoLocationApiContext _createGenericPlaceFromApi(
      LocationType locationType, Map<String, dynamic> locationJson) {
    var boundingBoxValue = locationJson[_boundingBoxField] as List;
    var boundingBox = BoundingBox(
        maxLat: double.parse(boundingBoxValue[1].toString()),
        minLat: double.parse(boundingBoxValue[0].toString()),
        maxLon: double.parse(boundingBoxValue[3].toString()),
        minLon: double.parse(boundingBoxValue[2].toString()));
    var city = locationJson[_address][_city];
    var state = locationJson[_address][_state];
    var country = locationJson[_address][_country];
    var name = locationJson[_address][_name];
    return GeoLocationApiContext._fromApi(
        nodeClass: locationJson[classField],
        nodeType: locationJson[typeField],
        placeId: locationJson[_placeIdField],
        boundingBox: boundingBox,
        locationType: locationType,
        city: city,
        state: state,
        country: country,
        name: name,
        address: locationJson[_displayAddress]);
  }

  static GeoLocationApiContext fromDocument(Map<String, dynamic> json) {
    return GeoLocationApiContext._fromDocument(
        placeId: json[_placeIdField],
        address: json[_address],
        locationType: json[_locationTypeField],
        nodeClass: json[classField],
        nodeType: json[typeField],
        name: json[_name],
        country: json[_country],
        boundingBox: BoundingBox.fromDocument(json[_boundingBoxField]),
        city: json[_city],
        state: json[_state]);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json[typeField] = _nodeType;
    json[_locationTypeField] = locationType.name;
    json[classField] = _nodeClass;
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
        _city,
        _name,
        _country,
        _state,
        _nodeClass,
        _nodeType,
        locationType,
        boundingBox,
        placeId
      ];
}

enum LocationType {
  Continent,
  Country,
  State,
  City,
  Place,
  Region,
  RailwayStation,
  Airport,
  BusStation,
  Restaurant,
  Attraction,
  Lodging,
  BusStop
}
