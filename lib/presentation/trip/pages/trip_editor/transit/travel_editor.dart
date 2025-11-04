import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'airport_data_editor_section.dart';
import 'transit_operator_editor_section.dart';
import 'transit_option_picker.dart';

class TravelEditor extends StatefulWidget {
  final TransitFacade transitFacade;
  final VoidCallback onTransitUpdated;

  const TravelEditor(
      {required this.transitFacade, required this.onTransitUpdated, super.key});

  @override
  State<TravelEditor> createState() => _TravelEditorState();
}

class _TravelEditorState extends State<TravelEditor>
    with SingleTickerProviderStateMixin {
  TransitFacade get _transitFacade => widget.transitFacade;

  @override
  void didUpdateWidget(covariant TravelEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitFacade != _transitFacade) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTrip = context.activeTrip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransitTypeBadge(),
        if (_needsPriorBooking) _buildOperatorSection(),
        _JourneySection(
          tripMetadata: activeTrip.tripMetadata,
          transitFacade: _transitFacade,
          parentContext: context,
          onLocationChanged: _updateLocation,
          onDateTimeChanged: _updateDateTime,
        ),
        if (_needsPriorBooking) _buildConfirmationIdSection(),
        _buildNotesSection(),
        _createPaymentDetailsSection(context),
      ],
    );
  }

  Widget _createPaymentDetailsSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.account_balance_wallet,
            title: context.localizations.expenses,
            iconColor: Theme.of(context).brightness == Brightness.light
                ? AppColors.warning
                : AppColors.warningLight,
          ),
          const SizedBox(height: 12),
          ExpenditureEditTile(
            expenseUpdator: _transitFacade.expense,
            isEditable: true,
            callback: _handleExpenseUpdated,
          ),
        ],
      ),
    );
  }

  bool get _needsPriorBooking {
    final option = _transitFacade.transitOption;
    return option != TransitOption.walk &&
        option != TransitOption.vehicle &&
        option != TransitOption.rentedVehicle;
  }

  Widget _buildTransitTypeBadge() {
    return Container(
      decoration: _buildBadgeDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TransitOptionPicker(
        options: context.activeTrip.transitOptionMetadatas,
        initialTransitOption: _transitFacade.transitOption,
        onChanged: _handleTransitOptionChanged,
      ),
    );
  }

  BoxDecoration _buildBadgeDecoration() {
    var isLightTheme = context.isLightTheme;
    final isBigLayout = context.isBigLayout;
    final cardBorderRadius = EditorTheme.getCardBorderRadius(isBigLayout);
    return BoxDecoration(
      gradient: EditorTheme.createPrimaryGradient(isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [EditorTheme.createBadgeShadow(isLightTheme)],
    );
  }

  void _handleTransitOptionChanged(TransitOption newOption) {
    setState(() {
      _clearOperatorIfNotNeeded(newOption);
      _clearFlightDataIfSwitchingFromFlight(newOption);
      _updateTransitOption(newOption);
    });
    widget.onTransitUpdated();
  }

  void _clearOperatorIfNotNeeded(TransitOption option) {
    final optionsWithoutOperator = [
      TransitOption.walk,
      TransitOption.rentedVehicle,
      TransitOption.vehicle,
    ];

    if (optionsWithoutOperator.contains(option)) {
      _transitFacade.operator = null;
    }
  }

  void _clearFlightDataIfSwitchingFromFlight(TransitOption newOption) {
    final isChangingToFlight = newOption == TransitOption.flight &&
        _transitFacade.transitOption != TransitOption.flight;
    final isChangingFromFlight =
        _transitFacade.transitOption == TransitOption.flight &&
            newOption != TransitOption.flight;

    if (isChangingToFlight || isChangingFromFlight) {
      _transitFacade.operator = null;
      _transitFacade.arrivalLocation = null;
      _transitFacade.departureLocation = null;
    }
  }

  void _updateTransitOption(TransitOption newOption) {
    _transitFacade.transitOption = newOption;
    _transitFacade.expense.category =
        TransitFacade.getExpenseCategory(newOption);
  }

  Widget _buildOperatorSection() {
    return TransitOperatorEditorSection(
      transitOption: _transitFacade.transitOption,
      initialOperator: _transitFacade.operator,
      onOperatorChanged: _handleOperatorChanged,
    );
  }

  Widget _buildConfirmationIdSection() {
    return EditorTheme.createSection(
      context: context,
      child: _buildConfirmationField(context),
    );
  }

  Widget _buildConfirmationField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: '${context.localizations.confirmation} #',
        prefixIcon: const Icon(Icons.tag),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      initialValue: _transitFacade.confirmationId,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _transitFacade.confirmationId = value;
        widget.onTransitUpdated();
      },
    );
  }

  Widget _buildNotesSection() {
    return EditorTheme.createSection(
      context: context,
      child: _buildNotesField(context),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return TextFormField(
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '${context.localizations.notes}...',
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      initialValue: _transitFacade.notes,
      textInputAction: TextInputAction.done,
      maxLines: 3,
      minLines: 2,
      onChanged: (value) {
        _transitFacade.notes = value;
        widget.onTransitUpdated();
      },
    );
  }

  void _handleExpenseUpdated(
    Map<String, double> paidBy,
    List<String> splitBy,
    Money totalExpense,
  ) {
    _transitFacade.expense.paidBy = Map.from(paidBy);
    _transitFacade.expense.splitBy = List.from(splitBy);
    _transitFacade.expense.totalExpense = totalExpense;
    widget.onTransitUpdated();
  }

  void _handleOperatorChanged(String? newOperator) {
    _transitFacade.operator = newOperator;
    widget.onTransitUpdated();
  }

  void _updateLocation(bool isArrival, LocationFacade? newLocation) {
    if (isArrival) {
      _transitFacade.arrivalLocation = newLocation;
    } else {
      _transitFacade.departureLocation = newLocation;
    }
    widget.onTransitUpdated();
  }

  void _updateDateTime(bool isArrival, DateTime updatedDateTime) {
    if (isArrival) {
      _transitFacade.arrivalDateTime = updatedDateTime;
    } else {
      _transitFacade.departureDateTime = updatedDateTime;
    }
    setState(() {});
    widget.onTransitUpdated();
  }
}

