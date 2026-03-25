import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip_entity_editor/events.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/services/transit_journey_service.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Editor for multi-leg transit journeys
/// Shows collapsible sections for each leg with journey overview
class JourneyEditor extends StatefulWidget {
  /// The initial leg being edited (used to find the journey)
  final TransitFacade initialLeg;

  /// Called when any leg in the journey is updated
  final VoidCallback onJourneyUpdated;

  /// Notifier to track if FAB should be enabled
  final ValueNotifier<bool>? validityNotifier;

  const JourneyEditor({
    required this.initialLeg,
    required this.onJourneyUpdated,
    this.validityNotifier,
    super.key,
  });

  @override
  State<JourneyEditor> createState() => JourneyEditorState();
}

class JourneyEditorState extends State<JourneyEditor> {
  late List<TransitFacade> _legs;
  late List<bool> _expandedStates;
  String? _journeyId;
  bool _isInitialized = false;

  /// Get all legs in this journey (for saving)
  List<TransitFacade> get legs => List.unmodifiable(_legs);

  /// Whether this is a new journey (no existing legs in DB)
  bool get isNewJourney =>
      _legs.isEmpty || _legs.every((l) => l.id == null || l.id!.isEmpty);

  TransitJourneyServiceFacade get _journeyService =>
      TransitJourneyServiceFacade(context.activeTrip.transitCollection);

  @override
  void initState() {
    super.initState();
    _initializeLegs();
  }

