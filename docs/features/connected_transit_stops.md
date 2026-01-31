# Feature: Connected Transit Stops (Multi-Leg Journeys)

## Overview

Implement support for multi-leg transit journeys where a single trip consists of multiple connected
stops. For example, a flight journey from New York → London → Paris should be represented as a
connected journey with two legs, each with its own editable properties.

## Current State

Currently, `TransitFacade` represents a single point-to-point journey with:

- Single departure/arrival locations
- Single departure/arrival date-times
- Single expense
- Single confirmation ID
- Single operator
- Single transit option (flight, train, etc.)

## Proposed Solution

### 1. Data Model Changes

#### 1.1 Rename `TransitFacade` → `TransitLegFacade`

The existing `TransitFacade` becomes `TransitLegFacade` with one new field:

```dart
/// Represents a single transit leg (the actual DB entity)
/// Can be standalone or part of a multi-leg journey
class TransitLegFacade extends Equatable
    implements ExpenseBearingTripEntity<TransitLegFacade> {
  final String tripId;
  
  @override
  String? id;
  
  /// If set, this leg is part of a multi-leg journey
  /// All legs with the same journeyId are connected
  String? journeyId;
  
  TransitOption transitOption;
  LocationFacade? departureLocation;
  DateTime? departureDateTime;
  LocationFacade? arrivalLocation;
  DateTime? arrivalDateTime;
  String? operator;
  String? confirmationId;
  String? notes;
  
  @override
  ExpenseFacade expense;
  
  /// Whether this leg is part of a multi-leg journey
  bool get isPartOfJourney => journeyId != null;
  
  // ... existing constructors, clone, validate methods
}
```

#### 1.2 New `TransitJourneyFacade` (Read-only aggregation)

A lightweight facade for representing a grouped journey in UI:

```dart
/// Read-only representation of a multi-leg journey
/// Created by grouping TransitLegFacade items by journeyId
/// Not stored in DB - purely for UI/business logic
class TransitJourneyFacade {
  final String journeyId;
  final String tripId;
  
  /// Legs sorted by departureDateTime (ascending)
  final List<TransitLegFacade> legs;
  
  TransitJourneyFacade({
    required this.journeyId,
    required this.tripId,
    required List<TransitLegFacade> unsortedLegs,
  }) : legs = List.from(unsortedLegs)
         ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
             .compareTo(b.departureDateTime ?? DateTime(0)));
  
  // Convenience getters
  TransitLegFacade get firstLeg => legs.first;
  TransitLegFacade get lastLeg => legs.last;
  
  LocationFacade? get departureLocation => firstLeg.departureLocation;
  DateTime? get departureDateTime => firstLeg.departureDateTime;
  LocationFacade? get arrivalLocation => lastLeg.arrivalLocation;
  DateTime? get arrivalDateTime => lastLeg.arrivalDateTime;
  
  /// All intermediate stops (arrival locations except the last)
  List<LocationFacade?> get intermediateStops =>
      legs.take(legs.length - 1).map((l) => l.arrivalLocation).toList();
  
  /// Total expense across all legs
  Money get totalExpense => legs.fold(
    Money.zero(legs.first.expense.currency),
    (sum, leg) => sum + leg.expense.totalExpense,
  );
  
  /// Validates all legs and their time sequence
  bool validate() {
    if (legs.isEmpty) return false;
    if (!legs.every((leg) => leg.validate())) return false;
    
    // Validate time sequence: each leg's arrival must be before next leg's departure
    for (var i = 0; i < legs.length - 1; i++) {
      final currentArrival = legs[i].arrivalDateTime;
      final nextDeparture = legs[i + 1].departureDateTime;
      if (currentArrival == null || nextDeparture == null) continue;
      if (currentArrival.isAfter(nextDeparture)) return false;
    }
    return true;
  }
  
  /// Get validation errors for display
  List<JourneyValidationError> getValidationErrors() {
    final errors = <JourneyValidationError>[];
    
    for (var i = 0; i < legs.length; i++) {
      if (!legs[i].validate()) {
        errors.add(JourneyValidationError.legInvalid(legIndex: i));
      }
    }
    
    for (var i = 0; i < legs.length - 1; i++) {
      final currentArrival = legs[i].arrivalDateTime;
      final nextDeparture = legs[i + 1].departureDateTime;
      if (currentArrival != null && nextDeparture != null && 
          currentArrival.isAfter(nextDeparture)) {
        errors.add(JourneyValidationError.timeSequenceError(
          fromLegIndex: i,
          toLegIndex: i + 1,
        ));
      }
    }
    
    return errors;
  }
}

/// Validation error types for journey
sealed class JourneyValidationError {
  const JourneyValidationError();
  
  factory JourneyValidationError.legInvalid({required int legIndex}) = 
      LegInvalidError;
  factory JourneyValidationError.timeSequenceError({
    required int fromLegIndex,
    required int toLegIndex,
  }) = TimeSequenceError;
}

class LegInvalidError extends JourneyValidationError {
  final int legIndex;
  const LegInvalidError({required this.legIndex});
}

class TimeSequenceError extends JourneyValidationError {
  final int fromLegIndex;
  final int toLegIndex;
  const TimeSequenceError({
    required this.fromLegIndex,
    required this.toLegIndex,
  });
}
```

