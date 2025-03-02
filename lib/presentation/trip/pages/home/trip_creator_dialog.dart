import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close_rounded,
            ),
          ),
          centerTitle: true,
          title: FittedBox(
            child: PlatformTextElements.createHeader(
                context: context, text: widgetContext.localizations.planTrip),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: PlatformDateRangePicker(
                  firstDate: DateTime.now(),
                  callback: (startDate, endDate) {
                    _currentTripMetadata.startDate = startDate;
                    _currentTripMetadata.endDate = endDate;
                    _tripCreationMetadataValidityNotifier.value =
                        _currentTripMetadata.isValid();
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                    onChanged: _updateTripName,
                    decoration: InputDecoration(
                      labelText: context.localizations.tripName,
                    ),
                    controller: _tripNameEditingController),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(context.localizations.setBudgetAndCurrency),
                    PlatformMoneyEditField(
                      allCurrencies: widgetContext.supportedCurrencies,
                      selectedCurrencyData: currencyInfo,
                      onAmountUpdatedCallback: (updatedAmount) {
                        _currentTripMetadata.budget = Money(
                            currency: _currentTripMetadata.budget.currency,
                            amount: updatedAmount);
                      },
                      currencySelectedCallback: (selectedCurrency) {
                        _currentTripMetadata.budget.currency =
                            selectedCurrency.code;
                        _tripCreationMetadataValidityNotifier.value =
                            _currentTripMetadata.isValid();
                      },
                      isAmountEditable: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: _buildCreateTripButton(context),
        )
      ],
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
        if (_currentTripMetadata.isValid()) {
          _submitTripCreationEvent();
          Navigator.of(context).pop();
        }
      },
      valueNotifier: _tripCreationMetadataValidityNotifier,
    );
  }
}
