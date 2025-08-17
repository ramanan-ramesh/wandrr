import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'constants.dart';

class GeoLocator implements ApiService<String, Iterable<LocationFacade>> {
  static const _apiSurfaceUrl = 'https://api.locationiq.com/v1/autocomplete?';
  static const _typeField = 'type';
  static const _apiKeyField = 'key';
  static const _apiIdentifier = 'geoLocator';
  static const _latitudeField = 'lat';
  static const _longitudeField = 'lon';

  late String _apiKey;
  String _lastExecutedQuery = '';
  List<LocationFacade> _lastQueriedLocations = [];

  GeoLocator() : apiIdentifier = _apiIdentifier;

  @override
  final String apiIdentifier;

  @override
  Future<void> initialize() async {
    var locationAPIDocumentQueryResult = await FirebaseFirestore.instance
        .collection(Constants.apiServicesCollectionName)
        .where(_typeField, isEqualTo: _apiIdentifier)
        .get();
    var locationAPIDocument = locationAPIDocumentQueryResult.docs.first;
    _apiKey = locationAPIDocument[_apiKeyField] as String;
  }

  @override
  Future<Iterable<LocationFacade>> queryData(String query) async {
    if (_lastExecutedQuery != query && query.length >= 2) {
      var queryUrl = _constructQuery(query);
      try {
        var queryResponse = await http.get(Uri.parse(queryUrl));
        if (queryResponse.statusCode == 200) {
          _lastExecutedQuery = query;
          var locations = _convertResponse(queryResponse.body);
          return _lastQueriedLocations = locations;
        }
      } finally {}
    }
    return _lastQueriedLocations;
  }

  String _constructQuery(String query) =>
      '${_apiSurfaceUrl}key=$_apiKey&q=$query';

  static List<LocationFacade> _convertResponse(String response) {
    List decodedResponse = json.decode(response);
    return decodedResponse
        .map(
          (locationJson) => LocationFacade(
              latitude: double.parse(locationJson[_latitudeField].toString()),
              longitude: double.parse(locationJson[_longitudeField].toString()),
              context: GeoLocationApiContext.fromApi(locationJson),
              tripId: ''),
        )
        .toList();
  }

  @override
  FutureOr<void> dispose() {
    _lastExecutedQuery = '';
    _lastQueriedLocations.clear();
  }
}
