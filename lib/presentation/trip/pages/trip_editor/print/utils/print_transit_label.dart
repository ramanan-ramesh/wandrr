import 'package:wandrr/data/trip/models/transit.dart';

String printTransitLabel(TransitOption option) {
  const labels = {
    TransitOption.flight: 'Flight',
    TransitOption.train: 'Train',
    TransitOption.bus: 'Bus',
    TransitOption.ferry: 'Ferry',
    TransitOption.cruise: 'Cruise',
    TransitOption.taxi: 'Taxi',
    TransitOption.walk: 'Walk',
    TransitOption.rentedVehicle: 'Car Rental',
    TransitOption.vehicle: 'Vehicle',
    TransitOption.publicTransport: 'Public Transit',
  };
  return labels[option] ?? option.name;
}
