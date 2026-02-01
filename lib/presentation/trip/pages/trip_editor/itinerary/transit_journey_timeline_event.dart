import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';

/// Position of a leg within a connected journey
enum TravelLegConnectionPosition { start, middle, end, standalone }

/// Enhanced timeline event for connected transit journeys
class TransitJourneyTimelineEvent extends TimelineEvent<TransitFacade> {
  /// The journey ID that connects this leg to others
  final String journeyId;

  /// Position of this leg within the journey
  final TravelLegConnectionPosition position;

  /// Layover duration string (e.g., "2h 30m") - only for middle/end positions
  final String? layoverDuration;

  /// Reference to the full journey for navigation
  final TransitJourneyFacade journey;

  TransitJourneyTimelineEvent({
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
  bool get isFirstLeg => position == TravelLegConnectionPosition.start;

  /// Whether this is the last leg in the journey
  bool get isLastLeg => position == TravelLegConnectionPosition.end;

  /// Whether this leg has a connection before it
  bool get hasConnectionBefore =>
      position == TravelLegConnectionPosition.middle ||
      position == TravelLegConnectionPosition.end;

  /// Whether this leg has a connection after it
  bool get hasConnectionAfter =>
      position == TravelLegConnectionPosition.start ||
      position == TravelLegConnectionPosition.middle;
}
