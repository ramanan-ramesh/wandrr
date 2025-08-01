import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/currency_data.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

class TripCreatorDialog extends StatelessWidget {
  late final ValueNotifier<bool> _tripCreationMetadataValidityNotifier =
      ValueNotifier(false);
  final TripMetadataFacade _currentTripMetadata;
  static const String _defaultCurrency = 'INR';
  final BuildContext widgetContext;

  final TextEditingController _tripNameEditingController =
      TextEditingController();

  TripCreatorDialog({super.key, required this.widgetContext})
      : _currentTripMetadata =
            TripMetadataFacade.newUiEntry(defaultCurrency: _defaultCurrency);

  @override
  Widget build(BuildContext context) {
    var currencyInfo = widgetContext.supportedCurrencies.firstWhere((element) {
      return element.code == _currentTripMetadata.budget.currency;
    });
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 450,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _createAppBar(context),
            FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(1),
                            child: _createDatePicker(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(2),
                            child: _createTripNameField(context),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.localizations.edit_budget,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: _createBudgetEditingField(currencyInfo),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(4),
                      child: _buildCreateTripButton(context),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextField _createTripNameField(BuildContext context) {
    return TextField(
        onChanged: _updateTripName,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: context.localizations.tripName,
        ),
        controller: _tripNameEditingController);
  }

  PlatformDateRangePicker _createDatePicker() {
    return PlatformDateRangePicker(
      firstDate: DateTime.now(),
      callback: (startDate, endDate) {
        _currentTripMetadata.startDate = startDate;
        _currentTripMetadata.endDate = endDate;
        _tripCreationMetadataValidityNotifier.value =
            _currentTripMetadata.isValid();
      },
    );
  }

  Widget _createBudgetEditingField(CurrencyData currencyInfo) {
    return Column(
      children: [
        PlatformMoneyEditField(
          textInputAction: TextInputAction.done,
          allCurrencies: widgetContext.supportedCurrencies,
          selectedCurrencyData: currencyInfo,
          onAmountUpdatedCallback: (updatedAmount) {
            _currentTripMetadata.budget = Money(
                currency: _currentTripMetadata.budget.currency,
                amount: updatedAmount);
          },
          currencySelectedCallback: (selectedCurrency) {
            _currentTripMetadata.budget.currency = selectedCurrency.code;
            _tripCreationMetadataValidityNotifier.value =
                _currentTripMetadata.isValid();
          },
          isAmountEditable: true,
        ),
      ],
    );
  }

  Widget _createAppBar(BuildContext context) {
    return Material(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.hardEdge,
      child: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
        centerTitle: true,
        title: FittedBox(
          child: PlatformTextElements.createHeader(
              context: context, text: widgetContext.localizations.planTrip),
        ),
      ),
    );
  }

  void _submitTripCreationEvent() {
    var userName = widgetContext.activeUser!.userName;
    var tripMetadata = _currentTripMetadata.clone();
    tripMetadata.contributors = [userName];
    widgetContext.addTripManagementEvent(
      UpdateTripEntity<TripMetadataFacade>.create(tripEntity: tripMetadata),
    );
  }

  void _updateTripName(String newTripName) {
    _currentTripMetadata.name = newTripName;
    _tripCreationMetadataValidityNotifier.value =
        _currentTripMetadata.isValid();
  }

  Widget _buildCreateTripButton(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      icon: Icons.done_rounded,
      context: context,
      callback: () {
        _submitTripCreationEvent();
        Navigator.of(context).pop();
      },
      valueNotifier: _tripCreationMetadataValidityNotifier,
    );
  }
}
