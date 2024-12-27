import 'package:wandrr/data/trip/models/location/location.dart';

abstract class GeoLocatorService {
  Future<List<LocationFacade>> performQuery(String query);
}
