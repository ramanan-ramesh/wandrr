import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Types of timeline entities that can have conflicts
enum TimelineEntityType {
  transit,
  stay,
  sight,
}

/// Represents a conflict between the entity being edited and existing timeline entities
class TimelineConflict<T extends ExpenseBearingTripEntity> {
  /// The conflicting entity
  final T conflictingEntity;

  /// Type of the entity
  final TimelineEntityType entityType;

  /// Description of the conflict
  final String description;

  /// The time range of the conflict
  final DateTime conflictStart;
  final DateTime conflictEnd;

  TimelineConflict({
    required this.conflictingEntity,
    required this.entityType,
    required this.description,
    required this.conflictStart,
    required this.conflictEnd,
  });
}

/// Holds all conflicts detected for a timeline change
class TimelineConflictPlan {
  /// The entity being edited that caused the conflicts
  final ExpenseBearingTripEntity sourceEntity;

  /// Whether it's a new entity or an existing one being edited
  final bool isNewEntity;

  /// Conflicting transits
  final List<EntityConflictChange<TransitFacade>> transitConflicts;

  /// Conflicting stays
  final List<EntityConflictChange<LodgingFacade>> stayConflicts;

  /// Conflicting sights
  final List<EntityConflictChange<SightFacade>> sightConflicts;

  TimelineConflictPlan({
    required this.sourceEntity,
    required this.isNewEntity,
    List<EntityConflictChange<TransitFacade>>? transitConflicts,
    List<EntityConflictChange<LodgingFacade>>? stayConflicts,
    List<EntityConflictChange<SightFacade>>? sightConflicts,
  })  : transitConflicts = transitConflicts ?? [],
        stayConflicts = stayConflicts ?? [],
        sightConflicts = sightConflicts ?? [];

  /// Whether there are any conflicts
  bool get hasConflicts =>
      transitConflicts.isNotEmpty ||
      stayConflicts.isNotEmpty ||
      sightConflicts.isNotEmpty;

  /// Total number of conflicts
  int get totalConflicts =>
      transitConflicts.length + stayConflicts.length + sightConflicts.length;

  /// Get all conflicting expenses for deletion sync
  Iterable<ExpenseBearingTripEntity> get allConflictingEntities sync* {
    for (final c in transitConflicts) {
      yield c.entity;
    }
    for (final c in stayConflicts) {
      yield c.entity;
    }
    for (final c in sightConflicts) {
      yield c.entity;
    }
  }
}

/// Represents a conflicting entity and how to resolve it
class EntityConflictChange<T extends ExpenseBearingTripEntity> {
  /// The original entity before any modifications
  final T originalEntity;

  /// The entity with proposed changes (clamped times, etc.)
  T modifiedEntity;

  /// Whether to delete this entity
  bool isMarkedForDeletion;

  /// Description of the conflict
  final String conflictDescription;

  /// Original time info for display
  final String originalTimeDescription;

  EntityConflictChange({
    required this.originalEntity,
    required this.modifiedEntity,
    required this.conflictDescription,
    required this.originalTimeDescription,
    this.isMarkedForDeletion = true, // Default to deletion
  });

  T get entity => modifiedEntity;

  void markForDeletion() {
    isMarkedForDeletion = true;
  }

  void restore() {
    isMarkedForDeletion = false;
  }
}
