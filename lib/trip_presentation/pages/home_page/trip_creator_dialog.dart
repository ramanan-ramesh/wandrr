import 'package:flutter/material.dart';
import 'package:wandrr/api_services/models/currency_data.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/app_presentation/widgets/date_range_pickers.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';
import 'package:wandrr/trip_presentation/widgets/currency_drop_down.dart';

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
    var currencyInfo = context.getSupportedCurrencies().firstWhere((element) {
      return element.code == _currentTripMetadata.budget.currency;
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            //TODO: Unable to style splashColor here
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close_rounded,
            ),
          ),
          centerTitle: true,
          title: PlatformTextElements.createHeader(
              context: context, text: context.withLocale().planTrip),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: PlatformDateRangePicker(
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
                child: _buildTripNameField(context),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: PlatformTextElements.createSubHeader(
                          context: context,
                          text: context.withLocale().chooseDefaultCurrency),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: PlatformCurrencyDropDown(
                          selectedCurrencyData: currencyInfo,
                          allCurrencies: widgetContext.getSupportedCurrencies(),
                          currencySelectedCallback:
                              (CurrencyData selectedCurrencyInfo) {
                            _currentTripMetadata.budget.currency =
                                selectedCurrencyInfo.code;
                            _tripCreationMetadataValidityNotifier.value =
                                _currentTripMetadata.isValid();
                          },
                        ),
                      ),
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
    var userName = widgetContext.getAppLevelData().activeUser!.userName;
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

  Widget _buildTripNameField(BuildContext context) {
    return PlatformTextElements.createTextField(
        context: context,
        labelText: context.withLocale().tripName,
        onTextChanged: _updateTripName,
        controller: _tripNameEditingController);
  }

  Widget _buildCreateTripButton(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      icon: Icons.done_rounded,
      context: context,
      callback: () {
        if (_currentTripMetadata.isValid()) {
          _submitTripCreationEvent();
          Navigator.of(context)
              .pop(); //TODO: Animate the button to show 'Done' text, and then after a second, close the dialog
        }
      },
      valueNotifier: _tripCreationMetadataValidityNotifier,
    );
  }
}
