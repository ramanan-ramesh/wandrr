import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/models/api_services/airports_data.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'constants.dart';

class AirportsDataService implements AirportsDataServiceFacade {
  static const _typeField = 'type';
  static const _apiIdentifier = 'airportsData';
  static const _lastRefreshedAtField = 'lastRefreshedAt';
  static const _dataAtSharedPrefsField = '${_apiIdentifier}_data';
  static const _lastRefreshedAtSharedPrefsField =
      '${_apiIdentifier}_$_lastRefreshedAtField';

  static final HashSet<LocationFacade> _allAirportsData = HashSet();

  static Future<AirportsDataServiceFacade> create() async {
    var airportsDataApiDocSnapshot = await FirebaseFirestore.instance
        .collection(Constants.apiServicesCollectionName)
        .where(_typeField, isEqualTo: _apiIdentifier)
        .get();
    var airportsDataApiDoc = airportsDataApiDocSnapshot.docs.first;
    await _tryInitializeCache(airportsDataApiDoc);
    return AirportsDataService();
  }

  static Future<void> _tryInitializeCache(
      QueryDocumentSnapshot<Map<String, dynamic>> airportsDataApiDoc) async {
    var sharedPreferences = await SharedPreferences.getInstance();
    var lastRefreshedAt =
        (airportsDataApiDoc[_lastRefreshedAtField] as Timestamp).toDate();
    var shouldSynchronizeCache =
        _shouldSynchronizeCache(sharedPreferences, lastRefreshedAt);
    if (shouldSynchronizeCache) {
      var dataUrl = airportsDataApiDoc['dataUrl'];
      await _updateCache(dataUrl, lastRefreshedAt, sharedPreferences);
    }
    var dataAtCacheJsonMap =
        jsonDecode(sharedPreferences.getString(_dataAtSharedPrefsField)!)
            as Map<String, dynamic>;
    _allAirportsData.addAll(dataAtCacheJsonMap.entries.map((entry) {
      var airportData = entry.value as Map<String, dynamic>;
      return LocationFacade(
        tripId: '',
        latitude: double.parse(airportData['lat'].toString()),
        longitude: double.parse(airportData['lon'].toString()),
        context: AirportLocationContext.fromDocument(airportData),
      );
    }));
  }

  static bool _shouldSynchronizeCache(
      SharedPreferences sharedPreferences, DateTime lastRefreshedAt) {
    if (sharedPreferences.containsKey(_lastRefreshedAtSharedPrefsField) &&
        sharedPreferences.containsKey(_dataAtSharedPrefsField)) {
      var lastRefreshedAtCacheValue =
          sharedPreferences.getString(_lastRefreshedAtSharedPrefsField);
      var dataAtCacheValue =
          sharedPreferences.getString(_dataAtSharedPrefsField);
      if (lastRefreshedAtCacheValue != null && dataAtCacheValue != null) {
        return DateTime.parse(lastRefreshedAtCacheValue)
            .isAfter(lastRefreshedAt);
      }
      return lastRefreshedAtCacheValue == null ||
          DateTime.parse(lastRefreshedAtCacheValue).isBefore(DateTime.now());
    }
    return true;
  }

  static Future _updateCache(String dataUrl, DateTime lastRefreshedAt,
      SharedPreferences sharedPreferences) async {
    var httpResponse = await http.get(Uri.parse(dataUrl));
    var httpResponseBody = httpResponse.body;
    var httpResponseBodyJson =
        jsonDecode(httpResponseBody) as Map<String, dynamic>;
    _allAirportsData.addAll(httpResponseBodyJson.entries.map((entry) {
      var airportData = entry.value as Map<String, dynamic>;
      return LocationFacade(
        tripId: '',
        latitude: double.parse(airportData['lat'].toString()),
        longitude: double.parse(airportData['lon'].toString()),
        context: AirportLocationContext.fromDocument(airportData),
      );
    }));
    await sharedPreferences.setString(
        _dataAtSharedPrefsField, jsonEncode(httpResponseBodyJson));
    await sharedPreferences.setString(
        _lastRefreshedAtSharedPrefsField, lastRefreshedAt.toString());
  }

  @override
  Future<Iterable<LocationFacade>> queryAirportsData(
      String airportToSearch) async {
    airportToSearch = airportToSearch.toLowerCase().trim();
    if (airportToSearch.isEmpty || airportToSearch.length < 3) {
      return Future.value(<LocationFacade>[]);
    }
    return _filterAirportsData(airportToSearch);
  }

  List<LocationFacade> _filterAirportsData(String airportToSearch) {
    var filteredAirports = <LocationFacade>[];
    airportToSearch = airportToSearch.toLowerCase().trim();
    for (var airportData in _allAirportsData) {
      var airportLocationContext =
          airportData.context as AirportLocationContext;
      if (_contains(airportLocationContext.name, airportToSearch) ||
          (airportToSearch.length == 3 &&
              _contains(airportLocationContext.airportCode, airportToSearch)) ||
          _contains(airportLocationContext.city, airportToSearch)) {
        filteredAirports.add(airportData);
      }
    }
    return filteredAirports;
  }

  static bool _contains(String a, String b) {
    return a.toLowerCase().contains(b.toLowerCase());
  }
}
