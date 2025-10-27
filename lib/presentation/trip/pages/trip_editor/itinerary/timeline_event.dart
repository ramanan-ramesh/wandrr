// Event types for timeline
import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

enum ItineraryEventType { lodging, transit, sight }

// Timeline event model
class TimelineEvent {
  final ItineraryEventType type;
  final DateTime? time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final TripEntity
      data; // Original data (TransitFacade, LodgingFacade, or SightFacade)

  TimelineEvent({
    required this.type,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.data,
  });

  void onPressed(BuildContext context) {
    TripManagementEvent? tripManagementEvent;
    if (data is TransitFacade) {
      tripManagementEvent = UpdateTripEntity<TransitFacade>.select(
          tripEntity: data as TransitFacade);
    } else if (data is LodgingFacade) {
      tripManagementEvent = UpdateTripEntity<LodgingFacade>.select(
          tripEntity: data as LodgingFacade);
    } else if (data is SightFacade) {
      tripManagementEvent =
          UpdateTripEntity<SightFacade>.select(tripEntity: data as SightFacade);
    }
    if (tripManagementEvent != null) {
      context.addTripManagementEvent(tripManagementEvent);
    }
  }
}
