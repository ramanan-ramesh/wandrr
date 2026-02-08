import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Context for entity change messages
enum MessageContext { metadataUpdate, timelineConflict }

/// Provides context-aware messages for entity changes.
/// Works for both TripMetadata updates and timeline conflict resolution.
class EntityChangeMessageProvider {
  final MessageContext context;

  const EntityChangeMessageProvider(this.context);

  factory EntityChangeMessageProvider.forMetadataUpdate() =>
      const EntityChangeMessageProvider(MessageContext.metadataUpdate);

  factory EntityChangeMessageProvider.forTimelineConflict() =>
      const EntityChangeMessageProvider(MessageContext.timelineConflict);

  // =========================================================================
  // Section Headers
  // =========================================================================

  String staysSectionTitle(int count) =>
      context == MessageContext.metadataUpdate
          ? 'Affected Stays ($count)'
          : 'Conflicting Stays ($count)';

  String transitsSectionTitle(int count) =>
      context == MessageContext.metadataUpdate
          ? 'Affected Transits ($count)'
          : 'Conflicting Transits ($count)';

  String sightsSectionTitle(int count) =>
      context == MessageContext.metadataUpdate
          ? 'Affected Sights ($count)'
          : 'Conflicting Sights ($count)';

  String expensesSectionTitle(int count) => 'Expenses ($count)';

  // =========================================================================
  // Section Info Messages
  // =========================================================================

  EntityChangeInfoMessage staysSectionInfo() =>
      context == MessageContext.metadataUpdate
          ? const EntityChangeInfoMessage(
              title: 'These stays fall outside the new trip dates',
              details:
                  '• Set new check-in/check-out dates, or delete stays you no longer need',
            )
          : const EntityChangeInfoMessage(
              title: 'These stays overlap with your selected times',
              details:
                  '• Adjust the dates to avoid conflicts, or delete the stay',
            );

  EntityChangeInfoMessage transitsSectionInfo() =>
      context == MessageContext.metadataUpdate
          ? const EntityChangeInfoMessage(
              title: 'These transits fall outside the new trip dates',
              details:
                  '• Set new departure/arrival times, or delete transits you no longer need',
            )
          : const EntityChangeInfoMessage(
              title: 'These transits have conflicting times',
              details:
                  '• Adjust the times to avoid conflicts, or delete the transit',
            );

  EntityChangeInfoMessage sightsSectionInfo() =>
      context == MessageContext.metadataUpdate
          ? const EntityChangeInfoMessage(
              title: 'These sights fall outside the new trip dates',
              details:
                  '• Set new visit dates, or delete sights you no longer plan to visit',
            )
          : const EntityChangeInfoMessage(
              title: 'These sights have conflicting visit times',
              details:
                  '• Adjust the visit time to avoid conflicts, or delete the sight',
            );

  EntityChangeInfoMessage expensesSectionInfo({
    Iterable<String> addedContributors = const [],
    Iterable<String> removedContributors = const [],
  }) {
    final parts = <String>[];
    if (addedContributors.isNotEmpty) {
      parts.add(
          '• Added: ${addedContributors.join(", ")} - select which expenses to include them in');
    }
    if (removedContributors.isNotEmpty) {
      parts.add(
          '• Removed: ${removedContributors.join(", ")} - their records are preserved');
    }
    return EntityChangeInfoMessage(
      title: 'Review expense split changes',
      details: parts.isNotEmpty
          ? parts.join('\n')
          : '• Use checkboxes to select expenses',
    );
  }

  // =========================================================================
  // Per-Item Action Messages
  // =========================================================================

  String stayActionMessage(EntityChange<LodgingFacade> change) {
    final location = change.original.location?.toString() ?? 'this stay';
    if (change.isClamped) {
      return 'Dates adjusted for $location. Verify check-in/check-out times or delete.';
    }
    return 'Update check-in/check-out dates for $location, or it will be deleted.';
  }

  String transitActionMessage(EntityChange<TransitFacade> change) {
    final from = change.original.departureLocation?.toString() ?? '?';
    final to = change.original.arrivalLocation?.toString() ?? '?';
    if (change.isClamped) {
      return 'Times adjusted for $from → $to. Verify departure/arrival or delete.';
    }
    return 'Set departure/arrival times for $from → $to, or it will be deleted.';
  }

  String sightActionMessage(EntityChange<SightFacade> change) {
    final name = change.original.name.isNotEmpty
        ? '"${change.original.name}"'
        : 'this sight';
    if (change.isClamped) {
      return 'Visit time adjusted for $name. Verify or delete.';
    }
    return 'Set a new visit time for $name, or it will be deleted.';
  }

  // =========================================================================
  // Summary Messages
  // =========================================================================

  String buildSummaryMessage(TripDataUpdatePlan plan) {
    final parts = <String>[];
    if (plan.transitChanges.isNotEmpty) {
      final c = plan.transitChanges.length;
      parts.add('$c transit${c > 1 ? 's' : ''}');
    }
    if (plan.stayChanges.isNotEmpty) {
      final c = plan.stayChanges.length;
      parts.add('$c stay${c > 1 ? 's' : ''}');
    }
    if (plan.sightChanges.isNotEmpty) {
      final c = plan.sightChanges.length;
      parts.add('$c sight${c > 1 ? 's' : ''}');
    }
    if (parts.isEmpty) return 'No items affected.';

    final prefix = context == MessageContext.metadataUpdate
        ? 'Found ${parts.join(', ')} affected by date changes.'
        : 'Found ${parts.join(', ')} with conflicting times.';
    return '$prefix Review below.';
  }

  String buildActionMessage() => context == MessageContext.metadataUpdate
      ? 'Items without valid dates will be deleted. Update times or tap restore.'
      : 'Resolve conflicts by updating times or deleting items.';
}

/// Represents an informational message with a title and details
class EntityChangeInfoMessage {
  final String title;
  final String details;

  const EntityChangeInfoMessage({required this.title, required this.details});
}
