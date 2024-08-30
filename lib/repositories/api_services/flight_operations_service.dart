import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/location.dart';

abstract class FlightOperations {
  Future<List<LocationModelFacade>> queryAirportsData(String airportToSearch);

  Future<List<(String airlineName, String airlineCode)>> queryAirlinesData(
      String airlineNameToSearch);
}

class FlightOperationsService implements FlightOperations {
  static const _apiServiceIdentifier = 'flightOperationsService';
  static const _typeField = 'type';
  static const _apiKeyField = 'key';
  final String _apiKey;
  static bool _shouldAllowAirlineQuery = true;
  static bool _shouldAllowAirportQuery = true;
  final String _apiKeyQueryField = 'X-Api-Key';
  static const _airlinesApiSurfaceUrl =
      'https://api.api-ninjas.com/v1/airlines?';
  static const _airportsApiSurfaceUrl =
      'https://api.api-ninjas.com/v1/airports?';

  static final HashSet<(String, String)> _allAirlinesData = HashSet();
  static final HashSet<LocationModelFacade> _allAirportsData = HashSet();

  static Future<FlightOperations> create() async {
    var apiDocumentQueryResult = await FirebaseFirestore.instance
        .collection(FirestoreCollections.apiServicesCollection)
        .where(_typeField, isEqualTo: _apiServiceIdentifier)
        .get();
    var flightOperationsServiceDocument = apiDocumentQueryResult.docs.first;
    return FlightOperationsService._(
        apiKey: flightOperationsServiceDocument[_apiKeyField]);
  }

  @override
  Future<List<(String airlineName, String airlineCode)>> queryAirlinesData(
      String airlineNameToSearch) async {
    if (!_shouldAllowAirlineQuery ||
        airlineNameToSearch.isEmpty ||
        airlineNameToSearch.length <= 2) {
      return [];
    }

    var existingMatches = _allAirlinesData.where((element) =>
        element.$1.toLowerCase() == airlineNameToSearch.toLowerCase());
    if (existingMatches.isNotEmpty) {
      return existingMatches.toList();
    }

    var queryUrl = _constructQueryForAirlineSearch(airlineNameToSearch);
    List<(String, String)> allMatchedAirlineNames = [];
    try {
      var response = await http
          .get(Uri.parse(queryUrl), headers: {_apiKeyQueryField: _apiKey});
      if (response.statusCode == 200) {
        var decodedResponse = json.decode(response.body);
        var allAirlineMatchesList = List.from(decodedResponse);
        var airlineDataList = allAirlineMatchesList
            .map((e) => (
                  e['name'] as String,
                  e['iata'] != null
                      ? ((e['iata'] as String).isNotEmpty
                          ? e['iata'] as String
                          : e['icao'] as String)
                      : e['icao'] as String
                ))
            .toList();
        allMatchedAirlineNames.addAll(airlineDataList);
        _allAirlinesData.addAll(airlineDataList);
      }
    } finally {
      _shouldAllowAirlineQuery = false;
      Timer(Duration(seconds: 1), () {
        _shouldAllowAirlineQuery = true;
      });
    }
    return allMatchedAirlineNames.isEmpty
        ? _allAirlinesData.toList()
        : allMatchedAirlineNames;
  }

  @override
  Future<List<LocationModelFacade>> queryAirportsData(
      String airportToSearch) async {
    if (!_shouldAllowAirportQuery ||
        airportToSearch.isEmpty ||
        airportToSearch.length <= 2) {
      return [];
    }

    var existingMatches = _allAirportsData.where((element) =>
        (element.context as AirportLocationContext)
            .name
            .toLowerCase()
            .contains(airportToSearch.toLowerCase()));
    if (existingMatches.isNotEmpty) {
      return existingMatches.toList();
    }

    var queryUrl = _constructQueryForAirportSearch(airportToSearch);
    List<LocationModelFacade> allMatchedAirports = [];
    try {
      var response = await http
          .get(Uri.parse(queryUrl), headers: {_apiKeyQueryField: _apiKey});
      if (response.statusCode == 200) {
        var decodedResponse = json.decode(response.body);
        var allAirportsList = List.from(decodedResponse);
        var airportsDataList = allAirportsList
            .map((e) => LocationModelFacade(
                tripId: '',
                latitude: double.parse(e['latitude']),
                longitude: double.parse(e['longitude']),
                context: AirportLocationContext.fromApi(e)))
            .toList();
        allMatchedAirports.addAll(airportsDataList);
        _allAirportsData.addAll(airportsDataList);
      }
    } finally {
      _shouldAllowAirportQuery = false;
      Timer(Duration(seconds: 1), () {
        _shouldAllowAirportQuery = true;
      });
    }
    return allMatchedAirports.isEmpty
        ? _allAirportsData.toList()
        : allMatchedAirports;
  }

  String _constructQueryForAirlineSearch(String airlineSearched) {
    return '${_airlinesApiSurfaceUrl}name=$airlineSearched';
  }

  String _constructQueryForAirportSearch(String airportSearched) {
    return '${_airportsApiSurfaceUrl}name=$airportSearched';
  }

  FlightOperationsService._({required String apiKey}) : _apiKey = apiKey;
}
