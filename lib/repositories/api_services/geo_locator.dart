import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:wandrr/contracts/api_service.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/trip_entity_facades/location.dart';

class GeoLocator implements MultiOptionsAPIService<LocationFacade> {
  static const _apiSurfaceUrl = 'https://api.locationiq.com/v1/autocomplete?';
  static const _typeField = 'type';
  static const _apiKeyField = 'key';
  static const _apiServiceIdentifier = 'geoLocator';
  final String _apiKey;
  static bool _shouldAllowQuery = true;
  static const _latitudeField = 'lat';
  static const _longitudeField = 'lon';
  String lastQuery = '';
  List<LocationFacade> _lastQueriedLocations = [];

  static Future<GeoLocator> create() async {
    var locationAPIDocumentQueryResult = await FirebaseFirestore.instance
        .collection(FirestoreCollections.apiServicesCollection)
        .where(_typeField, isEqualTo: _apiServiceIdentifier)
        .get();
    var locationAPIDocument = locationAPIDocumentQueryResult.docs.first;
    return GeoLocator._(apiKey: locationAPIDocument[_apiKeyField]);
  }

  Future<List<LocationFacade>> performQuery(Object query) async {
    if (query is String && query.length >= 2 && _shouldAllowQuery) {
      var queryUrl = _constructQuery(query);
      try {
        var queryResponse = await http.get(Uri.parse(queryUrl));
        if (queryResponse.statusCode == 200) {
          lastQuery = query;
          var locations = _convertResponse(queryResponse.body);
          _lastQueriedLocations = locations;
          return _lastQueriedLocations;
        }
      } finally {
        _shouldAllowQuery = false;
        Timer(Duration(seconds: 1), () {
          _shouldAllowQuery = true;
        });
      }
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
