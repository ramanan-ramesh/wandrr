import 'package:wandrr/trip_data/models/location/location.dart';

abstract class GeoLocatorService {
  Future<List<LocationFacade>> performQuery(Object query);
}
