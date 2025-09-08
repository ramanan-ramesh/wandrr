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
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/theming/constants.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

import 'thumbnail_selector.dart';

class TripCreatorDialog extends StatelessWidget {
  static const String _defaultCurrency = 'INR';

  final TripMetadataFacade _currentTripMetadata;
  final BuildContext widgetContext;

  late final ValueNotifier<bool> _tripCreationMetadataValidityNotifier =
      ValueNotifier(false);
  final TextEditingController _tripNameEditingController =
      TextEditingController();

  TripCreatorDialog({required this.widgetContext, super.key})
      : _currentTripMetadata = TripMetadataFacade.newUiEntry(
            defaultCurrency: _defaultCurrency,
            thumbnailTag: Assets.images.tripThumbnails.roadTrip.fileName);

  @override
  Widget build(BuildContext context) {
    final isBig = context.isBigLayout;
    var currencyInfo = widgetContext.supportedCurrencies.firstWhere((element) {
      return element.code == _currentTripMetadata.budget.currency;
    });
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: isBig ? 800.0 : 600.0,
          maxWidth: isBig ? 600.0 : 400.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _createAppBar(context),
            FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                child: Column(
                  children: [
                    _createThumbnailPicker(context),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(4),
                        child: _buildCreateTripButton(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createThumbnailPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widgetContext.localizations.chooseTripThumbnail,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
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
            _currentTripMetadata.validate();
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
            _currentTripMetadata.budget = Money(
                currency: selectedCurrency.code,
                amount: _currentTripMetadata.budget.amount);
            _tripCreationMetadataValidityNotifier.value =
                _currentTripMetadata.validate();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(ThemeConstants.appBarBorderRadius)),
        ),
        leading: Builder(
          builder: (context) {
            final isLight = Theme.of(context).brightness == Brightness.light;
            return Align(
              alignment: Alignment.center,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: isLight
                    ? ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(AppColors.brandSecondary),
                      )
                    : null,
                icon: Icon(
                  Icons.close_rounded,
                  size: 26,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        title: FittedBox(
          child: PlatformTextElements.createHeader(
              context: context, text: widgetContext.localizations.planTrip),
        ),
      ),
    );
  }

  void _updateTripName(String newTripName) {
    _currentTripMetadata.name = newTripName;
    _tripCreationMetadataValidityNotifier.value =
        _currentTripMetadata.validate();
  }

  Widget _buildCreateTripButton(BuildContext context) {
    return PlatformSubmitterFAB.conditionallyEnabled(
      icon: Icons.done_rounded,
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
