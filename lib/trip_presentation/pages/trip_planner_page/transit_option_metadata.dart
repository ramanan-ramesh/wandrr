import 'package:flutter/material.dart';
import 'package:wandrr/trip_data/models/transit.dart';

class TransitOptionMetadata {
  final TransitOption transitOption;
  final IconData icon;
  final String name;

  TransitOptionMetadata(
      {required this.transitOption, required this.icon, required this.name});
}
