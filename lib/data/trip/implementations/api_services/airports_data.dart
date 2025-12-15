import 'package:wandrr/data/trip/implementations/api_services/cached_data_service.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

class AirportsDataService extends CachedDataService<LocationFacade> {
  static const String _apiIdentifier = "airportsData";

  AirportsDataService() : super(_apiIdentifier);

  @override
  LocationFacade fromJsonInCache(Map<String, dynamic> jsonInCache) =>
      _fromJson(jsonInCache);

  @override
  LocationFacade fromJsonInDatabase(Map<String, dynamic> jsonInDatabase) =>
      _fromJson(jsonInDatabase);

  @override
  bool shouldConsiderItemInQueryResult(LocationFacade item, String query) {
    var airportLocationContext = item.context as AirportLocationContext;
    return _contains(airportLocationContext.name, query) ||
        (query.length == 3 &&
            _contains(airportLocationContext.airportCode, query)) ||
        _contains(airportLocationContext.city, query);
  }

  static LocationFacade _fromJson(Map<String, dynamic> json) => LocationFacade(
        latitude: double.parse(json['lat'].toString()),
        longitude: double.parse(json['lon'].toString()),
        context: AirportLocationContext.fromDocument(json),
      );

  static bool _contains(String a, String b) =>
      a.toLowerCase().contains(b.toLowerCase());
}
