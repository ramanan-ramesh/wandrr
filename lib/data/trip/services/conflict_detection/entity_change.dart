import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/services/conflict_detection/entity_timeline_position.dart';

/// Action to perform on an entity
enum ChangeAction { update, delete }

/// Base class for entity changes
abstract class EntityChangeBase<T extends TripEntity<Enum>> {
  final T original;
  T modified;
  ChangeAction action;

  /// Whether times were auto-clamped to resolve conflict
  bool isClamped;

  EntityChangeBase({
    required this.original,
    required this.modified,
    this.action = ChangeAction.update,
    this.isClamped = false,
  });

  bool get isDelete => action == ChangeAction.delete;

  bool get isMarkedForDeletion => action == ChangeAction.delete;

  /// A conflict is resolved if it's clamped OR marked for deletion
  bool get isResolved => isClamped || isMarkedForDeletion;

  void markAsResolved() => isClamped = true;

  void markForDeletion() => action = ChangeAction.delete;

  void restore() => action = ChangeAction.update;
}

/// Change for entities with date/time conflicts (stays, transits, sights)
class DateTimeChange<T extends TripEntity<Enum>> extends EntityChangeBase<T> {
  /// Position relative to reference time range
  final EntityTimelinePosition? timelinePosition;

  DateTimeChange.forDeletion({
    required T original,
    this.timelinePosition,
  }) : super(
          original: original,
          modified: original,
          action: ChangeAction.delete,
          isClamped: false,
        );

  DateTimeChange.forClamping({
    required super.original,
    required super.modified,
    this.timelinePosition,
  }) : super(
          action: ChangeAction.update,
          isClamped: true,
        );

  /// Equality based on entity ID, action flags, and type-specific modified times.
  ///
  /// **Warning:** [modified] is mutable — do not use instances as Map keys or
  /// Set members after mutating the modified entity.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DateTimeChange<T>) {
      return false;
    }
    if (original.id != other.original.id) {
      return false;
    }
    if (isDelete != other.isDelete) {
      return false;
    }
    if (isClamped != other.isClamped) {
      return false;
    }
    return _modifiedTimeEquals(other);
  }

  @override
  int get hashCode => Object.hash(original.id, isDelete, isClamped);

  bool _modifiedTimeEquals(DateTimeChange<T> other) {
    final m = modified;
    final om = other.modified;
    if (m is LodgingFacade && om is LodgingFacade) {
      return m.checkinDateTime == om.checkinDateTime &&
          m.checkoutDateTime == om.checkoutDateTime;
    }
    if (m is TransitFacade && om is TransitFacade) {
      return m.departureDateTime == om.departureDateTime &&
          m.arrivalDateTime == om.arrivalDateTime;
    }
    if (m is SightFacade && om is SightFacade) {
      return m.visitTime == om.visitTime;
    }
    return true;
  }
}

/// Change for expense split updates (when contributors change)
class ExpenseSplitChange
    extends EntityChangeBase<ExpenseBearingTripEntity<Enum>> {
  /// Whether to include new contributors in splitBy for this expense
  bool includeInSplitBy;

  ExpenseSplitChange({
    required super.original,
    required super.modified,
    this.includeInSplitBy = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ExpenseSplitChange) {
      return false;
    }
    return original.id == other.original.id &&
        isDelete == other.isDelete &&
        isClamped == other.isClamped &&
        includeInSplitBy == other.includeInSplitBy;
  }

  @override
  int get hashCode =>
      Object.hash(original.id, isDelete, isClamped, includeInSplitBy);
}

/// Type aliases for cleaner API
typedef StayChange = DateTimeChange<LodgingFacade>;
typedef TransitChange = DateTimeChange<TransitFacade>;
typedef SightChange = DateTimeChange<SightFacade>;
