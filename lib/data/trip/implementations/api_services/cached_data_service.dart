import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/models/api_service.dart';

import 'constants.dart';

abstract class CachedDataService<TResult>
    extends ApiService<String, Iterable<TResult>> {
  static const _lastRefreshedAtField = 'lastRefreshedAt';
  static const _typeField = 'type';
  static const _dataUrlField = 'dataUrl';

  String get _lastRefreshedAtSharedPrefsField =>
      '${apiIdentifier}_$_lastRefreshedAtField';

  String get _dataAtSharedPrefsField => '${apiIdentifier}_data';

  final HashSet<TResult> _allData = HashSet<TResult>();

  CachedDataService(this.apiIdentifier);

  @override
  final String apiIdentifier;

  @override
  Future<void> initialize() async {
    var documentSnapshot = await FirebaseFirestore.instance
        .collection(Constants.apiServicesCollectionName)
        .where(_typeField, isEqualTo: apiIdentifier)
        .get();
    var documentData = documentSnapshot.docs.first;
    await _tryInitializeCache(documentData);
  }

  @override
  FutureOr<void> dispose() async {
    _allData.clear();
  }

  TResult fromJsonInDatabase(Map<String, dynamic> jsonInDatabase);

  TResult fromJsonInCache(Map<String, dynamic> jsonInCache);

  @override
  Future<Iterable<TResult>> queryData(String query) {
    if (query.isEmpty) {
      return Future.value(_allData);
    }
    return Future.value(
        _allData.where((item) => shouldConsiderItemInQueryResult(item, query)));
  }

  bool shouldConsiderItemInQueryResult(TResult item, String query) {
    return item.toString().toLowerCase().contains(query.toLowerCase());
  }

  Future<void> _tryInitializeCache(
      QueryDocumentSnapshot<Map<String, dynamic>> documentData) async {
    var sharedPreferences = await SharedPreferences.getInstance();
    var lastRefreshedAt =
        (documentData[_lastRefreshedAtField] as Timestamp).toDate();
    var shouldSynchronizeCache =
        _shouldSynchronizeCache(sharedPreferences, lastRefreshedAt);
    if (shouldSynchronizeCache) {
      var dataUrl = documentData[_dataUrlField].toString();
      await _updateCache(dataUrl, lastRefreshedAt, sharedPreferences);
    }
    var dataAtCacheJsonMap =
        jsonDecode(sharedPreferences.getString(_dataAtSharedPrefsField)!)
            as List;
    _allData.addAll(dataAtCacheJsonMap.map((entry) {
      return fromJsonInCache(entry as Map<String, dynamic>);
    }));
  }

  Future _updateCache(String dataUrl, DateTime lastRefreshedAt,
      SharedPreferences sharedPreferences) async {
    var httpResponse = await http.get(Uri.parse(dataUrl));
    var httpResponseBody = httpResponse.body;
    var httpResponseBodyJson = jsonDecode(httpResponseBody) as List;
    _allData.addAll(httpResponseBodyJson.map((entry) {
      return fromJsonInDatabase(entry);
    }));
    await sharedPreferences.setString(
        _dataAtSharedPrefsField, jsonEncode(httpResponseBodyJson));
    await sharedPreferences.setString(
        _lastRefreshedAtSharedPrefsField, lastRefreshedAt.toString());
  }

  bool _shouldSynchronizeCache(
      SharedPreferences sharedPreferences, DateTime lastRefreshedAt) {
    if (sharedPreferences.containsKey(_lastRefreshedAtSharedPrefsField) &&
        sharedPreferences.containsKey(_dataAtSharedPrefsField)) {
      var lastRefreshedAtCacheValue =
          sharedPreferences.getString(_lastRefreshedAtSharedPrefsField);
      var dataAtCacheValue =
          sharedPreferences.getString(_dataAtSharedPrefsField);
      if (lastRefreshedAtCacheValue != null && dataAtCacheValue != null) {
        return DateTime.parse(lastRefreshedAtCacheValue)
            .isBefore(lastRefreshedAt);
      }
    }
    return true;
  }
}
