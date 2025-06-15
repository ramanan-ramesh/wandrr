import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:wandrr/data/trip/models/api_services/flight_operations.dart';

import 'constants.dart';

class AirlinesDataService implements AirlinesDataServiceFacade {
  static const _typeField = 'type';
  static const _apiKeyField = 'key';

  static const _airlinesDataApiIdentifier = 'flightOperationsService';
  static const _airlinesDataApiUrlField = 'url';
  static const String _airlinesDataApiKeyQueryField = 'X-Api-Key';
  final String _airlinesDataApiKey;
  final String _airlinesDataApiUrl;
  static final HashSet<(String, String)> _allAirlinesData = HashSet();

  static Future<AirlinesDataServiceFacade> create() async {
    var airlinesDataApiDocSnapshot = await FirebaseFirestore.instance
        .collection(Constants.apiServicesCollectionName)
        .where(_typeField, isEqualTo: _airlinesDataApiIdentifier)
        .get();
    var airlinesDataApiDocData = airlinesDataApiDocSnapshot.docs.first.data();
    return AirlinesDataService._(
        airlinesDataApiKey: airlinesDataApiDocData[_apiKeyField],
        airlinesDataApiUrl: airlinesDataApiDocData[_airlinesDataApiUrlField]);
  }

  @override
  Future<List<(String airlineName, String airlineCode)>> queryAirlinesData(
      String airlineNameToSearch) async {
    if (airlineNameToSearch.isEmpty || airlineNameToSearch.length <= 3) {
      return [];
    }

    var existingMatches = _allAirlinesData.where((element) =>
        element.$1.toLowerCase() == airlineNameToSearch.toLowerCase());
    if (existingMatches.isNotEmpty) {
      return existingMatches.toList();
    }

    var queryUrl = '$_airlinesDataApiUrl$airlineNameToSearch';
    List<(String, String)> allMatchedAirlineNames = [];
    try {
      var response = await http.get(Uri.parse(queryUrl),
          headers: {_airlinesDataApiKeyQueryField: _airlinesDataApiKey});
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
    } finally {}
    return allMatchedAirlineNames.isEmpty
        ? _allAirlinesData.toList()
        : allMatchedAirlineNames;
  }

  AirlinesDataService._(
      {required String airlinesDataApiKey, required String airlinesDataApiUrl})
      : _airlinesDataApiKey = airlinesDataApiKey,
        _airlinesDataApiUrl = airlinesDataApiUrl;
}
