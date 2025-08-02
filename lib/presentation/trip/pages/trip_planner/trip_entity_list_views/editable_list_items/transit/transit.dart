import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/base_list_items/transit_card_base.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/transit/airport_data_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/transit/transit_operator.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/transit/transit_option_picker.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

class EditableTransitPlan extends StatefulWidget {
  final UiElement<TransitFacade> transitUiElement;
  final ValueNotifier<bool> validityNotifier;

  const EditableTransitPlan(
      {super.key,
      required this.transitUiElement,
      required this.validityNotifier});

  @override
  State<EditableTransitPlan> createState() => _EditableTransitPlanState();
}

class _EditableTransitPlanState extends State<EditableTransitPlan> {
  late UiElement<TransitFacade> _transitUiElement;

  TransitFacade get _transitFacade => _transitUiElement.element;

  @override
  void initState() {
    super.initState();
    _transitUiElement = widget.transitUiElement.clone();
    _calculateTransitValidity();
  }

  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    return TransitCardBase(
        transitOption: _createTransitOptionPicker(activeTrip),
        transitOperator: TransitOperatorEditor(
          transitOption: _transitFacade.transitOption,
          initialOperator: _transitFacade.operator,
          onOperatorChanged: (newOperator) {
            _transitFacade.operator = newOperator;
            _calculateTransitValidity();
          },
        ),
        arrivalLocation: _buildLocationEditor(true),
        arrivalDateTime: _buildDateTimePicker(true, activeTrip.tripMetadata),
        departureLocation: _buildLocationEditor(false),
        departureDateTime: _buildDateTimePicker(false, activeTrip.tripMetadata),
        expenseTile: ExpenditureEditTile(
          expenseUpdator: _transitFacade.expense,
          isEditable: true,
          callback: (paidBy, splitBy, totalExpense) {
            _transitFacade.expense.paidBy = Map.from(paidBy);
            _transitFacade.expense.splitBy = List.from(splitBy);
            _transitFacade.expense.totalExpense = totalExpense;
          },
        ),
        confirmationId: _buildConfirmationIdField(context),
        transitFacade: _transitFacade,
        notes: _buildNotesField(context),
        isEditable: true);
  }

  TransitOptionPicker _createTransitOptionPicker(TripDataFacade activeTrip) {
    return TransitOptionPicker(
      options: activeTrip.transitOptionMetadatas,
      initialTransitOption: _transitFacade.transitOption,
      onChanged: (transitOption) {
        setState(() {
          if (transitOption == TransitOption.walk ||
              transitOption == TransitOption.rentedVehicle ||
              transitOption == TransitOption.vehicle) {
            _transitFacade.operator = null;
          }
          if ((transitOption == TransitOption.flight &&
                  _transitFacade.transitOption != TransitOption.flight) ||
              (_transitFacade.transitOption == TransitOption.flight &&
                  transitOption != TransitOption.flight)) {
            _transitFacade.operator = null;
            _transitFacade.arrivalLocation = null;
            _transitFacade.departureLocation = null;
          }
          _transitFacade.transitOption = transitOption;
          _transitFacade.expense.category =
              TransitFacade.getExpenseCategory(_transitFacade.transitOption);
          _calculateTransitValidity();
        });
      },
    );
  }

  Widget _buildLocationEditor(bool isArrival) {
    var locationToConsider = isArrival
        ? _transitFacade.arrivalLocation
        : _transitFacade.departureLocation;
    return _transitFacade.transitOption == TransitOption.flight
        ? AirportsDataEditor(
            initialLocation: locationToConsider,
            onLocationSelected: (newLocation) {
              if (isArrival) {
                _transitFacade.arrivalLocation = newLocation;
              } else {
                _transitFacade.departureLocation = newLocation;
              }
            },
          )
        : PlatformGeoLocationAutoComplete(
            onLocationSelected: (newLocation) {
              if (isArrival) {
                _transitFacade.arrivalLocation = newLocation;
              } else {
                _transitFacade.departureLocation = newLocation;
              }
            },
            selectedLocation: locationToConsider,
          );
  }

  Widget _buildDateTimePicker(bool isArrival, TripMetadataFacade tripMetadata) {
    return PlatformDateTimePicker(
      dateTimeUpdated: (updatedDateTime) {
        if (isArrival) {
          _transitFacade.arrivalDateTime = updatedDateTime;
        } else {
          _transitFacade.departureDateTime = updatedDateTime;
        }
        setState(() {});
      },
      startDateTime: isArrival
          ? (_transitFacade.departureDateTime
                ?..add(const Duration(minutes: 1))) ??
              tripMetadata.startDate!
          : tripMetadata.startDate!,
      endDateTime: tripMetadata.endDate!,
      currentDateTime: isArrival
          ? _transitFacade.arrivalDateTime
          : _transitFacade.departureDateTime,
    );
  }

  Widget _buildConfirmationIdField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: '${context.localizations.confirmation} #',
      ),
      initialValue: _transitFacade.confirmationId,
      textInputAction: TextInputAction.next,
      onChanged: (newConfirmationId) {
        _transitUiElement.element.confirmationId = newConfirmationId;
      },
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return TextFormField(
      style: Theme.of(context).textTheme.labelLarge,
      decoration: InputDecoration(
        labelText: context.localizations.notes,
      ),
      initialValue: _transitFacade.notes,
      textInputAction: TextInputAction.done,
      maxLines: null,
      onChanged: (newNotes) {
        _transitUiElement.element.notes = newNotes;
      },
    );
  }

  void _calculateTransitValidity() {
    widget.validityNotifier.value = _transitUiElement.element.isValid();
  }
}