#### 1.3 Database Schema

Each leg is stored as its own document. The `journeyId` field links legs together:

```
trips/{tripId}/transit/{legId}
  - journeyId: "journey_abc123" | null  // null = standalone leg
  - transitOption: "flight"
  - departureLocation: {...}
  - departureDateTime: Timestamp
  - arrivalLocation: {...}
  - arrivalDateTime: Timestamp
  - operator: "AA 123 Boeing 777"
  - confirmationId: "ABC123"
  - notes: "Window seat"
  - totalExpense: {...}
```

**Note**: No `legIndex` field - legs are sorted by `departureDateTime` at runtime.

### 2. Repository/Service Layer Changes

#### 2.1 TransitLegCollection (renamed from TransitCollection)

```dart
/// Manages individual transit legs in the database
class TransitLegCollection implements ModelCollectionModifier<TransitLegFacade> {
  // ... existing CRUD operations for individual legs
  
  @override
  List<TransitLegFacade> get collectionItems;
}
```

#### 2.2 New TransitJourneyService

Following Single Responsibility Principle - separate service for journey operations:

```dart
/// Service for managing multi-leg journeys
/// Handles grouping, validation, and batch operations
abstract class TransitJourneyServiceFacade {
  /// Get all standalone legs (no journeyId)
  List<TransitLegFacade> get standalonelegs;
  
  /// Get all grouped journeys
  List<TransitJourneyFacade> get journeys;
  
  /// Get a specific journey by ID
  TransitJourneyFacade? getJourney(String journeyId);
  
  /// Get all legs for a journey
  List<TransitLegFacade> getLegsForJourney(String journeyId);
}

class TransitJourneyService implements TransitJourneyServiceFacade {
  final ModelCollectionFacade<TransitLegFacade> _legCollection;
  
  TransitJourneyService(this._legCollection);
  
  @override
  List<TransitLegFacade> get standaloneLegs =>
      _legCollection.collectionItems
          .where((leg) => leg.journeyId == null)
          .toList();
  
  @override
  List<TransitJourneyFacade> get journeys {
    final grouped = <String, List<TransitLegFacade>>{};
    
    for (final leg in _legCollection.collectionItems) {
      if (leg.journeyId != null) {
        grouped.putIfAbsent(leg.journeyId!, () => []).add(leg);
      }
    }
    
    return grouped.entries
        .map((e) => TransitJourneyFacade(
              journeyId: e.key,
              tripId: e.value.first.tripId,
              unsortedLegs: e.value,
            ))
        .toList();
  }
  
  @override
  TransitJourneyFacade? getJourney(String journeyId) {
    final legs = getLegsForJourney(journeyId);
    if (legs.isEmpty) return null;
    return TransitJourneyFacade(
      journeyId: journeyId,
      tripId: legs.first.tripId,
      unsortedLegs: legs,
    );
  }
  
  @override
  List<TransitLegFacade> getLegsForJourney(String journeyId) =>
      _legCollection.collectionItems
          .where((leg) => leg.journeyId == journeyId)
          .toList();
}
```

#### 2.3 Bloc Events (Using Existing Pattern)

No new event types needed. Use existing `UpdateTripEntity<TransitLegFacade>` events:

```dart
// Create a new standalone leg
UpdateTripEntity<TransitLegFacade>.create(tripEntity: leg)

// Update a leg (including adding/changing journeyId)
UpdateTripEntity<TransitLegFacade>.update(tripEntity: leg)

// Delete a leg
UpdateTripEntity<TransitLegFacade>.delete(tripEntity: leg)
```

