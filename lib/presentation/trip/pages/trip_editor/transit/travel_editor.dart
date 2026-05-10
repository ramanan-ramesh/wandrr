import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';
import 'package:wandrr/presentation/trip/widgets/time_zone_indicator.dart';

import 'journey_point_editor.dart';
import 'transit_operator_editor_section.dart';
import 'transit_option_picker.dart';

class TravelEditor extends StatefulWidget {
  final TransitFacade transitFacade;
  final void Function({bool needsRebuild}) onTransitUpdated;

  /// Notifier to track if FAB should be enabled
  final ValueNotifier<bool>? validityNotifier;

  /// Minimum allowed departure date time (e.g., previous leg's arrival time)
  /// Used for connecting legs in a journey
  final DateTime? minDepartureDateTime;

  const TravelEditor({
    required this.transitFacade,
    required this.onTransitUpdated,
    this.validityNotifier,
    this.minDepartureDateTime,
    super.key,
  });

  @override
  State<TravelEditor> createState() => _TravelEditorState();
}

class _TravelEditorState extends State<TravelEditor> {
  TransitFacade get _transitFacade => widget.transitFacade;
  bool _isSeatsExpanded = false;

  @override
  void didUpdateWidget(covariant TravelEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitFacade != _transitFacade) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransitTypeBadge(),
        if (_needsPriorBooking) _buildOperatorSection(),
        _JourneySection(
          transitFacade: _transitFacade,
          onLocationChanged: _updateLocation,
          onDateTimeChanged: _updateDateTime,
          onPlatformChanged: _updatePlatform,
          minDepartureDateTime: widget.minDepartureDateTime,
        ),
        _buildSeatNumbersSection(),
        if (_needsPriorBooking) _buildConfirmationIdSection(),
        _buildNotesSection(),
        if (_needsPriorBooking) _createPaymentDetailsSection(context),
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
            title: 'Payment Details',
            iconColor: Theme.of(context).brightness == Brightness.light
                ? AppColors.warning
                : AppColors.warningLight,
          ),
          const SizedBox(height: 12),
          ExpenditureEditTile(
            key: ValueKey('expense_${_transitFacade.id ?? 'new'}'),
            expenseFacade: _transitFacade.expense,
            isEditable: true,
            callback: _handleExpenseUpdated,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatNumbersSection() {
    final activeUserName = context.activeUser?.userName;
    final allContributors = context.activeTrip.tripMetadata.contributors;
    
    _transitFacade.seatNumbers ??= {};
    
    final otherContributors = allContributors.where((c) => c != activeUserName).toList();
    
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeUserName != null && allContributors.contains(activeUserName))
            TextFormField(
              key: const ValueKey('TravelEditor_ActiveUserSeat_TextField'),
              decoration: InputDecoration(
                labelText: 'My Seat Number',
                prefixIcon: const Icon(Icons.event_seat_rounded),
                suffixIcon: IconButton(
                  key: const ValueKey('TravelEditor_ExpandSeats_Button'),
                  icon: Icon(_isSeatsExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isSeatsExpanded = !_isSeatsExpanded),
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              initialValue: _transitFacade.seatNumbers![activeUserName] ?? '',
              onChanged: (val) {
                _transitFacade.seatNumbers![activeUserName] = val;
                widget.onTransitUpdated(needsRebuild: false);
              },
            ),
          if (_isSeatsExpanded && otherContributors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12, right: 12),
              child: Column(
                children: otherContributors.map((userName) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      key: ValueKey('TravelEditor_TripmateSeat_TextField_$userName'),
                      decoration: InputDecoration(
                        label: Text(
                          '$userName\'s Seat',
                          overflow: TextOverflow.ellipsis,
                        ),
                        prefixIcon: const Icon(Icons.event_seat_outlined),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      initialValue: _transitFacade.seatNumbers![userName] ?? '',
                      onChanged: (val) {
                        _transitFacade.seatNumbers![userName] = val;
                        widget.onTransitUpdated(needsRebuild: false);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  bool get _needsPriorBooking {
    final option = _transitFacade.transitOption;
    return option != TransitOption.walk && option != TransitOption.vehicle;
  }

  Widget _buildTransitTypeBadge() {
    return Container(
      decoration: _buildBadgeDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TransitOptionPicker(
        options: context.transitOptionMetadatas,
        initialTransitOption: _transitFacade.transitOption,
        onChanged: _handleTransitOptionChanged,
      ),
    );
  }

  BoxDecoration _buildBadgeDecoration() {
    var isLightTheme = context.isLightTheme;
    final isBigLayout = context.isBigLayout;
    final cardBorderRadius =
        EditorTheme.getCardBorderRadius(isBigLayout: isBigLayout);
    return BoxDecoration(
      gradient: EditorTheme.createPrimaryGradient(isLightTheme: isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [EditorTheme.createBadgeShadow(isLightTheme: isLightTheme)],
    );
  }

  void _handleTransitOptionChanged(TransitOption newOption) {
    setState(() {
      _clearOperatorIfNotNeeded(newOption);
      _clearFlightDataIfSwitchingFromFlight(newOption);
      _clearPlatformAndSeatsIfNotNeeded(newOption);
      _transitFacade.transitOption = newOption;
    });
    widget.onTransitUpdated(needsRebuild: true);
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

  void _clearPlatformAndSeatsIfNotNeeded(TransitOption option) {
    final isSupported = option == TransitOption.bus ||
        option == TransitOption.flight ||
        option == TransitOption.train ||
        option == TransitOption.ferry ||
        option == TransitOption.cruise ||
        option == TransitOption.publicTransport;

    if (!isSupported) {
      _transitFacade.departurePlatform = null;
      _transitFacade.arrivalPlatform = null;
      _transitFacade.seatNumbers = null;
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
      key: const ValueKey('TransitEditor_ConfirmationId_TextField'),
      decoration: InputDecoration(
        labelText: '${context.localizations.confirmation} #',
        prefixIcon: const Icon(Icons.confirmation_number_rounded),
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
        widget.onTransitUpdated(needsRebuild: false);
      },
    );
  }

  Widget _buildNotesSection() {
    var note = Note(_transitFacade.notes ?? '');
    return EditorTheme.createSection(
      context: context,
      child: NoteEditor(
          note: note,
          onChanged: () {
            _transitFacade.notes = note.text;
            widget.onTransitUpdated(needsRebuild: false);
          }),
    );
  }

  void _handleExpenseUpdated(
    Map<String, double> paidBy,
    List<String> splitBy,
    Money totalExpense,
  ) {
    _transitFacade.expense.paidBy = Map.from(paidBy);
    _transitFacade.expense.splitBy = List.from(splitBy);
    _transitFacade.expense.currency = totalExpense.currency;
    widget.onTransitUpdated(needsRebuild: false);
  }

  void _handleOperatorChanged(String? newOperator) {
    _transitFacade.operator = newOperator;
    widget.onTransitUpdated(needsRebuild: false);
  }

  void _updateLocation({required bool isArrival, LocationFacade? newLocation}) {
    setState(() {
      if (isArrival) {
        _transitFacade.arrivalLocation = newLocation;
      } else {
        _transitFacade.departureLocation = newLocation;
      }
    });
    widget.onTransitUpdated(needsRebuild: true);
  }

  void _updateDateTime(DateTime updatedDateTime, {required bool isArrival}) {
    setState(() {
      if (isArrival) {
        _transitFacade.arrivalDateTime = updatedDateTime;
      } else {
        _transitFacade.departureDateTime = updatedDateTime;
      }
    });
    widget.onTransitUpdated(needsRebuild: true);
  }

  void _updatePlatform({required bool isArrival, String? newPlatform}) {
    if (isArrival) {
      _transitFacade.arrivalPlatform = newPlatform;
    } else {
      _transitFacade.departurePlatform = newPlatform;
    }
    widget.onTransitUpdated(needsRebuild: false);
  }
}

class _JourneySection extends StatelessWidget {
  final TransitFacade transitFacade;
  final void Function({required bool isArrival, LocationFacade? newLocation})
      onLocationChanged;
  final void Function(DateTime updatedDateTime, {required bool isArrival})
      onDateTimeChanged;
  final void Function({required bool isArrival, String? newPlatform})
      onPlatformChanged;

  /// Minimum allowed departure date time (e.g., previous leg's arrival time)
  final DateTime? minDepartureDateTime;

  const _JourneySection({
    required this.transitFacade,
    required this.onLocationChanged,
    required this.onDateTimeChanged,
    required this.onPlatformChanged,
    Key? key,
    this.minDepartureDateTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasBothLocations = transitFacade.departureLocation != null &&
        transitFacade.arrivalLocation != null;
    if (context.isBigLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDeparturePoint(context)),
              _buildJourneyConnector(context),
              Expanded(child: _buildArrivalPoint(context)),
            ],
          ),
          if (hasBothLocations)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0),
              child: DualTimezoneIndicator(
                departureLocation: transitFacade.departureLocation!,
                arrivalLocation: transitFacade.arrivalLocation!,
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeparturePoint(context),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildJourneyConnector(context),
          ),
        ),
        _buildArrivalPoint(context),
        if (hasBothLocations)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: DualTimezoneIndicator(
              departureLocation: transitFacade.departureLocation!,
              arrivalLocation: transitFacade.arrivalLocation!,
            ),
          ),
      ],
    );
  }

  Widget _buildDeparturePoint(BuildContext context) {
    return _buildJourneyPoint(
      context,
      isDeparture: true,
    );
  }

  Widget _buildArrivalPoint(BuildContext context) {
    return _buildJourneyPoint(
      context,
      isDeparture: false,
    );
  }

  Widget _buildJourneyPoint(
    BuildContext context, {
    required bool isDeparture,
  }) {
    return JourneyPointEditor(
      transitFacade: transitFacade,
      isDeparture: isDeparture,
      onLocationChanged: (newLocation) {
        onLocationChanged(isArrival: !isDeparture, newLocation: newLocation);
      },
      onDateTimeChanged: (updatedDateTime) =>
          onDateTimeChanged(updatedDateTime, isArrival: !isDeparture),
      platform: isDeparture ? transitFacade.departurePlatform : transitFacade.arrivalPlatform,
      onPlatformChanged: (newPlatform) => onPlatformChanged(isArrival: !isDeparture, newPlatform: newPlatform),
      // Pass min departure time constraint for connecting legs
      minDateTime: isDeparture ? minDepartureDateTime : null,
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
}
