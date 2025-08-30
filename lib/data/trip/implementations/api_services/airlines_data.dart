import 'package:wandrr/data/trip/implementations/api_services/cached_data_service.dart';

class AirlinesDataService
    extends CachedDataService<(String airlineName, String airlineCode)> {
  static const String _apiIdentifier = "airlinesData";
  static const String _nameField = 'name';
  static const String _iataField = 'iata';

  AirlinesDataService() : super(_apiIdentifier);

  @override
  (String, String) fromJsonInCache(Map<String, dynamic> jsonInCache) =>
      _fromJson(jsonInCache);

  @override
  (String, String) fromJsonInDatabase(Map<String, dynamic> jsonInDatabase) =>
      _fromJson(jsonInDatabase);

  @override
  bool shouldConsiderItemInQueryResult(
      (String airlineName, String airlineCode) item, String query) {
    var queryInLowerCase = query.toLowerCase();
    return item.$1.toLowerCase().contains(queryInLowerCase) ||
        item.$2.toLowerCase() == queryInLowerCase;
  }

  static (String, String) _fromJson(Map<String, dynamic> json) =>
      (json[_nameField] as String, json[_iataField] as String);
}
