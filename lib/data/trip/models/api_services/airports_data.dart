import 'package:wandrr/data/trip/models/location/location.dart';

abstract class AirportsDataServiceFacade {
  Future<Iterable<LocationFacade>> queryAirportsData(String airportToSearch);
}
