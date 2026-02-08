# Consolidated Conflict Detection in TripConflictScanner

## Summary

All conflict detection logic is now unified in `TripConflictScanner`. The separate
`TripMetadataUpdatePlanFactory` has been removed.

## Changes Made

### 1. `TripConflictScanner` - Added metadata update scanning

**File:** `lib/data/trip/services/conflict_detection/trip_conflict_scanner.dart`

Added new method that scans for entities affected by trip date/contributor changes:

```dart
/// Scans for entities affected by trip metadata changes (date/contributor changes).
MetadataUpdateConflicts? scanForMetadataUpdate({
  required TripMetadataFacade oldMetadata,
  required TripMetadataFacade newMetadata,
}) {
  // Uses same pattern as scanForConflicts()
  // Returns MetadataUpdateConflicts with stays/transits/sights + expense entities
}
```

Added helper methods:

- `_findStaysOutsideDateRange()` - Finds stays outside new trip date range
- `_findTransitsOutsideDateRange()` - Finds transits outside new trip date range
- `_findSightsOutsideDateRange()` - Finds sights outside new trip date range
- `_collectAllExpenseBearingEntities()` - Collects all entities for contributor split updates
- `_haveContributorsChanged()` - Checks if contributors changed

### 2. `conflict_result.dart` - Added MetadataUpdateConflicts

**File:** `lib/data/trip/services/conflict_detection/conflict_result.dart`

```dart
class MetadataUpdateConflicts extends AggregatedConflicts {
  final List<ExpenseBearingTripEntity> expenseEntities;
  final TripMetadataFacade oldMetadata;
  final TripMetadataFacade newMetadata;

  Iterable<String> get addedContributors =>

  ...;

  Iterable<String> get removedContributors =>

  ...;

  bool get hasContributorChanges =>

  ...;

  bool get hasDateChanges =>

  ...;
}
```

### 3. `EntityTimeClamper` - Added date range clamping

**File:** `lib/data/trip/services/conflict_detection/entity_time_clamper.dart`

```dart
/// Clamps a stay to fit within a new trip date range.
static LodgingFacade? clampStayToDateRange
(LodgingFacade stay, TimeRange newTripRange)
```

### 4. `ConflictToEntityChangeAdapter` - Added metadata conversion

**File:**
`lib/presentation/trip/pages/trip_editor/conflict_resolution/conflict_to_entity_change_adapter.dart`

```dart
/// Converts MetadataUpdateConflicts to a TripMetadataUpdatePlan.
static TripMetadataUpdatePlan toMetadataUpdatePlan
(
MetadataUpdateConflicts
conflicts
)
```

### 5. `EntityConflictCoordinator` - Updated to use scanner

**File:**
`lib/presentation/trip/pages/trip_editor/conflict_resolution/entity_conflict_coordinator.dart`

```dart
TripMetadataUpdatePlan? detectTripMetadataConflicts(TripMetadataFacade editedMetadata) {
  final conflicts = _scanner.scanForMetadataUpdate(
    oldMetadata: _tripData.tripMetadata,
    newMetadata: editedMetadata,
  );
  if (conflicts == null) return null;
  return ConflictToEntityChangeAdapter.toMetadataUpdatePlan(conflicts);
}
```

### 6. Deleted Files

-
`lib/presentation/trip/pages/trip_editor/trip_details/affected_entities/trip_metadata_update_plan_factory.dart`

## Architecture After Refactoring

```
TripConflictScanner (Data Layer)
├── scanForConflicts()         - For Transit/Stay/Sight time conflicts
├── scanForMetadataUpdate()    - For TripMetadata date/contributor changes
├── scanTransitConflicts()     - Individual transit scanning
├── scanStayConflicts()        - Individual stay scanning  
└── scanSightConflicts()       - Individual sight scanning

     ↓ Returns raw conflict data

ConflictToEntityChangeAdapter (Presentation Layer)
├── toUpdatePlan()             - Converts AggregatedConflicts → TripDataUpdatePlan
└── toMetadataUpdatePlan()     - Converts MetadataUpdateConflicts → TripMetadataUpdatePlan

     ↓ Returns UI-ready EntityChange objects

EntityConflictCoordinator (Presentation Layer)
├── detectTripMetadataConflicts()  - Uses scanner + adapter
├── detectStayConflicts()          - Uses detector + adapter
├── detectJourneyConflicts()       - Uses detector + adapter
└── detectItineraryConflicts()     - Uses detector + adapter
```

## Benefits

1. **Single source of truth** - All conflict detection in `TripConflictScanner`
2. **Consistent pattern** - Metadata updates use same structure as entity conflicts
3. **Separation of concerns** - Data layer scans, presentation layer adapts to UI
4. **Reusable clamping logic** - `EntityTimeClamper` handles all time adjustments