**Journey Management Logic:**

1. **Single leg (standalone)**: `journeyId` is `null`, no journey grouping
2. **Convert to multi-leg journey**:
    - Generate new `journeyId` (UUID)
    - Update existing leg with `journeyId`
    - Create new leg with same `journeyId`
    - Dispatch `UpdateTripEntity.update()` for existing leg
    - Dispatch `UpdateTripEntity.create()` for new leg
3. **Add leg to existing journey**:
    - Create new leg with existing `journeyId`
    - Dispatch `UpdateTripEntity.create()`
4. **Remove leg from journey**:
    - If journey has 2 legs → remove `journeyId` from remaining leg (becomes standalone)
    - If journey has 3+ legs → just delete the leg
    - Dispatch `UpdateTripEntity.delete()` and optionally `UpdateTripEntity.update()` for remaining
      leg
5. **Delete entire journey**:
    - Dispatch `UpdateTripEntity.delete()` for each leg

### 3. UI Changes

#### 3.1 JourneyEditor (New - replaces TravelEditor for journeys)

Single page for editing entire journey with collapsible leg sections:

```dart
/// Editor for multi-leg journeys
/// Shows collapsible sections for each leg with journey overview
class JourneyEditor extends StatefulWidget {
  final TransitJourneyFacade journey;
  final VoidCallback onJourneyUpdated;
  
  const JourneyEditor({
    required this.journey,
    required this.onJourneyUpdated,
    super.key,
  });
  
  @override
  State<JourneyEditor> createState() => _JourneyEditorState();
}

class _JourneyEditorState extends State<JourneyEditor> {
  late List<bool> _expandedStates;
  
  @override
  void initState() {
    super.initState();
    // First leg expanded by default
    _expandedStates = List.generate(
      widget.journey.legs.length,
      (i) => i == 0,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact journey overview at top
        JourneyRouteHeader(journey: widget.journey),
        
        // Validation errors banner (if any)
        if (!widget.journey.validate())
          JourneyValidationBanner(
            errors: widget.journey.getValidationErrors(),
            onErrorTap: _expandLegWithError,
          ),
        
        // Scrollable list of collapsible leg editors
        Expanded(
          child: ListView.builder(
            itemCount: widget.journey.legs.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == widget.journey.legs.length) {
                return _buildAddLegButton();
              }
              return _buildCollapsibleLegEditor(index);
            },
          ),
        ),
        
        // Journey summary footer
        JourneySummaryFooter(journey: widget.journey),
      ],
    );
  }
  
  Widget _buildCollapsibleLegEditor(int index) {
    final leg = widget.journey.legs[index];
    final isExpanded = _expandedStates[index];
    final isFirst = index == 0;
    final isLast = index == widget.journey.legs.length - 1;
    
    return CollapsibleLegSection(
      leg: leg,
      legNumber: index + 1,
      isExpanded: isExpanded,
      isFirst: isFirst,
      isLast: isLast,
      previousLeg: isFirst ? null : widget.journey.legs[index - 1],
      onToggle: () => _toggleLegExpansion(index),
      onLegUpdated: widget.onJourneyUpdated,
      onRemoveLeg: () => _removeLeg(index),
    );
  }
}
```

#### 3.2 JourneyRouteHeader (Compact Overview)

Space-efficient header showing the full route:

