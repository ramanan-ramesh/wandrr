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

import 'journey_point_editor.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransitTypeBadge(),
        if (_needsPriorBooking) _buildOperatorSection(),
        _JourneySection(
          transitFacade: _transitFacade,
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
            title: 'Payment Details',
            iconColor: Theme.of(context).brightness == Brightness.light
                ? AppColors.warning
                : AppColors.warningLight,
          ),
          const SizedBox(height: 12),
          ExpenditureEditTile(
            expenseFacade: _transitFacade.expense,
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
        widget.onTransitUpdated();
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
            widget.onTransitUpdated();
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
    widget.onTransitUpdated();
  }

  void _handleOperatorChanged(String? newOperator) {
    _transitFacade.operator = newOperator;
    widget.onTransitUpdated();
  }

  void _updateLocation(bool isArrival, LocationFacade? newLocation) {
    setState(() {
      if (isArrival) {
        _transitFacade.arrivalLocation = newLocation;
      } else {
        _transitFacade.departureLocation = newLocation;
      }
    });
    widget.onTransitUpdated();
  }

  void _updateDateTime(bool isArrival, DateTime updatedDateTime) {
    setState(() {
      if (isArrival) {
        _transitFacade.arrivalDateTime = updatedDateTime;
      } else {
        _transitFacade.departureDateTime = updatedDateTime;
      }
    });
    widget.onTransitUpdated();
  }
}

class _JourneySection extends StatelessWidget {
  final TransitFacade transitFacade;
  final void Function(bool isArrival, LocationFacade? newLocation)
      onLocationChanged;
  final void Function(bool isArrival, DateTime updatedDateTime)
      onDateTimeChanged;

  const _JourneySection({
    Key? key,
    required this.transitFacade,
    required this.onLocationChanged,
    required this.onDateTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (context.isBigLayout) {
      return Row(
        children: [
          Expanded(child: _buildDeparturePoint(context)),
          _buildJourneyConnector(context),
          Expanded(child: _buildArrivalPoint(context)),
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
        onLocationChanged(!isDeparture, newLocation);
      },
      onDateTimeChanged: (updatedDateTime) =>
          onDateTimeChanged(!isDeparture, updatedDateTime),
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
