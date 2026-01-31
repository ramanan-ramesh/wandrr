import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Position of a leg within a connected journey
enum ConnectionPosition { start, middle, end, standalone }

class TimelineEvent<T extends TripEntity> {
  final DateTime time;
  final String title;
  final String subtitle;
  final String? notes;
  final String? confirmationId;
  final IconData icon;
  final Color iconColor;
  final T data;
  final TripManagementEvent Function(T data)? tripManagementEventCreatorOnTap;
  final TripManagementEvent Function(T data)?
      tripManagementEventCreatorOnDelete;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.data,
    this.tripManagementEventCreatorOnTap,
    this.tripManagementEventCreatorOnDelete,
    this.notes,
    this.confirmationId,
  });

  void onPressed(BuildContext context) {
    var tripManagementEvent = tripManagementEventCreatorOnTap != null
        ? tripManagementEventCreatorOnTap!(data)
        : UpdateTripEntity<T>.select(tripEntity: data);
    context.addTripManagementEvent(tripManagementEvent);
  }

  void onDelete(BuildContext context) {
    var tripManagementEvent = tripManagementEventCreatorOnDelete != null
        ? tripManagementEventCreatorOnDelete!(data)
        : UpdateTripEntity<T>.delete(tripEntity: data);
    context.addTripManagementEvent(tripManagementEvent);
  }
}

/// Enhanced timeline event for connected transit journeys
class ConnectedTransitTimelineEvent extends TimelineEvent<TransitFacade> {
  /// The journey ID that connects this leg to others
  final String journeyId;

  /// Position of this leg within the journey
  final ConnectionPosition position;

  /// Layover duration string (e.g., "2h 30m") - only for middle/end positions
  final String? layoverDuration;

  /// Reference to the full journey for navigation
  final TransitJourneyFacade journey;

  ConnectedTransitTimelineEvent({
    required super.time,
    required super.title,
    required super.subtitle,
    required super.icon,
    required super.iconColor,
    required super.data,
    required this.journeyId,
    required this.position,
    required this.journey,
    this.layoverDuration,
    super.notes,
    super.confirmationId,
  });

  /// Whether this is the first leg in the journey
  bool get isFirstLeg => position == ConnectionPosition.start;

  /// Whether this is the last leg in the journey
  bool get isLastLeg => position == ConnectionPosition.end;

  /// Whether this leg has a connection before it
  bool get hasConnectionBefore =>
      position == ConnectionPosition.middle ||
      position == ConnectionPosition.end;

  /// Whether this leg has a connection after it
  bool get hasConnectionAfter =>
      position == ConnectionPosition.start ||
      position == ConnectionPosition.middle;
}
