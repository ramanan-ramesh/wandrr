import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';

/// Context for entity change messages
enum MessageContext { metadataUpdate, timelineConflict }

/// Provides context-aware messages for entity changes.
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
          ? 'Stays ($count)'
          : 'Conflicting Stays ($count)';

  String transitsSectionTitle(int count) =>
      context == MessageContext.metadataUpdate
          ? 'Transits ($count)'
          : 'Conflicting Transits ($count)';

  String sightsSectionTitle(int count) =>
      context == MessageContext.metadataUpdate
          ? 'Sights ($count)'
          : 'Conflicting Sights ($count)';

  String expensesSectionTitle(int count) => 'Expenses ($count)';

  // =========================================================================
  // Section Info Messages
  // =========================================================================

  EntityChangeInfoMessage staysSectionInfo() =>
      context == MessageContext.metadataUpdate
          ? const EntityChangeInfoMessage(
              title: 'These stays fall outside the new trip dates',
              details: 'Adjust dates or delete',
            )
          : const EntityChangeInfoMessage(
              title: 'These stays overlap with your selected times',
              details: 'Adjust dates or delete',
            );

  EntityChangeInfoMessage transitsSectionInfo() =>
      context == MessageContext.metadataUpdate
          ? const EntityChangeInfoMessage(
              title: 'These transits fall outside the new trip dates',
              details: 'Adjust times or delete',
            )
          : const EntityChangeInfoMessage(
              title: 'These transits have conflicting times',
              details: 'Adjust times or delete',
            );

  EntityChangeInfoMessage sightsSectionInfo() =>
      context == MessageContext.metadataUpdate
          ? const EntityChangeInfoMessage(
              title: 'These sights fall outside the new trip dates',
              details: 'Adjust visit time or delete',
            )
          : const EntityChangeInfoMessage(
              title: 'These sights have conflicting visit times',
              details: 'Adjust visit time or delete',
            );

  EntityChangeInfoMessage expensesSectionInfo({
    Iterable<String> addedContributors = const [],
    Iterable<String> removedContributors = const [],
  }) {
    final parts = <String>[];
    if (addedContributors.isNotEmpty) {
      parts.add('Added: ${addedContributors.join(", ")}');
    }
    if (removedContributors.isNotEmpty) {
      parts.add('Removed: ${removedContributors.join(", ")} (preserved)');
    }
    return EntityChangeInfoMessage(
      title: 'Review expense splits',
      details:
          parts.isNotEmpty ? parts.join(' • ') : 'Select expenses to include',
    );
  }

  // =========================================================================
  // Summary Messages
  // =========================================================================

  String buildSummaryMessage(TripDataUpdatePlan plan) {
    final parts = <String>[];
    if (plan.transitChanges.isNotEmpty) {
      parts.add('${plan.transitChanges.length} transit(s)');
    }
    if (plan.stayChanges.isNotEmpty) {
      parts.add('${plan.stayChanges.length} stay(s)');
    }
    if (plan.sightChanges.isNotEmpty) {
      parts.add('${plan.sightChanges.length} sight(s)');
    }
    if (parts.isEmpty) {
      return 'No conflicts.';
    }
    return parts.join(', ');
  }
}

/// Represents an informational message with a title and details
class EntityChangeInfoMessage {
  final String title;
  final String details;

  const EntityChangeInfoMessage({required this.title, required this.details});
}
