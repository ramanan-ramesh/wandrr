import 'package:wandrr/trip_data/models/location.dart';

abstract class GeoLocatorService {
  Future<List<LocationFacade>> performQuery(Object query);
}
