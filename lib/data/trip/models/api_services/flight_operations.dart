import 'package:wandrr/data/trip/models/location/location.dart';

abstract class FlightOperationsService {
  Future<List<LocationFacade>> queryAirportsData(String airportToSearch);

  Future<List<(String airlineName, String airlineCode)>> queryAirlinesData(
      String airlineNameToSearch);
}
