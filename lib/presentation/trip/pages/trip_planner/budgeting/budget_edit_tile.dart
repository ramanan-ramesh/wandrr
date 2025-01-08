import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

class BudgetEditTile extends StatefulWidget {
  BudgetEditTile({super.key});

  @override
  State<BudgetEditTile> createState() => _BudgetEditTileState();
}

class _BudgetEditTileState extends State<BudgetEditTile> {
  Money? _currentBudget;

  final _amountEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_currentBudget == null) {
      var currentBudget = context.activeTrip.tripMetadata.budget;
      _currentBudget =
          Money(currency: currentBudget.currency, amount: currentBudget.amount);
    }
    var currentCurrency = _currentBudget!.currency;
    var allCurrencies = context.supportedCurrencies;
    var currencyInfo =
        allCurrencies.firstWhere((element) => element.code == currentCurrency);
    _amountEditingController.text = _currentBudget!.amount.toString();
    return SliverToBoxAdapter(
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.0),
              child: PlatformTextElements.createSubHeader(
                  context: context, text: context.localizations.edit_budget),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: PlatformMoneyEditField(
                  allCurrencies: context.supportedCurrencies,
                  selectedCurrencyData: currencyInfo,
                  amount: _currentBudget?.amount,
                  onAmountUpdatedCallback: (updatedAmount) {
                    _currentBudget!.amount = updatedAmount;
                  },
                  currencySelectedCallback: (selectedCurrency) {
                    setState(() {
                      _currentBudget!.currency = selectedCurrency.code;
                    });
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

  Widget _buildUpdateBudgetButton() {
    _amountEditingController.text = _currentBudget!.amount.toString();
    return FloatingActionButton(
      onPressed: () {
        var tripMetadata = context.activeTrip.tripMetadata;
        tripMetadata.budget = _currentBudget!;
        context.addTripManagementEvent(
            UpdateTripEntity<TripMetadataFacade>.update(
                tripEntity: tripMetadata));
      },
      child: Icon(Icons.save_rounded),
    );
  }
}