```dart
/// Compact visual representation of the journey route
/// Shows: [City] ──✈──> [City] ──✈──> [City]
///         10:00       14:00→15:30    19:00
class JourneyRouteHeader extends StatelessWidget {
  final TransitJourneyFacade journey;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(/* brand colors */),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Route line: Cities with icons between
          _buildRouteLine(context),
          const SizedBox(height: 8),
          // Times row
          _buildTimesRow(context),
        ],
      ),
    );
  }
  
  Widget _buildRouteLine(BuildContext context) {
    final widgets = <Widget>[];
    
    for (var i = 0; i < journey.legs.length; i++) {
      final leg = journey.legs[i];
      
      // Add departure city (only for first leg)
      if (i == 0) {
        widgets.add(_CityChip(
          city: _getCityName(leg.departureLocation),
          isOrigin: true,
        ));
      }
      
      // Add transit icon with connection line
      widgets.add(_ConnectionLine(
        icon: _getTransitIcon(leg.transitOption),
        duration: _formatDuration(leg.departureDateTime, leg.arrivalDateTime),
      ));
      
      // Add arrival city
      widgets.add(_CityChip(
        city: _getCityName(leg.arrivalLocation),
        isOrigin: false,
        isDestination: i == journey.legs.length - 1,
      ));
      
      // Add layover indicator (if not last leg)
      if (i < journey.legs.length - 1) {
        final layover = _calculateLayover(
          leg.arrivalDateTime,
          journey.legs[i + 1].departureDateTime,
        );
        if (layover != null) {
          widgets.add(_LayoverIndicator(duration: layover));
        }
      }
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }
  
  /// Get city name, preferring city over location name
  String _getCityName(LocationFacade? location) {
    if (location == null) return '?';
    // Priority: city > name > formatted address
    return location.city ?? 
           location.name ?? 
           location.formattedAddress?.split(',').first ?? 
           '?';
  }
}

/// Compact city chip for route display
class _CityChip extends StatelessWidget {
  final String city;
  final bool isOrigin;
  final bool isDestination;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOrigin || isDestination
            ? AppColors.brandPrimary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOrigin || isDestination
              ? AppColors.brandPrimary
              : Colors.grey.shade400,
        ),
      ),
      child: Text(
        city,
        style: TextStyle(
          fontWeight: isOrigin || isDestination 
              ? FontWeight.bold 
              : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Connection line with transit icon
class _ConnectionLine extends StatelessWidget {
  final IconData icon;
  final String? duration;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 16, height: 1, color: Colors.grey),
              Icon(icon, size: 16, color: AppColors.info),
              Container(width: 16, height: 1, color: Colors.grey),
            ],
          ),
          if (duration != null)
            Text(
              duration!,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

/// Layover indicator between legs
class _LayoverIndicator extends StatelessWidget {
  final Duration duration;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${duration.inHours}h ${duration.inMinutes % 60}m',
        style: TextStyle(
          fontSize: 9,
          color: AppColors.warning,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
```

#### 3.3 CollapsibleLegSection

Individual leg editor wrapped in expandable section:

```dart
/// Collapsible section for editing a single leg
class CollapsibleLegSection extends StatelessWidget {
  final TransitLegFacade leg;
  final int legNumber;
  final bool isExpanded;
  final bool isFirst;
  final bool isLast;
  final TransitLegFacade? previousLeg;
  final VoidCallback onToggle;
  final VoidCallback onLegUpdated;
  final VoidCallback onRemoveLeg;
  
  @override
  Widget build(BuildContext context) {
    final isValid = leg.validate();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.grey.shade300 : AppColors.error,
          width: isValid ? 1 : 2,
        ),
      ),
      child: Column(
        children: [
          // Header (always visible) - tap to expand/collapse
          _LegSectionHeader(
            leg: leg,
            legNumber: legNumber,
            isExpanded: isExpanded,
            isValid: isValid,
            onToggle: onToggle,
            onRemove: isFirst && isLast ? null : onRemoveLeg,
          ),
          
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _LegEditorContent(
              leg: leg,
              previousLeg: previousLeg,
              onLegUpdated: onLegUpdated,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Collapsed header showing leg summary
class _LegSectionHeader extends StatelessWidget {
  final TransitLegFacade leg;
  final int legNumber;
  final bool isExpanded;
  final bool isValid;
  final VoidCallback onToggle;
  final VoidCallback? onRemove;
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Leg number badge
            _LegNumberBadge(number: legNumber, isValid: isValid),
            const SizedBox(width: 12),
            
            // Route summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getCityName(leg.departureLocation)} → ${_getCityName(leg.arrivalLocation)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatLegTimes(leg),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Transit option icon
            Icon(
              _getTransitIcon(leg.transitOption),
              color: AppColors.info,
              size: 20,
            ),
            const SizedBox(width: 8),
            
            // Remove button (if allowed)
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                tooltip: 'Remove leg',
              ),
            
            // Expand/collapse indicator
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatLegTimes(TransitLegFacade leg) {
    final dep = leg.departureDateTime?.hourMinuteAmPmFormat ?? '--:--';
    final arr = leg.arrivalDateTime?.hourMinuteAmPmFormat ?? '--:--';
    final date = leg.departureDateTime?.dayDateMonthFormat ?? '';
    return '$date • $dep → $arr';
  }
}

/// Leg number badge with validation indicator
class _LegNumberBadge extends StatelessWidget {
  final int number;
  final bool isValid;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isValid ? AppColors.brandPrimary : AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isValid
            ? Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
            : const Icon(Icons.error, color: Colors.white, size: 16),
      ),
    );
  }
}
```

