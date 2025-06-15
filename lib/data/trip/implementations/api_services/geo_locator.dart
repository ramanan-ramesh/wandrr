import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:wandrr/data/trip/models/api_services/geo_locator.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'constants.dart';

class GeoLocator implements GeoLocatorService {
  static const _apiSurfaceUrl = 'https://api.locationiq.com/v1/autocomplete?';
  static const _typeField = 'type';
  static const _apiKeyField = 'key';
  static const _apiServiceIdentifier = 'geoLocator';
  final String _apiKey;
  static const _latitudeField = 'lat';
  static const _longitudeField = 'lon';
  String lastExecutedQuery = '';
  List<LocationFacade> _lastQueriedLocations = [];

  static Future<GeoLocator> create() async {
    var locationAPIDocumentQueryResult = await FirebaseFirestore.instance
        .collection(Constants.apiServicesCollectionName)
        .where(_typeField, isEqualTo: _apiServiceIdentifier)
        .get();
    var locationAPIDocument = locationAPIDocumentQueryResult.docs.first;
    return GeoLocator._(apiKey: locationAPIDocument[_apiKeyField]);
  }

  @override
  Future<List<LocationFacade>> performQuery(String query) async {
    if (lastExecutedQuery != query && query.length >= 2) {
      var queryUrl = _constructQuery(query);
      try {
        var queryResponse = await http.get(Uri.parse(queryUrl));
        if (queryResponse.statusCode == 200) {
          lastExecutedQuery = query;
          var locations = _convertResponse(queryResponse.body);
          _lastQueriedLocations = locations;
          return _lastQueriedLocations;
        }
      } finally {}
    }
    return _lastQueriedLocations;
  }

  String _constructQuery(String query) =>
      '${_apiSurfaceUrl}key=$_apiKey&q=$query';

  static List<LocationFacade> _convertResponse(String response) {
    List decodedResponse = json.decode(response);
    return decodedResponse.map((e) => convertJsonToLocation(e)).toList();
  }

  static LocationFacade convertJsonToLocation(
      Map<String, dynamic> locationJson) {
    return LocationFacade(
        latitude: double.parse(locationJson[_latitudeField].toString()),
        longitude: double.parse(locationJson[_longitudeField].toString()),
        context: GeoLocationApiContext.fromApi(locationJson),
        tripId: '');
  }

  GeoLocator._({required String apiKey}) : _apiKey = apiKey;
}