  @override
  void didUpdateWidget(covariant JourneyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLeg.journeyId != widget.initialLeg.journeyId) {
      _initializeLegs();
      setState(() {});
    }
  }

  /// Save all legs of the journey to the database
  void saveAllLegs(BuildContext context) {
    for (final leg in _legs) {
      final isNew = leg.id == null || leg.id!.isEmpty;
      if (isNew) {
        context.addTripManagementEvent(
          UpdateTripEntity<TransitFacade>.create(tripEntity: leg),
        );
      } else {
        context.addTripManagementEvent(
          UpdateTripEntity<TransitFacade>.update(tripEntity: leg),
        );
      }
    }
  }

  void _initializeLegs() {
    _journeyId = widget.initialLeg.journeyId;

    if (_journeyId != null) {
      // Load all legs for this journey
      final journey = _journeyService.getJourney(_journeyId!);
      if (journey != null) {
        _legs = journey.legs.map((l) => l.clone()).toList();
      } else {
        _legs = [widget.initialLeg.clone()];
      }
    } else {
      // Single standalone leg
      _legs = [widget.initialLeg.clone()];
    }

    // Find the index of the clicked leg and expand it
    int expandedIndex = 0;
    for (int i = 0; i < _legs.length; i++) {
      if (_legs[i].id == widget.initialLeg.id) {
        expandedIndex = i;
        break;
      }
    }
    _expandedStates = List.generate(_legs.length, (i) => i == expandedIndex);
    _isInitialized = true;
  }

  void _toggleLegExpansion(int index) {
    setState(() {
      _expandedStates[index] = !_expandedStates[index];
    });
  }

  void _addNewLeg() {
    final tripData = context.activeTrip;
    final contributors = tripData.tripMetadata.contributors;

    // Generate journeyId if this is converting from standalone
    if (_journeyId == null) {
      _journeyId = DateTime.now().millisecondsSinceEpoch.toString();
      // Update existing leg with journeyId
      _legs.first.journeyId = _journeyId;
    }

    // Create new leg with same journeyId
    final newLeg = TransitFacade.newUiEntry(
      tripId: tripData.tripMetadata.id!,
      transitOption: _legs.last.transitOption,
      allTripContributors: contributors,
      defaultCurrency: tripData.tripMetadata.budget.currency,
      journeyId: _journeyId,
    );

    // Pre-fill departure from last leg's arrival
    newLeg.departureLocation = _legs.last.arrivalLocation?.clone();

    setState(() {
      _legs.add(newLeg);
      _expandedStates.add(true); // Expand new leg
      // Collapse other legs
      for (var i = 0; i < _expandedStates.length - 1; i++) {
        _expandedStates[i] = false;
      }
    });

    widget.onJourneyUpdated();
    _updateValidity();
  }

  void _removeLeg(int index) {
    if (_legs.length <= 1) return; // Can't remove last leg

    final legToRemove = _legs[index];
    TransitFacade? remainingLegToUpdate;

    setState(() {
      _legs.removeAt(index);
      _expandedStates.removeAt(index);

      // If only one leg remains, remove journeyId (becomes standalone)
      if (_legs.length == 1) {
        _legs.first.journeyId = null;
        _journeyId = null;
        // Mark the remaining leg for update if it exists in DB
        if (_legs.first.id != null && _legs.first.id!.isNotEmpty) {
          remainingLegToUpdate = _legs.first;
        }
      }
    });

    // Delete the removed leg from database if it has an ID
    if (legToRemove.id != null && legToRemove.id!.isNotEmpty) {
      context.addTripManagementEvent(
        UpdateTripEntity<TransitFacade>.delete(tripEntity: legToRemove),
      );
    }

    // Update the remaining leg to remove journeyId from database
    if (remainingLegToUpdate != null) {
      context.addTripManagementEvent(
        UpdateTripEntity<TransitFacade>.update(
            tripEntity: remainingLegToUpdate!),
      );
    }

    widget.onJourneyUpdated();
    _updateValidity();
  }

  void _onLegUpdated(int index, {bool needsRebuild = true}) {
    // Only call setState if the change requires a visual rebuild (e.g., location/time changes).
    // Expense changes don't need rebuilds and calling setState disrupts text field editing.
    if (needsRebuild) {
      setState(() {
        // Trigger rebuild to update header with new leg data
      });
      // Time or location might have changed, trigger conflict scan
      context.addTripEntityEditorEvent<TransitFacade>(
          UpdateJourneyTimeRange(_legs));
    }
    widget.onJourneyUpdated();
    _updateValidity();
  }

  void _updateValidity() {
    if (widget.validityNotifier != null) {
      final allValid = _legs.every((leg) => leg.validate());
      final timeSequenceValid = _validateTimeSequence();
      widget.validityNotifier!.value = allValid && timeSequenceValid;
    }
  }

  bool _validateTimeSequence() {
    // Sort legs by departure time
    final sortedLegs = List<TransitFacade>.from(_legs)
      ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
          .compareTo(b.departureDateTime ?? DateTime(0)));

    for (var i = 0; i < sortedLegs.length; i++) {
      final leg = sortedLegs[i];

      // Check arrival is at least 1 minute after departure
      if (leg.departureDateTime != null && leg.arrivalDateTime != null) {
        final minArrival =
            leg.departureDateTime!.add(const Duration(minutes: 1));
        if (leg.arrivalDateTime!.isBefore(minArrival)) return false;
      }

      // Check connecting leg's departure is on or after previous leg's arrival
      if (i > 0) {
        final prevArrival = sortedLegs[i - 1].arrivalDateTime;
        final currentDeparture = leg.departureDateTime;
        if (prevArrival != null && currentDeparture != null) {
          if (currentDeparture.isBefore(prevArrival)) return false;
        }
      }
    }
    return true;
  }

  TransitJourneyFacade? _getJourneyFacade() {
    if (_journeyId == null || _legs.length < 2) return null;
    return TransitJourneyFacade(
      journeyId: _journeyId!,
      tripId: _legs.first.tripId,
      unsortedLegs: _legs,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final journey = _getJourneyFacade();
    final hasMultipleLegs = _legs.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Journey route header (only for multi-leg journeys)
        if (hasMultipleLegs && journey != null)
          JourneyRouteHeader(journey: journey),

        // Validation errors banner
        if (hasMultipleLegs && journey != null && !journey.validate())
          _buildValidationBanner(journey),

        // Leg editors - use shrinkWrap since we're in an unbounded context
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _legs.length + 1,
          // +1 for add button
          itemBuilder: (context, index) {
            if (index == _legs.length) {
              return _buildAddLegButton();
            }
            return _buildCollapsibleLegEditor(index);
          },
        ),

        // Journey summary footer (only for multi-leg journeys)
        if (hasMultipleLegs && journey != null)
          JourneySummaryFooter(
            journey: journey,
            targetCurrency: context.activeTrip.tripMetadata.budget.currency,
          ),
      ],
    );
  }

  Widget _buildValidationBanner(TransitJourneyFacade journey) {
    final errors = journey.getValidationErrors();
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme ? AppColors.error : AppColors.errorLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isLightTheme ? AppColors.error : AppColors.errorLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${errors.length} validation error${errors.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isLightTheme ? AppColors.error : AppColors.errorLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleLegEditor(int index) {
    final leg = _legs[index];
    final isExpanded = _expandedStates[index];
    final isValid = leg.validate();
    final canRemove = _legs.length > 1;

    // Get previous leg's arrival time for constraining departure picker
    // The legs are displayed sorted by departure time, so use the sorted order
    DateTime? minDepartureDateTime;
    if (_legs.length > 1) {
      // Sort legs by departure time to find the correct order
      final sortedLegs = List<TransitFacade>.from(_legs)
        ..sort((a, b) => (a.departureDateTime ?? DateTime(9999))
            .compareTo(b.departureDateTime ?? DateTime(9999)));
      final legIndexInSorted = sortedLegs.indexOf(leg);
      if (legIndexInSorted > 0) {
        final previousLeg = sortedLegs[legIndexInSorted - 1];
        minDepartureDateTime = previousLeg.arrivalDateTime;
      }
    }

    return CollapsibleLegSection(
      leg: leg,
      legNumber: index + 1,
      isExpanded: isExpanded,
      isValid: isValid,
      canRemove: canRemove,
      onToggle: () => _toggleLegExpansion(index),
      onRemove: () => _removeLeg(index),
      onLegUpdated: ({bool needsRebuild = true}) =>
          _onLegUpdated(index, needsRebuild: needsRebuild),
      minDepartureDateTime: minDepartureDateTime,
    );
  }

  Widget _buildAddLegButton() {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.all(12),
      child: OutlinedButton.icon(
        onPressed: _addNewLeg,
        icon: const Icon(Icons.add),
        label: const Text('Add Connecting Leg'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(
            color: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Compact visual representation of the journey route
class JourneyRouteHeader extends StatelessWidget {
  final TransitJourneyFacade journey;

  const JourneyRouteHeader({required this.journey, super.key});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLightTheme
              ? [
                  AppColors.brandPrimary.withValues(alpha: 0.1),
                  AppColors.info.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.brandPrimaryLight.withValues(alpha: 0.2),
                  AppColors.infoLight.withValues(alpha: 0.2),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme
              ? AppColors.brandPrimary.withValues(alpha: 0.3)
              : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildRouteWidgets(context),
        ),
      ),
    );
  }

  List<Widget> _buildRouteWidgets(BuildContext context) {
    final widgets = <Widget>[];

    for (var i = 0; i < journey.legs.length; i++) {
      final leg = journey.legs[i];

      // Add departure city (only for first leg)
      if (i == 0) {
        widgets.add(_CityChip(
          city: _getCityName(leg.departureLocation),
          isEndpoint: true,
        ));
      }

      // Add transit icon with connection line
      widgets.add(_ConnectionSegment(
        transitOption: leg.transitOption,
        duration: _formatFlightDuration(leg),
      ));

      // Add arrival city
      widgets.add(_CityChip(
        city: _getCityName(leg.arrivalLocation),
        isEndpoint: i == journey.legs.length - 1,
      ));

      // Add layover indicator (if not last leg)
      if (i < journey.legs.length - 1) {
        final layover = journey.getLayoverDuration(i);
        if (layover != null) {
          widgets.add(_LayoverChip(duration: layover));
        }
      }
    }

    return widgets;
  }

  String _getCityName(LocationFacade? location) {
    if (location == null) return '?';
    // Try city from context first, then name from context
    final city = location.context.city;
    if (city != null && city.isNotEmpty) return city;
    final name = location.context.name;
    if (name.isNotEmpty) return name;
    return '?';
  }

  String? _formatFlightDuration(TransitFacade leg) {
    if (leg.departureDateTime == null || leg.arrivalDateTime == null) {
      return null;
    }
    final duration = leg.arrivalDateTime!.difference(leg.departureDateTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes > 0 ? ' ${minutes}m' : ''}';
    }
    return '${minutes}m';
  }
}

/// Chip displaying city name
class _CityChip extends StatelessWidget {
  final String city;
  final bool isEndpoint;

  const _CityChip({required this.city, required this.isEndpoint});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEndpoint
            ? (isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.2)
                : AppColors.brandPrimaryLight.withValues(alpha: 0.3))
            : (isLightTheme ? Colors.grey.shade200 : Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEndpoint
              ? (isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight)
              : Colors.grey.shade400,
        ),
      ),
      child: Text(
        city,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isEndpoint ? FontWeight.bold : FontWeight.normal,
              color: isEndpoint
                  ? (isLightTheme
                      ? AppColors.brandPrimary
                      : AppColors.brandPrimaryLight)
                  : null,
            ),
      ),
    );
  }
}

