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
  final Transit initialTransit;
  final void Function(Transit updated) onTransitUpdated;

  const TravelEditor(
      {required this.initialTransit,
      required this.onTransitUpdated,
      super.key});

  // Legacy constructor for backward compatibility
  factory TravelEditor.legacy({
    required Transit transitFacade,
    required VoidCallback onTransitUpdated,
  }) {
    // Note: This doesn't propagate changes back properly
    throw UnimplementedError('Use new constructor with callback');
  }

  @override
  State<TravelEditor> createState() => _TravelEditorState();
}

class _TravelEditorState extends State<TravelEditor>
    with SingleTickerProviderStateMixin {
  late Transit _transit;

  @override
  void initState() {
    super.initState();
    _transit = widget.initialTransit;
  }

  @override
  void didUpdateWidget(covariant TravelEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTransit != widget.initialTransit) {
      _transit = widget.initialTransit;
      setState(() {});
    }
  }

  void _updateTransit(Transit updated) {
    setState(() {
      _transit = updated;
    });
    widget.onTransitUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransitTypeBadge(),
        if (_needsPriorBooking) _buildOperatorSection(),
        _JourneySection(
          transitFacade: _transit,
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
            expenseFacade: _transit.expense,
            isEditable: true,
            callback: _handleExpenseUpdated,
          ),
        ],
      ),
    );
  }

  bool get _needsPriorBooking {
    final option = _transit.transitOption;
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
        initialTransitOption: _transit.transitOption,
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
    final optionsWithoutOperator = [
      TransitOption.walk,
      TransitOption.rentedVehicle,
      TransitOption.vehicle,
    ];

    final isChangingToFlight = newOption == TransitOption.flight &&
        _transit.transitOption != TransitOption.flight;
    final isChangingFromFlight =
        _transit.transitOption == TransitOption.flight &&
            newOption != TransitOption.flight;

    var updated = _transit.copyWith(
      transitOption: newOption,
      expense: _transit.expense.copyWith(
        category: Transit.getExpenseCategory(newOption),
      ),
    );

    // Clear operator if not needed
    if (optionsWithoutOperator.contains(newOption)) {
      updated = updated.copyWith(operator: null);
    }

    // Clear flight data when switching to/from flight
    if (isChangingToFlight || isChangingFromFlight) {
      // Need to create a new draft since we're setting locations to null
      updated = Transit.draft(
        tripId: updated.tripId,
        id: updated.id,
        transitOption: updated.transitOption,
        expense: updated.expense,
        departureLocation: null,
        departureDateTime: updated.departureDateTime,
        arrivalLocation: null,
        arrivalDateTime: updated.arrivalDateTime,
        operator: null,
        confirmationId: updated.confirmationId,
        notes: updated.notes,
      );
    }

    _updateTransit(updated);
  }

  Widget _buildOperatorSection() {
    return TransitOperatorEditorSection(
      transitOption: _transit.transitOption,
      initialOperator: _transit.operator,
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
      initialValue: _transit.confirmationId,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _updateTransit(_transit.copyWith(confirmationId: value));
      },
    );
  }

  Widget _buildNotesSection() {
    var note = Note(_transit.notes);
    return EditorTheme.createSection(
      context: context,
      child: NoteEditor(
          note: note,
          onChanged: () {
            _updateTransit(_transit.copyWith(notes: note.text));
          }),
    );
  }

  void _handleExpenseUpdated(
    Map<String, double> paidBy,
    List<String> splitBy,
    Money totalExpense,
  ) {
    _updateTransit(_transit.copyWith(
      expense: _transit.expense.copyWith(
        paidBy: Map.from(paidBy),
        splitBy: List.from(splitBy),
        currency: totalExpense.currency,
      ),
    ));
  }

  void _handleOperatorChanged(String? newOperator) {
    _updateTransit(_transit.copyWith(operator: newOperator));
  }

  void _updateLocation(bool isArrival, Location? newLocation) {
    // For nullable location updates, we may need to use draft if setting to null
    // or if the model is strict and we can't use copyWith with nullable
    Transit updated;
    if (newLocation != null) {
      if (isArrival) {
        updated = _transit.copyWith(arrivalLocation: newLocation);
      } else {
        updated = _transit.copyWith(departureLocation: newLocation);
      }
    } else {
      // Create a draft to allow null locations
      updated = Transit.draft(
        tripId: _transit.tripId,
        id: _transit.id,
        transitOption: _transit.transitOption,
        expense: _transit.expense,
        departureLocation: isArrival ? _transit.departureLocation : null,
        departureDateTime: _transit.departureDateTime,
        arrivalLocation: isArrival ? null : _transit.arrivalLocation,
        arrivalDateTime: _transit.arrivalDateTime,
        operator: _transit.operator,
        confirmationId: _transit.confirmationId,
        notes: _transit.notes,
      );
    }
    _updateTransit(updated);
  }

  void _updateDateTime(bool isArrival, DateTime updatedDateTime) {
    if (isArrival) {
      _updateTransit(_transit.copyWith(arrivalDateTime: updatedDateTime));
    } else {
      _updateTransit(_transit.copyWith(departureDateTime: updatedDateTime));
    }
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
