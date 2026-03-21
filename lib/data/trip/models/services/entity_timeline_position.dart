/// Represents the temporal relationship between an entity and a reference time range.
enum EntityTimelinePosition {
  exactBoundaryMatch,

  /// Entity's time is completely before the reference time range
  beforeEvent,

  /// Entity's time is completely after the reference time range
  afterEvent,

  /// Entity's time is contained within the reference time range
  containedIn,

  /// Reference time is completely contained within the entity's time range
  contains,

  /// Entity's time overlaps the start boundary of the reference time range
  startsBeforeEndsDuring,

  /// Entity's time overlaps the end boundary of the reference time range
  startsDuringEndsAfter,

  /// Entity overlaps with another entity of the same type (intra-day)
  isOverlapping,
}
