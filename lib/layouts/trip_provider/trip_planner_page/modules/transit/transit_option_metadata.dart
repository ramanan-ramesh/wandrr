import 'package:flutter/material.dart';
import 'package:wandrr/contracts/transit.dart';

class TransitOptionMetadata {
  final TransitOption transitOption;
  final IconData icon;
  final String name;

  TransitOptionMetadata(
      {required this.transitOption, required this.icon, required this.name});
}
