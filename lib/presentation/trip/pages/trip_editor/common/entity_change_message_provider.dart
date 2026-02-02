import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change_context.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';

/// Provides context-aware messages for entity changes.
/// Works for both TripMetadata updates and timeline conflict resolution.
class EntityChangeMessageProvider {
  final EntityChangeContext context;

  const EntityChangeMessageProvider(this.context);

  /// Creates a provider for trip metadata update context
  factory EntityChangeMessageProvider.forMetadataUpdate() =>
      const EntityChangeMessageProvider(EntityChangeContext.tripMetadataUpdate);

  /// Creates a provider for timeline conflict context
  factory EntityChangeMessageProvider.forTimelineConflict() =>
      const EntityChangeMessageProvider(EntityChangeContext.timelineConflict);

  // =========================================================================
  // Section Headers
  // =========================================================================

  /// Returns the section title for stays
  String staysSectionTitle(int count) {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return 'Affected Stays ($count)';
      case EntityChangeContext.timelineConflict:
        return 'Conflicting Stays ($count)';
    }
  }

  /// Returns the section title for transits
  String transitsSectionTitle(int count) {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return 'Affected Transits ($count)';
      case EntityChangeContext.timelineConflict:
        return 'Conflicting Transits ($count)';
    }
  }

  /// Returns the section title for sights
  String sightsSectionTitle(int count) {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return 'Affected Sights ($count)';
      case EntityChangeContext.timelineConflict:
        return 'Conflicting Sights ($count)';
    }
  }

  /// Returns the section title for expenses
  String expensesSectionTitle(int count) {
    return 'Expenses ($count)';
  }

  // =========================================================================
  // Section Info Messages
  // =========================================================================

  /// Returns the info banner message for stays section
  EntityChangeInfoMessage staysSectionInfo() {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return const EntityChangeInfoMessage(
          title: 'These stays fall outside the new trip dates',
          details:
              '• Dates have been adjusted to fit within the new trip range where possible\n'
              '• Set new check-in/check-out dates, or delete stays you no longer need\n'
              '• Stays without valid dates will be skipped',
        );
      case EntityChangeContext.timelineConflict:
        return const EntityChangeInfoMessage(
          title: 'These stays have overlapping check-in/check-out times',
          details:
              '• The check-in or check-out time falls during another travel or stay\n'
              '• Adjust the dates to avoid conflicts, or delete the stay\n'
              '• Times have been auto-adjusted where possible',
        );
    }
  }

  /// Returns the info banner message for transits section
  EntityChangeInfoMessage transitsSectionInfo() {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return const EntityChangeInfoMessage(
          title: 'These transits fall outside the new trip dates',
          details: '• Dates have been cleared and need to be set again\n'
              '• Set new departure/arrival times, or delete transits you no longer need\n'
              '• Transits without valid dates will be skipped',
        );
      case EntityChangeContext.timelineConflict:
        return const EntityChangeInfoMessage(
          title: 'These transits have conflicting departure/arrival times',
          details:
              '• The departure or arrival time overlaps with your selected times\n'
              '• Adjust the times to avoid conflicts, or delete the transit\n'
              '• Times have been auto-adjusted where possible',
        );
    }
  }

  /// Returns the info banner message for sights section
  EntityChangeInfoMessage sightsSectionInfo() {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return const EntityChangeInfoMessage(
          title: 'These sights fall outside the new trip dates',
          details: '• Visit dates have been cleared and need to be set again\n'
              '• Set new visit dates, or delete sights you no longer plan to visit\n'
              '• Sights without dates will remain in your itinerary but unscheduled',
        );
      case EntityChangeContext.timelineConflict:
        return const EntityChangeInfoMessage(
          title: 'These sights have conflicting visit times',
          details: '• The visit time overlaps with a travel or stay period\n'
              '• Adjust the visit time to avoid conflicts, or delete the sight\n'
              '• Visit times have been cleared where conflicts exist',
        );
    }
  }

  /// Returns the info banner message for expenses section
  EntityChangeInfoMessage expensesSectionInfo({
    Iterable<String> addedContributors = const [],
    Iterable<String> removedContributors = const [],
  }) {
    final addedText = addedContributors.isNotEmpty
        ? 'Added: ${addedContributors.join(", ")}'
        : null;
    final removedText = removedContributors.isNotEmpty
        ? 'Removed: ${removedContributors.join(", ")}'
        : null;

    final detailParts = <String>[
      if (addedText != null)
        '• $addedText - select which expenses to include them in',
      if (removedText != null)
        '• $removedText - their expense records are preserved for historical accuracy',
    ];

    return EntityChangeInfoMessage(
      title: 'Review expense split changes',
      details: detailParts.isNotEmpty
          ? detailParts.join('\n')
          : '• Use checkboxes to select which expenses to include new tripmates in',
    );
  }

  // =========================================================================
  // Entity-specific Messages
  // =========================================================================

  /// Returns a message for a specific entity change based on its timeline position
  String entityChangeMessage<T extends TripEntity>(EntityChange<T> change) {
    final position = change.timelinePosition;
    final entity = change.originalEntity;

    if (entity is LodgingFacade) {
      return _stayChangeMessage(entity, position);
    } else if (entity is TransitFacade) {
      return _transitChangeMessage(entity, position);
    } else if (entity is SightFacade) {
      return _sightChangeMessage(entity, position);
    }

    return change.conflictMessage ?? 'This item needs to be reviewed.';
  }

  String _stayChangeMessage(
      LodgingFacade stay, EntityTimelinePosition? position) {
    final location = stay.location?.toString() ?? 'this stay';

    switch (position) {
      case EntityTimelinePosition.beforeEvent:
        return 'Check-out for $location is before the trip starts.';
      case EntityTimelinePosition.overlapWithStartBoundary:
        return 'Check-in for $location overlaps with the start of another event.';
      case EntityTimelinePosition.duringEvent:
        return 'The stay at $location falls during another travel period.';
      case EntityTimelinePosition.overlapWithEndBoundary:
        return 'Check-out for $location overlaps with the end of another event.';
      case EntityTimelinePosition.afterEvent:
        return 'Check-in for $location is after the trip ends.';
      case EntityTimelinePosition.exactBoundaryMatch:
        return 'Check-in/out for $location matches another event boundary exactly.';
      case null:
        return context == EntityChangeContext.tripMetadataUpdate
            ? 'The stay at $location falls outside the new trip dates.'
            : 'The stay at $location has conflicting dates.';
    }
  }

  String _transitChangeMessage(
      TransitFacade transit, EntityTimelinePosition? position) {
    final from = transit.departureLocation?.toString() ?? '?';
    final to = transit.arrivalLocation?.toString() ?? '?';
    final route = '$from → $to';

    switch (position) {
      case EntityTimelinePosition.beforeEvent:
        return 'Transit $route is before the trip starts.';
      case EntityTimelinePosition.overlapWithStartBoundary:
        return 'Departure for $route overlaps with the start of another event.';
      case EntityTimelinePosition.duringEvent:
        return 'Transit $route falls during another stay or travel.';
      case EntityTimelinePosition.overlapWithEndBoundary:
        return 'Arrival for $route overlaps with the end of another event.';
      case EntityTimelinePosition.afterEvent:
        return 'Transit $route is after the trip ends.';
      case EntityTimelinePosition.exactBoundaryMatch:
        return 'Departure/arrival for $route matches another event boundary.';
      case null:
        return context == EntityChangeContext.tripMetadataUpdate
            ? 'Transit $route falls outside the new trip dates.'
            : 'Transit $route has conflicting times.';
    }
  }

  String _sightChangeMessage(
      SightFacade sight, EntityTimelinePosition? position) {
    final name = sight.name.isNotEmpty ? '"${sight.name}"' : 'this sight';

    switch (position) {
      case EntityTimelinePosition.beforeEvent:
        return 'Visit to $name is scheduled before the trip starts.';
      case EntityTimelinePosition.overlapWithStartBoundary:
        return 'Visit time for $name overlaps with the start of a travel.';
      case EntityTimelinePosition.duringEvent:
        return 'Visit to $name is during a travel period.';
      case EntityTimelinePosition.overlapWithEndBoundary:
        return 'Visit time for $name overlaps with the end of a travel.';
      case EntityTimelinePosition.afterEvent:
        return 'Visit to $name is scheduled after the trip ends.';
      case EntityTimelinePosition.exactBoundaryMatch:
        return 'Visit time for $name matches a travel departure/arrival.';
      case null:
        return context == EntityChangeContext.tripMetadataUpdate
            ? 'The sight $name falls outside the new trip dates.'
            : 'The sight $name has a conflicting visit time.';
    }
  }

  // =========================================================================
  // Summary Messages
  // =========================================================================

  /// Builds a summary message describing all conflicts
  String buildSummaryMessage(TripDataUpdatePlan plan) {
    final parts = <String>[];

    if (plan.transitChanges.isNotEmpty) {
      final count = plan.transitChanges.length;
      final label = context == EntityChangeContext.tripMetadataUpdate
          ? 'affected transit${count > 1 ? 's' : ''}'
          : 'transit${count > 1 ? 's' : ''} with conflicting times';
      parts.add('$count $label');
    }

    if (plan.stayChanges.isNotEmpty) {
      final count = plan.stayChanges.length;
      final label = context == EntityChangeContext.tripMetadataUpdate
          ? 'affected stay${count > 1 ? 's' : ''}'
          : 'stay${count > 1 ? 's' : ''} with overlapping dates';
      parts.add('$count $label');
    }

    if (plan.sightChanges.isNotEmpty) {
      final count = plan.sightChanges.length;
      final label = context == EntityChangeContext.tripMetadataUpdate
          ? 'affected sight${count > 1 ? 's' : ''}'
          : 'sight${count > 1 ? 's' : ''} with conflicting visit times';
      parts.add('$count $label');
    }

    if (parts.isEmpty) {
      return context == EntityChangeContext.tripMetadataUpdate
          ? 'No items are affected by this change.'
          : 'No conflicts detected.';
    }

    final prefix =
        context == EntityChangeContext.tripMetadataUpdate ? 'Found ' : 'Found ';
    final suffix = context == EntityChangeContext.tripMetadataUpdate
        ? '. Review and update as needed.'
        : '. Review and resolve each conflict below.';

    return '$prefix${parts.join(', ')}$suffix';
  }

  /// Returns an action message explaining what the user should do
  String buildActionMessage() {
    switch (context) {
      case EntityChangeContext.tripMetadataUpdate:
        return 'Items marked for deletion will be removed when you save. '
            'Update times for items you want to keep, or tap restore to undo deletion.';
      case EntityChangeContext.timelineConflict:
        return 'Items marked for deletion will be removed when you save. '
            'To keep an item, update its times to avoid conflicts, or tap the restore button.';
    }
  }
}

/// Represents an informational message with a title and details
class EntityChangeInfoMessage {
  final String title;
  final String details;

  const EntityChangeInfoMessage({
    required this.title,
    required this.details,
  });
}
