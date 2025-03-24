import 'package:equatable/equatable.dart';

import 'location.dart';

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
  static const _iataAirportCodeField = 'iata';
  static const _icaoAirportCodeField = 'icao';
  static const _airportCodeField = 'code';

  AirportLocationContext._(
      {required this.city,
      required this.airportCode,
      required String airportName})
      : name = airportName;

  AirportLocationContext.fromApi(Map<String, dynamic> json)
      : this._(
            city: json[_cityField],
            airportCode: json[_iataAirportCodeField] != null
                ? ((json[_iataAirportCodeField] as String).isNotEmpty
                    ? json[_iataAirportCodeField]
                    : json[_icaoAirportCodeField])
                : json[_icaoAirportCodeField],
            airportName: json[_nameField]);

  AirportLocationContext.fromDocument(Map<String, dynamic> json)
      : this._(
            city: json[_cityField],
            airportCode: json[_airportCodeField],
            airportName: json[_nameField]);

  @override
  Map<String, dynamic> toJson() {
    return {
      _nameField: name,
      _cityField: city,
      _airportCodeField: airportCode,
      _locationTypeField: locationType.name
    };
  }

  @override
  LocationContext clone() {
    return AirportLocationContext._(
        city: city, airportCode: airportCode, airportName: name);
  }

  @override
  List<Object?> get props => [locationType, city, name, airportCode];
}