class _JourneySection extends StatelessWidget {
  final TripMetadataFacade tripMetadata;
  final TransitFacade transitFacade;
  final BuildContext parentContext;
  final void Function(bool isArrival, LocationFacade? newLocation)
      onLocationChanged;
  final void Function(bool isArrival, DateTime updatedDateTime)
      onDateTimeChanged;

  const _JourneySection({
    Key? key,
    required this.tripMetadata,
    required this.transitFacade,
    required this.parentContext,
    required this.onLocationChanged,
    required this.onDateTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (context.isBigLayout) {
      return Row(
        children: [
          Expanded(child: _buildDeparturePoint(tripMetadata)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildJourneyConnector(context),
          ),
          Expanded(child: _buildArrivalPoint(tripMetadata)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeparturePoint(tripMetadata),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildJourneyConnector(context),
          ),
        ),
        _buildArrivalPoint(tripMetadata),
      ],
    );
  }

  Widget _buildDeparturePoint(TripMetadataFacade tripMetadata) {
    return _buildJourneyPoint(
      isDeparture: true,
      tripMetadata: tripMetadata,
    );
  }

  Widget _buildArrivalPoint(TripMetadataFacade tripMetadata) {
    return _buildJourneyPoint(
      isDeparture: false,
      tripMetadata: tripMetadata,
    );
  }

  Widget _buildJourneyPoint({
    required bool isDeparture,
    required TripMetadataFacade tripMetadata,
  }) {
    final pointTitle = isDeparture
        ? parentContext.localizations.depart
        : parentContext.localizations.arrive;
    return EditorTheme.createSection(
      context: parentContext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            parentContext,
            icon: isDeparture ? Icons.flight_takeoff : Icons.flight_land,
            title: pointTitle,
            iconColor: isDeparture ? AppColors.info : AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildLocationField(isDeparture),
          const SizedBox(height: 12),
          _buildDateTimeField(isDeparture, tripMetadata),
        ],
      ),
    );
  }

  Widget _buildJourneyConnector(BuildContext context) {
    final connectorColor = context.isLightTheme
        ? AppColors.brandPrimary
        : AppColors.brandPrimaryLight;
    return Icon(
        context.isBigLayout ? Icons.arrow_forward : Icons.arrow_downward,
        color: connectorColor,
        size: 32);
  }

  //TODO: LocationAutoComplete has little width in big layout
  Widget _buildLocationField(bool isArrival) {
    final currentLocation = isArrival
        ? transitFacade.arrivalLocation
        : transitFacade.departureLocation;
    final isFlightTransit = transitFacade.transitOption == TransitOption.flight;
    return isFlightTransit
        ? AirportsDataEditorSection(
            initialLocation: currentLocation,
            onLocationSelected: (newLocation) =>
                onLocationChanged(isArrival, newLocation),
          )
        : PlatformGeoLocationAutoComplete(
            onLocationSelected: (newLocation) =>
                onLocationChanged(isArrival, newLocation),
            selectedLocation: currentLocation,
          );
  }

  Widget _buildDateTimeField(bool isArrival, TripMetadataFacade tripMetadata) {
    final startDateTime = _getStartDateTime(isArrival, tripMetadata);
    final endDateTime = _getEndDateTime(tripMetadata);
    final currentDateTime = isArrival
        ? transitFacade.arrivalDateTime
        : transitFacade.departureDateTime;
    return PlatformDateTimePicker(
      dateTimeUpdated: (updatedDateTime) =>
          onDateTimeChanged(isArrival, updatedDateTime),
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      currentDateTime: currentDateTime,
    );
  }

  DateTime _getStartDateTime(bool isArrival, TripMetadataFacade tripMetadata) {
    if (isArrival) {
      final departureTime = transitFacade.departureDateTime;
      if (departureTime != null) {
        return departureTime.add(const Duration(minutes: 1));
      }
    }
    return tripMetadata.startDate!;
  }

  DateTime _getEndDateTime(TripMetadataFacade tripMetadata) {
    final endDate = tripMetadata.endDate!;
    return DateTime(endDate.year, endDate.month, endDate.day, 23, 59);
  }
}