#### 3.4 Timeline Display Changes

Update timeline to show connected legs efficiently:

```dart
/// Enhanced timeline event for connected journeys
class ConnectedTransitTimelineEvent extends TimelineEvent<TransitLegFacade> {
  final String journeyId;
  final ConnectionPosition position;
  final String? layoverDuration; // Only for middle/end positions
  
  ConnectedTransitTimelineEvent({
    required super.time,
    required super.title,
    required super.subtitle,
    required super.icon,
    required super.iconColor,
    required super.data,
    required this.journeyId,
    required this.position,
    this.layoverDuration,
    super.notes,
    super.confirmationId,
  });
}

enum ConnectionPosition { start, middle, end, standalone }

/// Timeline widget with connection indicators
class ConnectedTimelineItemWidget extends StatelessWidget {
  final ConnectedTransitTimelineEvent event;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Incoming connection line (for middle/end)
        if (event.position == ConnectionPosition.middle ||
            event.position == ConnectionPosition.end)
          _buildConnectionLine(showLayover: event.layoverDuration != null),
        
        // The actual event card
        _buildCompactTransitCard(context),
        
        // Outgoing connection line (for start/middle)
        if (event.position == ConnectionPosition.start ||
            event.position == ConnectionPosition.middle)
          _buildConnectionLine(showLayover: false),
      ],
    );
  }
  
  Widget _buildCompactTransitCard(BuildContext context) {
    // Compact card showing:
    // [Icon] NYC → LHR | 10:00 → 18:00 | AA 123
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getBackgroundColor(event.position),
        borderRadius: _getBorderRadius(event.position),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(event.icon, size: 18, color: event.iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title, // "NYC → LHR"
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  event.subtitle, // "10:00 → 18:00 • AA 123"
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Tap to edit
          Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
  
  Widget _buildConnectionLine({required bool showLayover}) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          // Vertical dotted line
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.info,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
          // Layover duration (if applicable)
          if (showLayover && event.layoverDuration != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Layover: ${event.layoverDuration}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  BorderRadius _getBorderRadius(ConnectionPosition position) {
    const radius = Radius.circular(8);
    switch (position) {
      case ConnectionPosition.start:
        return const BorderRadius.only(topLeft: radius, topRight: radius);
      case ConnectionPosition.middle:
        return BorderRadius.zero;
      case ConnectionPosition.end:
        return const BorderRadius.only(bottomLeft: radius, bottomRight: radius);
      case ConnectionPosition.standalone:
        return BorderRadius.circular(8);
    }
  }
}
```

#### 3.5 Updated TimelineEventFactory

```dart
/// Creates timeline events, grouping connected journeys
Iterable<TimelineEvent> _createTransitEvents(
  Iterable<TransitLegFacade> legs,
  TransitJourneyService journeyService,
) sync* {
  // Process standalone legs
  for (final leg in journeyService.standaloneLegs) {
    yield _createSingleLegEvent(leg);
  }
  
  // Process journeys (grouped legs)
  for (final journey in journeyService.journeys) {
    yield* _createJourneyEvents(journey);
  }
}

Iterable<TimelineEvent> _createJourneyEvents(
  TransitJourneyFacade journey,
) sync* {
  for (var i = 0; i < journey.legs.length; i++) {
    final leg = journey.legs[i];
    final isFirst = i == 0;
    final isLast = i == journey.legs.length - 1;
    
    String? layoverDuration;
    if (!isFirst) {
      final prevLeg = journey.legs[i - 1];
      layoverDuration = _calculateLayoverString(
        prevLeg.arrivalDateTime,
        leg.departureDateTime,
      );
    }
    
    yield ConnectedTransitTimelineEvent(
      time: leg.departureDateTime ?? DateTime.now(),
      title: '${_getCityName(leg.departureLocation)} → ${_getCityName(leg.arrivalLocation)}',
      subtitle: _formatTimeRange(leg) + _formatOperator(leg),
      icon: _getTransitIcon(leg.transitOption),
      iconColor: AppColors.info,
      data: leg,
      journeyId: journey.journeyId,
      position: isFirst
          ? ConnectionPosition.start
          : (isLast ? ConnectionPosition.end : ConnectionPosition.middle),
      layoverDuration: layoverDuration,
      notes: leg.notes,
      confirmationId: leg.confirmationId,
    );
  }
}
```

