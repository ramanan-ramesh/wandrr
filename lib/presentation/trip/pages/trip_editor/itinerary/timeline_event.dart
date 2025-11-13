import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

class TimelineEvent<T extends TripEntity> {
  final DateTime time;
  final String title;
  final String subtitle;
  final String? notes;
  final String? confirmationId;
  final IconData icon;
  final Color iconColor;
  final T data;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.data,
    this.notes,
    this.confirmationId,
  });

  void onPressed(BuildContext context) {
    var tripManagementEvent = UpdateTripEntity<T>.select(tripEntity: data);
    context.addTripManagementEvent(tripManagementEvent);
  }

  void onDelete(BuildContext context) {
    var tripManagementEvent = UpdateTripEntity<T>.delete(tripEntity: data);
    context.addTripManagementEvent(tripManagementEvent);
  }
}