/// Connection line segment with transit icon
class _ConnectionSegment extends StatelessWidget {
  final TransitOption transitOption;
  final String? duration;

  const _ConnectionSegment({
    required this.transitOption,
    this.duration,
  });

  IconData _getTransitIcon() {
    switch (transitOption) {
      case TransitOption.flight:
        return Icons.flight;
      case TransitOption.train:
        return Icons.train;
      case TransitOption.bus:
        return Icons.directions_bus;
      case TransitOption.ferry:
      case TransitOption.cruise:
        return Icons.directions_boat;
      case TransitOption.taxi:
        return Icons.local_taxi;
      case TransitOption.walk:
        return Icons.directions_walk;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 2,
                color: AppColors.info,
              ),
              Icon(
                _getTransitIcon(),
                size: 18,
                color: AppColors.info,
              ),
              Container(
                width: 20,
                height: 2,
                color: AppColors.info,
              ),
            ],
          ),
          if (duration != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                duration!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Layover duration indicator
class _LayoverChip extends StatelessWidget {
  final Duration duration;

  const _LayoverChip({required this.duration});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final text = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.warningLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isLightTheme ? AppColors.warning : AppColors.warningLight,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

/// Collapsible section for editing a single leg
class CollapsibleLegSection extends StatelessWidget {
  final TransitFacade leg;
  final int legNumber;
  final bool isExpanded;
  final bool isValid;
  final bool canRemove;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final void Function({bool needsRebuild}) onLegUpdated;

  /// Minimum allowed departure date time (previous leg's arrival time)
  final DateTime? minDepartureDateTime;

  const CollapsibleLegSection({
    required this.leg,
    required this.legNumber,
    required this.isExpanded,
    required this.isValid,
    required this.canRemove,
    required this.onToggle,
    required this.onRemove,
    required this.onLegUpdated,
    this.minDepartureDateTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? (isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700)
              : (isLightTheme ? AppColors.error : AppColors.errorLight),
          width: isValid ? 1 : 2,
        ),
      ),
      child: Column(
        children: [
          // Header (always visible)
          _LegSectionHeader(
            leg: leg,
            legNumber: legNumber,
            isExpanded: isExpanded,
            isValid: isValid,
            canRemove: canRemove,
            onToggle: onToggle,
            onRemove: onRemove,
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(12),
              child: TravelEditor(
                key: ValueKey('travel_${leg.id ?? 'new_$legNumber'}'),
                transitFacade: leg,
                onTransitUpdated: onLegUpdated,
                minDepartureDateTime: minDepartureDateTime,
              ),
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
  final TransitFacade leg;
  final int legNumber;
  final bool isExpanded;
  final bool isValid;
  final bool canRemove;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _LegSectionHeader({
    required this.leg,
    required this.legNumber,
    required this.isExpanded,
    required this.isValid,
    required this.canRemove,
    required this.onToggle,
    required this.onRemove,
  });

  String _getCityName(LocationFacade? location) {
    if (location == null) return '?';
    // Try city from context first, then name from context
    final city = location.context.city;
    if (city != null && city.isNotEmpty) return city;
    final name = location.context.name;
    if (name.isNotEmpty) return name;
    return '?';
  }

  String _formatLegTimes() {
    final dep = leg.departureDateTime;
    final arr = leg.arrivalDateTime;
    if (dep == null && arr == null) return 'Times not set';

    final depStr = dep != null
        ? '${dep.day}/${dep.month} ${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}'
        : '--';
    final arrStr = arr != null
        ? '${arr.hour.toString().padLeft(2, '0')}:${arr.minute.toString().padLeft(2, '0')}'
        : '--';
    return '$depStr → $arrStr';
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

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
                    _formatLegTimes(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                  ),
                ],
              ),
            ),

            // Remove button (if allowed)
            if (canRemove)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isLightTheme ? AppColors.error : AppColors.errorLight,
                ),
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
}

/// Leg number badge with validation indicator
class _LegNumberBadge extends StatelessWidget {
  final int number;
  final bool isValid;

  const _LegNumberBadge({required this.number, required this.isValid});

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

/// Journey summary footer with total expense converted to trip currency
class JourneySummaryFooter extends StatefulWidget {
  final TransitJourneyFacade journey;

  /// Target currency for expense display (usually trip's default currency)
  final String targetCurrency;

  const JourneySummaryFooter({
    required this.journey,
    required this.targetCurrency,
    super.key,
  });

  @override
  State<JourneySummaryFooter> createState() => _JourneySummaryFooterState();
}

class _JourneySummaryFooterState extends State<JourneySummaryFooter> {
  double _totalExpense = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateTotalExpense();
  }

  @override
  void didUpdateWidget(covariant JourneySummaryFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.journey != widget.journey ||
        oldWidget.targetCurrency != widget.targetCurrency) {
      _calculateTotalExpense();
    }
  }

  void _calculateTotalExpense() async {
    setState(() {
      _isLoading = true;
      _totalExpense = 0.0;
    });

    final currencyConverter = context.apiServicesRepository.currencyConverter;
    final service = TransitJourneyServiceFacade(
      context.activeTrip.transitCollection,
      currencyConverter: currencyConverter,
    );

    await for (final amount in service.getTotalExpenseStream(
      legs: widget.journey.legs,
      targetCurrency: widget.targetCurrency,
    )) {
      if (mounted) {
        setState(() {
          _totalExpense = amount;
          _isLoading = false;
        });
      }
    }

    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _calculateTotalDuration() {
    if (widget.journey.departureDateTime == null ||
        widget.journey.arrivalDateTime == null) {
      return null;
    }
    final duration = widget.journey.arrivalDateTime!
        .difference(widget.journey.departureDateTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final totalDuration = _calculateTotalDuration();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.grey.shade100 : Colors.grey.shade900,
        border: Border(
          top: BorderSide(
            color: isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.flight_takeoff,
            label:
                '${widget.journey.legs.length} leg${widget.journey.legs.length > 1 ? 's' : ''}',
          ),
          if (totalDuration != null)
            _SummaryItem(
              icon: Icons.schedule,
              label: totalDuration,
            ),
          _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _SummaryItem(
                  icon: Icons.payments,
                  label:
                      '${_totalExpense.toStringAsFixed(2)} ${widget.targetCurrency}',
                ),
        ],
      ),
    );
  }
}

/// Summary item for footer
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.info),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
