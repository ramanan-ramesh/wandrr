import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'airport_data_editor.dart';
import 'transit_operator.dart';
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final isBigLayout = context.isBigLayout;
    final cardBorderRadius = _getCardBorderRadius(isBigLayout);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildTransitCard(
        context,
        activeTrip,
        isLightTheme,
        isBigLayout,
        cardBorderRadius,
      ),
    );
  }

  double _getCardBorderRadius(bool isBigLayout) {
    return isBigLayout ? 28.0 : 24.0;
  }

  Widget _buildTransitCard(
    BuildContext context,
    TripDataFacade activeTrip,
    bool isLightTheme,
    bool isBigLayout,
    double cardBorderRadius,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isBigLayout ? 24 : 16,
        vertical: isBigLayout ? 16 : 12,
      ),
      constraints: isBigLayout ? const BoxConstraints(maxWidth: 1200) : null,
      decoration:
          _buildCardDecoration(isLightTheme, isBigLayout, cardBorderRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardBorderRadius - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransitTypeBadge(
                context, activeTrip, isLightTheme, cardBorderRadius),
            if (_needsPriorBooking) _buildOperatorSection(context),
            _buildJourneyTimeline(context, activeTrip.tripMetadata),
            if (_needsPriorBooking) _buildConfirmationIdSection(context),
            _buildExpenseSection(context),
            _buildNotesSection(context),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(
      bool isLightTheme, bool isBigLayout, double borderRadius) {
    return BoxDecoration(
      gradient: _buildCardGradient(isLightTheme),
      borderRadius: BorderRadius.circular(borderRadius),
      border: _buildCardBorder(isLightTheme),
      boxShadow: [_buildCardShadow(isLightTheme, isBigLayout)],
    );
  }

  LinearGradient _buildCardGradient(bool isLightTheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLightTheme
          ? [
              AppColors.brandPrimaryLight.withValues(alpha: 0.15),
              AppColors.brandAccent.withValues(alpha: 0.08),
            ]
          : [
              AppColors.darkSurface,
              AppColors.darkSurfaceVariant,
            ],
    );
  }

  Border _buildCardBorder(bool isLightTheme) {
    return Border.all(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.3)
          : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
      width: 2,
    );
  }

  BoxShadow _buildCardShadow(bool isLightTheme, bool isBigLayout) {
    return BoxShadow(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.3),
      blurRadius: isBigLayout ? 20 : 16,
      offset: Offset(0, isBigLayout ? 10 : 8),
    );
  }

  bool get _needsPriorBooking {
    final option = _transitFacade.transitOption;
    return option != TransitOption.walk &&
        option != TransitOption.vehicle &&
        option != TransitOption.rentedVehicle;
  }

  Widget _buildTransitTypeBadge(
    BuildContext context,
    TripDataFacade activeTrip,
    bool isLightTheme,
    double cardBorderRadius,
  ) {
    return Row(
      children: [
        Container(
          decoration: _buildBadgeDecoration(isLightTheme, cardBorderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TransitOptionPicker(
            options: activeTrip.transitOptionMetadatas,
            initialTransitOption: _transitFacade.transitOption,
            onChanged: _handleTransitOptionChanged,
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  BoxDecoration _buildBadgeDecoration(
      bool isLightTheme, double cardBorderRadius) {
    return BoxDecoration(
      gradient: _buildPrimaryGradient(isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [_buildBadgeShadow(isLightTheme)],
    );
  }

  LinearGradient _buildPrimaryGradient(bool isLightTheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLightTheme
          ? [AppColors.brandPrimary, AppColors.brandPrimaryDark]
          : [AppColors.brandPrimaryLight, AppColors.brandPrimaryDark],
    );
  }

  BoxShadow _buildBadgeShadow(bool isLightTheme) {
    return BoxShadow(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(2, 2),
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

  Widget _buildOperatorSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _buildPrimaryGradient(isLightTheme),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [_buildStandardShadow(isLightTheme)],
      ),
      child: TransitOperatorEditor(
        transitOption: _transitFacade.transitOption,
        initialOperator: _transitFacade.operator,
        onOperatorChanged: _handleOperatorChanged,
      ),
    );
  }

  BoxShadow _buildStandardShadow(bool isLightTheme) {
    return BoxShadow(
      color: isLightTheme
          ? AppColors.brandPrimary.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    );
  }

  void _handleOperatorChanged(String? newOperator) {
    _transitFacade.operator = newOperator;
    widget.onTransitUpdated();
  }

  Widget _buildJourneyTimeline(
      BuildContext context, TripMetadataFacade tripMetadata) {
    final isBigLayout = context.isBigLayout;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        padding: EdgeInsets.all(isBigLayout ? 24 : 20),
        child: isBigLayout
            ? _buildHorizontalJourney(context, tripMetadata)
            : _buildVerticalJourney(context, tripMetadata),
      ),
    );
  }

  Widget _buildHorizontalJourney(
      BuildContext context, TripMetadataFacade tripMetadata) {
    return Row(
      children: [
        Expanded(child: _buildDeparturePoint(context, tripMetadata)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildHorizontalConnector(context),
        ),
        Expanded(child: _buildArrivalPoint(context, tripMetadata)),
      ],
    );
  }

  Widget _buildVerticalJourney(
      BuildContext context, TripMetadataFacade tripMetadata) {
    return Column(
      children: [
        _buildDeparturePoint(context, tripMetadata),
        _buildVerticalConnector(context),
        _buildArrivalPoint(context, tripMetadata),
      ],
    );
  }

  Widget _buildDeparturePoint(
      BuildContext context, TripMetadataFacade tripMetadata) {
    return _buildJourneyPoint(
      context,
      isDeparture: true,
      tripMetadata: tripMetadata,
    );
  }

  Widget _buildArrivalPoint(
      BuildContext context, TripMetadataFacade tripMetadata) {
    return _buildJourneyPoint(
      context,
      isDeparture: false,
      tripMetadata: tripMetadata,
    );
  }

  Widget _buildHorizontalConnector(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final connectorColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    return Icon(Icons.arrow_forward, color: connectorColor, size: 32);
  }

  Widget _buildVerticalConnector(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final connectorColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.4)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(
                5,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  width: 3,
                  height: 8,
                  decoration: BoxDecoration(
                    color: connectorColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyPoint(
    BuildContext context, {
    required bool isDeparture,
    required TripMetadataFacade tripMetadata,
  }) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final pointTitle = isDeparture
        ? context.localizations.depart
        : context.localizations.arrive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildJourneyPointDecoration(isLightTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJourneyPointHeader(
              context, isDeparture, pointTitle, isLightTheme),
          const SizedBox(height: 12),
          _buildLocationField(isDeparture),
          const SizedBox(height: 12),
          _buildDateTimeField(isDeparture, tripMetadata),
        ],
      ),
    );
  }

  BoxDecoration _buildJourneyPointDecoration(bool isLightTheme) {
    return BoxDecoration(
      color: isLightTheme
          ? Colors.white.withValues(alpha: 0.9)
          : AppColors.darkSurface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isLightTheme
            ? AppColors.brandPrimary.withValues(alpha: 0.3)
            : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isLightTheme
              ? AppColors.brandPrimary.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildJourneyPointHeader(
    BuildContext context,
    bool isDeparture,
    String title,
    bool isLightTheme,
  ) {
    return Row(
      children: [
        _buildJourneyPointIcon(isDeparture),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLightTheme
                    ? AppColors.brandSecondary
                    : AppColors.neutral100,
              ),
        ),
      ],
    );
  }

  Widget _buildJourneyPointIcon(bool isDeparture) {
    final gradientColors = isDeparture
        ? [AppColors.info, AppColors.infoLight]
        : [AppColors.success, AppColors.successLight];
    final iconData = isDeparture ? Icons.flight_takeoff : Icons.flight_land;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 24),
    );
  }

  Widget _buildLocationField(bool isArrival) {
    final currentLocation = isArrival
        ? _transitFacade.arrivalLocation
        : _transitFacade.departureLocation;

    final isFlightTransit =
        _transitFacade.transitOption == TransitOption.flight;

    return isFlightTransit
        ? AirportsDataEditor(
            initialLocation: currentLocation,
            onLocationSelected: (newLocation) =>
                _updateLocation(isArrival, newLocation),
          )
        : PlatformGeoLocationAutoComplete(
            onLocationSelected: (newLocation) =>
                _updateLocation(isArrival, newLocation),
            selectedLocation: currentLocation,
          );
  }

  void _updateLocation(bool isArrival, LocationFacade? newLocation) {
    if (isArrival) {
      _transitFacade.arrivalLocation = newLocation;
    } else {
      _transitFacade.departureLocation = newLocation;
    }
    widget.onTransitUpdated();
  }

  Widget _buildDateTimeField(bool isArrival, TripMetadataFacade tripMetadata) {
    final startDateTime = _getStartDateTime(isArrival, tripMetadata);
    final endDateTime = _getEndDateTime(tripMetadata);
    final currentDateTime = isArrival
        ? _transitFacade.arrivalDateTime
        : _transitFacade.departureDateTime;

    return PlatformDateTimePicker(
      dateTimeUpdated: (updatedDateTime) =>
          _updateDateTime(isArrival, updatedDateTime),
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      currentDateTime: currentDateTime,
    );
  }

  DateTime _getStartDateTime(bool isArrival, TripMetadataFacade tripMetadata) {
    if (isArrival) {
      final departureTime = _transitFacade.departureDateTime;
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

  void _updateDateTime(bool isArrival, DateTime updatedDateTime) {
    if (isArrival) {
      _transitFacade.arrivalDateTime = updatedDateTime;
    } else {
      _transitFacade.departureDateTime = updatedDateTime;
    }
    setState(() {});
    widget.onTransitUpdated();
  }

  Widget _buildConfirmationIdSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return _buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            icon: Icons.confirmation_number_outlined,
            title: context.localizations.confirmation,
            iconColor: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
          const SizedBox(height: 12),
          _buildConfirmationField(context),
        ],
      ),
    );
  }

  Widget _buildExpenseSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return _buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpenseHeader(context, isLightTheme),
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

  Widget _buildExpenseHeader(BuildContext context, bool isLightTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warning, AppColors.warningLight],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          context.localizations.expenses,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLightTheme
                    ? AppColors.brandSecondary
                    : AppColors.neutral100,
              ),
        ),
      ],
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

  Widget _buildNotesSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return _buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            icon: Icons.notes_outlined,
            title: context.localizations.notes,
            iconColor: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
          const SizedBox(height: 12),
          _buildNotesField(context),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required Widget child,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isLightTheme
              ? Colors.white.withValues(alpha: 0.7)
              : AppColors.darkSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: context.isLightTheme
                  ? AppColors.brandPrimary.withValues(alpha: 0.2)
                  : AppColors.brandPrimaryLight.withValues(alpha: 0.2),
              width: 1.5),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
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
}
