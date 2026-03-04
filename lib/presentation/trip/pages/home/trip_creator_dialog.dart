import 'package:flutter/material.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/asset_manager/extension.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';
import 'package:wandrr/presentation/trip/widgets/unified_trip_dialog.dart';

import 'thumbnail_selector.dart';

class TripCreatorDialog extends StatelessWidget {
  static const String _defaultCurrency = 'INR';

  final TripMetadataFacade _currentTripMetadata;
  final BuildContext widgetContext;

  late final ValueNotifier<bool> _tripCreationMetadataValidityNotifier =
      ValueNotifier(false);
  final TextEditingController _tripNameEditingController =
      TextEditingController();
  final SizedBox _formElementsSpacer = const SizedBox(height: 8.0);

  TripCreatorDialog({required this.widgetContext, super.key})
      : _currentTripMetadata = TripMetadataFacade.newUiEntry(
            defaultCurrency: _defaultCurrency,
            thumbnailTag: Assets.images.tripThumbnails.roadTrip.fileName);

  @override
  Widget build(BuildContext context) {
    var currencyInfo = widgetContext.supportedCurrencies.firstWhere((element) {
      return element.code == _currentTripMetadata.budget.currency;
    });

    return UnifiedTripDialog(
      title: widgetContext.localizations.planTrip,
      icon: const Icon(Icons.auto_awesome_rounded),
      content: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          children: [
            _createThumbnailPicker(context),
            _formElementsSpacer,
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: _createDatePicker(),
            ),
            _formElementsSpacer,
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: _createTripNameField(context),
            ),
            _formElementsSpacer,
            _createBudgetEditor(context, currencyInfo),
          ],
        ),
      ),
      actions: [
        _buildCreateTripButton(context),
      ],
    );
  }

  Widget _createBudgetEditor(BuildContext context, CurrencyData currencyInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            context.localizations.edit_budget,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        FocusTraversalOrder(
          order: const NumericFocusOrder(3),
          child: _createBudgetEditingField(currencyInfo),
        ),
      ],
    );
  }

  Widget _createThumbnailPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            widgetContext.localizations.chooseTripThumbnail,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _formElementsSpacer,
        TripThumbnailCarouselSelector(
          selectedThumbnailTag: _currentTripMetadata.thumbnailTag,
          onChanged: (thumbnailTag) {
            _currentTripMetadata.thumbnailTag = thumbnailTag;
          },
        ),
      ],
    );
  }

  TextField _createTripNameField(BuildContext context) {
    return TextField(
      key: Key('TripCreatorDialog_TripNameField'),
      onChanged: _updateTripName,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: context.localizations.tripName,
      ),
      controller: _tripNameEditingController,
    );
  }

  PlatformDateRangePicker _createDatePicker() {
    return PlatformDateRangePicker(
      firstDate: DateTime.now(),
      callback: (startDate, endDate) {
        _currentTripMetadata.startDate = startDate;
        _currentTripMetadata.endDate = endDate;
        _tripCreationMetadataValidityNotifier.value =
            _currentTripMetadata.validate();
      },
    );
  }

  Widget _createBudgetEditingField(CurrencyData currencyInfo) {
    return PlatformMoneyEditField(
      textInputAction: TextInputAction.done,
      allCurrencies: widgetContext.supportedCurrencies,
      selectedCurrency: currencyInfo,
      onAmountUpdated: (updatedAmount) {
        _currentTripMetadata.budget = Money(
            currency: _currentTripMetadata.budget.currency,
            amount: updatedAmount);
      },
      onCurrencySelected: (selectedCurrency) {
        _currentTripMetadata.budget = Money(
            currency: selectedCurrency.code,
            amount: _currentTripMetadata.budget.amount);
        _tripCreationMetadataValidityNotifier.value =
            _currentTripMetadata.validate();
      },
      isAmountEditable: true,
    );
  }

  void _updateTripName(String newTripName) {
    _currentTripMetadata.name = newTripName;
    _tripCreationMetadataValidityNotifier.value =
        _currentTripMetadata.validate();
  }

  Widget _buildCreateTripButton(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      child: const Icon(Icons.done_rounded),
      callback: () {
        _submitTripCreationEvent();
        Navigator.of(context).pop();
      },
      valueNotifier: _tripCreationMetadataValidityNotifier,
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
}
