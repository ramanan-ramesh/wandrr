import 'package:equatable/equatable.dart';

import 'location.dart';
import 'location_context.dart';

class AirportLocationContext with EquatableMixin implements LocationContext {
  @override
  final LocationType locationType = LocationType.airport;
  static const _locationTypeField = 'type';

  @override
  final String city;
  static const _cityField = 'city';

  @override
  final String name;
  static const _nameField = 'name';

  final String airportCode;
  static const _iataCodeField = 'iata';

  AirportLocationContext.fromDocument(Map<String, dynamic> json)
      : this._(
            city: json[_cityField],
            airportCode: json[_iataCodeField],
            airportName: json[_nameField]);

  @override
  Map<String, dynamic> toJson() => {
        _nameField: name,
        _cityField: city,
        _iataCodeField: airportCode,
        _locationTypeField: locationType.name
      };

  @override
  LocationContext clone() => AirportLocationContext._(
      city: city, airportCode: airportCode, airportName: name);

  AirportLocationContext._(
      {required this.city,
      required this.airportCode,
      required String airportName})
      : name = airportName;

  @override
  List<Object?> get props => [locationType, city, name, airportCode];
}
