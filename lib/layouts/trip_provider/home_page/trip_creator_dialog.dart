import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/api_services/geo_locator.dart';

class TripCreatorDialog extends StatelessWidget {
  final GeoLocator geoLocator;
  final Function(TripMetadataModelFacade tripCreationMetadata) eventSubmitter;
  late final ValueNotifier<bool> _tripCreationMetadataValidityNotifier =
      ValueNotifier(false);
  final TripMetadataModelFacade _currentTripMetadata;
  static const String _defaultCurrency = 'INR';

  final TextEditingController _tripNameEditingController =
      TextEditingController();

  TripCreatorDialog(
      {super.key, required this.geoLocator, required this.eventSubmitter})
      : _currentTripMetadata = TripMetadataModelFacade.newUiEntry(
            defaultCurrency: _defaultCurrency);

  @override
  Widget build(BuildContext context) {
    var currencyInfo = currencies.firstWhere((element) {
      return element['code'] == _currentTripMetadata.budget.currency;
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
              context: context, text: AppLocalizations.of(context)!.planTrip),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: _buildTripNameField(context),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: PlatformDateRangePicker(
                  callback: (startDate, endDate) {
                    _currentTripMetadata.startDate = startDate;
                    _currentTripMetadata.endDate = endDate;
                    _tripCreationMetadataValidityNotifier.value =
                        _isTripCreateRequestValid();
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: PlatformTextElements.createSubHeader(
                          context: context,
                          text: AppLocalizations.of(context)!
                              .chooseDefaultCurrency),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: PlatformCurrencyDropDown(
                          currencyInfo: currencyInfo,
                          allCurrencies: currencies,
                          callBack:
                              (Map<String, dynamic> selectedCurrencyInfo) {
                            _currentTripMetadata.budget.currency =
                                selectedCurrencyInfo['code'];
                            _tripCreationMetadataValidityNotifier.value =
                                _isTripCreateRequestValid();
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

  void _updateTripName(String newTripName) {
    _currentTripMetadata.name = newTripName;
    _tripCreationMetadataValidityNotifier.value = _isTripCreateRequestValid();
  }

  bool _isTripCreateRequestValid() {
    var hasValidName = _currentTripMetadata.name.isNotEmpty;
    var hasValidDateRange = _currentTripMetadata.endDate != null &&
        _currentTripMetadata.startDate != null &&
        _currentTripMetadata.endDate!
                .compareTo(_currentTripMetadata.startDate!) >
            0 &&
        _currentTripMetadata.endDate!
                .calculateDaysInBetween(_currentTripMetadata.startDate!) >=
            1;

    return hasValidName && hasValidDateRange;
  }

  Widget _buildTripNameField(BuildContext context) {
    return PlatformTextElements.createTextField(
        context: context,
        labelText: AppLocalizations.of(context)!.tripName,
        onTextChanged: _updateTripName,
        controller: _tripNameEditingController);
  }

  Widget _buildCreateTripButton(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      icon: Icons.done_rounded,
      context: context,
      callback: () {
        if (_isTripCreateRequestValid()) {
          eventSubmitter(_currentTripMetadata);
          Navigator.of(context)
              .pop(); //TODO: Animate the button to show 'Done' text, and then after a second, close the dialog
        }
      },
      valueNotifier: _tripCreationMetadataValidityNotifier,
    );
  }
}