### 4. Migration Strategy

#### 4.1 Backward Compatibility

Existing transits work without changes:

- `journeyId` defaults to `null` (standalone leg)
- All existing functionality remains for standalone legs
- UI detects standalone vs journey based on `journeyId`

#### 4.2 Rename Migration

Rename `TransitFacade` → `TransitLegFacade` across codebase:

- Update all imports and references
- No database changes needed (just add nullable `journeyId` field)

### 5. Affected Files

#### Data Layer

- `lib/data/trip/models/transit.dart` - Added `journeyId` field ✅
- `lib/data/trip/models/transit_journey.dart` - New file for `TransitJourneyFacade` ✅
- `lib/data/trip/implementations/transit.dart` - Updated for `journeyId` serialization ✅
- `lib/data/trip/services/transit_journey_service.dart` - New service ✅

#### Presentation Layer

- `lib/presentation/trip/pages/trip_editor/transit/journey_editor.dart` - New file ✅
- `lib/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart` - Added
  `ConnectedTransitTimelineEvent` ✅
- `lib/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_event_factory.dart` - Journey
  grouping ✅
- `lib/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item_widget.dart` - Connection
  UI ✅

#### Bloc

- No new event types needed - uses existing `UpdateTripEntity<TransitFacade>` events ✅

### 6. SOLID Principles Applied

1. **Single Responsibility**
    - `TransitLegFacade`: Represents a single leg (DB entity)
    - `TransitJourneyFacade`: Groups legs into journey (read-only)
    - `TransitJourneyService`: Handles grouping logic
    - `JourneyEditor`: Handles UI for editing journeys
    - `CollapsibleLegSection`: Handles individual leg UI

2. **Open/Closed**
    - Timeline events extensible via `ConnectedTransitTimelineEvent`
    - Validation extensible via sealed `JourneyValidationError`

3. **Liskov Substitution**
    - `ConnectedTransitTimelineEvent` extends `TimelineEvent<TransitLegFacade>`
    - All leg operations work the same for journey legs and standalone legs

4. **Interface Segregation**
    - `TransitJourneyServiceFacade`: Read-only journey operations
    - `ModelCollectionModifier<TransitLegFacade>`: CRUD for individual legs

5. **Dependency Inversion**
    - `JourneyEditor` depends on abstractions (`TransitJourneyFacade`)
    - Service layer abstracts DB grouping logic from UI

### 7. Implementation Phases

#### Phase 1: Data Model (COMPLETED ✅)

- [x] Add `journeyId` field to `TransitFacade` model and implementation
- [x] Create `TransitJourneyFacade` read-only aggregation
- [x] Create `TransitJourneyService` for grouping logic
- [x] No new bloc events needed - uses existing `UpdateTripEntity<TransitFacade>`

#### Phase 2: Editor UI (COMPLETED ✅)

- [x] Create `JourneyRouteHeader` - compact route visualization
- [x] Create `CollapsibleLegSection` - expandable leg editor
- [x] Create `JourneyEditor` - main journey editing page
- [x] Update `editor_action.dart` to use `JourneyEditor` for all transit editing
- [x] Implement journey validation display

#### Phase 3: Timeline Display (COMPLETED ✅)

- [x] Create `ConnectedTransitTimelineEvent` with connection position
- [x] Update `TimelineEventFactory` for journey grouping
- [x] Update `TimelineItemWidget` with `ConnectedTimelineItemWidget`
- [x] Add connection lines and layover indicators

#### Phase 4: Testing (TODO)

- [ ] Unit tests for `TransitJourneyFacade` validation
- [ ] Unit tests for `TransitJourneyService`
- [ ] Integration tests for journey editor
- [ ] Test backward compatibility with existing transits

---

## Acceptance Criteria

- [x] Standalone legs continue to work without changes
- [x] User can create a new journey with multiple legs
- [x] User can add legs to an existing journey
- [x] User can remove legs from a journey (minimum 1 leg remains)
- [x] Legs are automatically sorted by departure time
- [x] Journey validation shows errors for invalid time sequences
- [x] Timeline displays connected legs with visual connections
- [x] Layover durations are shown between legs
- [x] City names are displayed (city preferred over full location)
- [x] Collapsible leg sections keep UI organized
- [x] Journey route header provides at-a-glance overview
- [x] Clicking on any transit leg opens the JourneyEditor
