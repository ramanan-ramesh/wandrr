import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';
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
      var currentBudget =
          RepositoryProvider.of<TripRepositoryModelFacade>(context)
              .activeTrip!
              .tripMetadata
              .budget;
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
              child: PlatformSubmitterFAB.conditionallyEnabled(
                valueNotifier: _budgetValidityNotifier,
                callback: () {
                  var tripManagementBloc =
                      BlocProvider.of<TripManagementBloc>(context);
                  var tripMetadata =
                      RepositoryProvider.of<TripRepositoryModelFacade>(context)
                          .activeTrip!
                          .tripMetadata;
                  tripMetadata.budget = _currentBudget!;
                  tripManagementBloc.add(
                      UpdateTripEntity<TripMetadataModelFacade>.update(
                          tripEntity: tripMetadata));
                },
                icon: Icons.save_rounded,
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int findDifferenceIndex(String newValue, String currentValue) {
    if (currentValue.isEmpty) {
      return newValue.length;
    }
    if (newValue.isEmpty) {
      return 0;
    }
    if (newValue.length > currentValue.length) {
      for (int i = 0; i < currentValue.length; i++) {
        if (newValue[i] != currentValue[i]) {
          return i + 1;
        }
      }
      return newValue.length;
    } else if (newValue.length < currentValue.length) {
      for (int i = 0; i < newValue.length; i++) {
        if (newValue[i] != currentValue[i]) {
          return i + 1;
        }
      }
      return newValue.length;
    }
    for (int i = 0; i < newValue.length; i++) {
      if (newValue[i] != currentValue[i]) {
        return i + 1;
      }
    }
    return newValue.length; // Strings are equal
  }
}
