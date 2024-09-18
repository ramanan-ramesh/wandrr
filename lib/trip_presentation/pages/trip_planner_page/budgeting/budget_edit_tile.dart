import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/collection_change_metadata.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/money.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';
import 'package:wandrr/trip_presentation/widgets/money_edit_field.dart';

class BudgetEditTile extends StatelessWidget {
  BudgetEditTile({super.key});

  Money? _currentBudget;
  final _amountEditingController = TextEditingController();
  final _budgetValidityNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    if (_currentBudget == null) {
      var currentBudget = context.getActiveTrip().tripMetadata.budget;
      _currentBudget =
          Money(currency: currentBudget.currency, amount: currentBudget.amount);
    }
    var currentCurrency = _currentBudget!.currency;
    var allCurrencies = context.getSupportedCurrencies();
    var currencyInfo =
        allCurrencies.firstWhere((element) => element.code == currentCurrency);
    _amountEditingController.text = _currentBudget!.amount.toString();
    return SliverToBoxAdapter(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.0),
              child: PlatformTextElements.createSubHeader(
                  context: context, text: context.withLocale().edit_budget),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: PlatformMoneyEditField(
                  allCurrencies: context.getSupportedCurrencies(),
                  selectedCurrencyData: currencyInfo,
                  amount: _currentBudget?.amount,
                  onAmountUpdatedCallback: (updatedAmount) {
                    _currentBudget!.amount = updatedAmount;
                    _budgetValidityNotifier.value = true;
                  },
                  currencySelectedCallback: (selectedCurrency) {
                    _currentBudget!.currency = selectedCurrency.code;
                    _budgetValidityNotifier.value = true;
                  },
                  isAmountEditable: true,
                ),
                // child: Row(
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.0),
              child: _buildUpdateBudgetButton(),
            ),
          ],
        ),
      ),
    );
  }

  BlocConsumer<TripManagementBloc, TripManagementState>
      _buildUpdateBudgetButton() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        if (state.isTripEntity<TripMetadataFacade>()) {
          var updatedTripEntity = state as UpdatedTripEntity;
          if (updatedTripEntity.dataState == DataState.Update) {
            var tripMetadataModelModificationData =
                updatedTripEntity.tripEntityModificationData
                    as CollectionChangeMetadata<TripMetadataFacade>;
            if (tripMetadataModelModificationData.isFromEvent) {
              if (tripMetadataModelModificationData
                      .modifiedCollectionItem.budget !=
                  _currentBudget) {
                _currentBudget = tripMetadataModelModificationData
                    .modifiedCollectionItem.budget;
                _amountEditingController.text =
                    _currentBudget!.amount.toString();
              }
            }
          }
        }
        return PlatformSubmitterFAB.conditionallyEnabled(
          valueNotifier: _budgetValidityNotifier,
          isSubmitted: false,
          callback: () {
            var tripMetadata = context.getActiveTrip().tripMetadata;
            tripMetadata.budget = _currentBudget!;
            context.addTripManagementEvent(
                UpdateTripEntity<TripMetadataFacade>.update(
                    tripEntity: tripMetadata));
          },
          icon: Icons.save_rounded,
          context: context,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
