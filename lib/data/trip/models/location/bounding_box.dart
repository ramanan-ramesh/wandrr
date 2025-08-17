import 'package:equatable/equatable.dart';

class BoundingBox extends Equatable {
  static const _maxLatField = 'maxLat';
  static const _minLatField = 'minLat';
  static const _maxLonField = 'maxLon';
  static const _minLonField = 'minLon';
  final double maxLat, minLat;
  final double maxLon, minLon;

  const BoundingBox(
      {required this.maxLat,
      required this.minLat,
      required this.maxLon,
      required this.minLon});

  static BoundingBox fromDocument(Map<String, dynamic> json) => BoundingBox(
      maxLat: double.parse(json[_maxLatField].toString()),
      minLat: double.parse(json[_minLatField].toString()),
      maxLon: double.parse(json[_maxLonField].toString()),
      minLon: double.parse(json[_minLonField].toString()));

  BoundingBox clone() => BoundingBox(
      maxLat: maxLat, minLat: minLat, maxLon: maxLon, minLon: minLon);

  Map<String, dynamic> toJson() => {
        _maxLatField: maxLat,
        _maxLonField: maxLon,
        _minLonField: minLon,
        _minLatField: minLat
      };

  @override
  List<Object?> get props => [maxLat, minLat, maxLon, minLon];
}
