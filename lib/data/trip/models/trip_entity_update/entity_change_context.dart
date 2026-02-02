/// Represents the context in which an entity change is being displayed/edited
enum EntityChangeContext {
  /// Entity affected by trip metadata changes (dates or contributors)
  tripMetadataUpdate,

  /// Entity conflicts with another entity being created/edited
  timelineConflict,
}
