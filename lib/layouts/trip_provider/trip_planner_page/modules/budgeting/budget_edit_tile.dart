import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/model_collection.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';

class BudgetEditTile extends StatelessWidget {
  BudgetEditTile({super.key});

  CurrencyWithValue? _currentBudget;
  final _amountEditingController = TextEditingController();
  var _budgetValidityNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    if (_currentBudget == null) {
      var currentBudget = context.getActiveTrip().tripMetadata.budget;
      _currentBudget = CurrencyWithValue(
          currency: currentBudget.currency, amount: currentBudget.amount);
    }
    var currentCurrency = _currentBudget!.currency;
    var currencyInfo =
        currencies.firstWhere((element) => element['code'] == currentCurrency);
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
                  context: context,
                  text: AppLocalizations.of(context)!.edit_budget),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: PlatformCurrencyDropDownTextField(
                    allCurrencies: currencies,
                    currencyInfo: currencyInfo,
                    amount: _currentBudget?.amount,
                    onAmountUpdatedCallback: (updatedAmount) {
                      _currentBudget!.amount = updatedAmount;
                      _budgetValidityNotifier.value = true;
                    },
                    currencySelectedCallback: (selectedCurrency) {
                      _currentBudget!.currency = selectedCurrency['code'];
                      _budgetValidityNotifier.value = true;
                    }),
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
        if (state.isTripEntity<TripMetadataModelFacade>()) {
          var updatedTripEntity = state as UpdatedTripEntity;
          if (updatedTripEntity.dataState == DataState.Update) {
            var tripMetadataModelModificationData =
                updatedTripEntity.tripEntityModificationData
                    as CollectionModificationData<TripMetadataModelFacade>;
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
            var tripManagementBloc =
                BlocProvider.of<TripManagementBloc>(context);
            var tripMetadata = context.getActiveTrip().tripMetadata;
            tripMetadata.budget = _currentBudget!;
            tripManagementBloc.add(
                UpdateTripEntity<TripMetadataModelFacade>.update(
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
