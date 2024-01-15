import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/trip_management.dart';

class BudgetEditTile extends StatelessWidget {
  BudgetEditTile({super.key});
  CurrencyWithValue? _currentBudget;
  final _amountEditingController = TextEditingController();
  var _budgetValidityNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    if (_currentBudget == null) {
      var currentBudget = RepositoryProvider.of<TripManagement>(context)
          .activeTrip!
          .tripMetaData
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
        color: Colors.white12,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.0),
              child: PlatformTextElements.createSubHeader(
                  context: context,
                  text: AppLocalizations.of(context)!.edit_budget),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: [
                  PlatformCurrencyDropDown(
                      currencyInfo: currencyInfo,
                      allCurrencies: currencies,
                      callBack: (newCurrencyInfo) {
                        _currentBudget!.currency = newCurrencyInfo['code'];
                        _budgetValidityNotifier.value = true;
                      }),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      onChanged: (newValue) {
                        if (newValue.isEmpty || newValue.endsWith('.')) {
                          _budgetValidityNotifier.value = false;
                          return;
                        }

                        if (double.parse(newValue) != _currentBudget!.amount) {
                          var differenceIndex = findDifferenceIndex(
                              newValue, _amountEditingController.text);
                          _amountEditingController.selection =
                              TextSelection.fromPosition(
                                  TextPosition(offset: differenceIndex));
                          _currentBudget!.amount = double.parse(newValue);
                          _budgetValidityNotifier.value = true;
                        }
                      },
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      controller: _amountEditingController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'\d+\.?\d{0,2}'))
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.0),
              child: _PlatformSubmitterFAB(
                validityNotifier: _budgetValidityNotifier,
                callback: () {
                  var tripManagementBloc =
                      BlocProvider.of<TripManagementBloc>(context);
                  var tripMetadata =
                      RepositoryProvider.of<TripManagement>(context)
                          .activeTrip!
                          .tripMetaData;
                  var tripMetadataUpdator =
                      TripMetadataUpdator.fromTripMetadata(
                          tripMetaDataFacade: tripMetadata);
                  tripMetadataUpdator.budget = _currentBudget!;
                  tripManagementBloc.add(UpdateTripMetadata.update(
                      tripMetadataUpdator: tripMetadataUpdator));
                },
                icon: Icons.save_rounded,
                buildWhen: (previousState, currentState) {
                  return currentState is UpdatedTripMetadata;
                },
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

class _PlatformSubmitterFAB extends StatefulWidget {
  const _PlatformSubmitterFAB({
    super.key,
    required ValueNotifier<bool> validityNotifier,
    required VoidCallback callback,
    required IconData icon,
    required BlocBuilderCondition<TripManagementState>? buildWhen,
  })  : _validityNotifier = validityNotifier,
        _callBack = callback,
        _icon = icon,
        _buildWhen = buildWhen;

  final IconData _icon;
  final VoidCallback _callBack;
  final ValueNotifier<bool> _validityNotifier;
  final BlocBuilderCondition<TripManagementState>? _buildWhen;

  @override
  State<_PlatformSubmitterFAB> createState() => _PlatformSubmitterFABState();
}

class _PlatformSubmitterFABState extends State<_PlatformSubmitterFAB> {
  var _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        widget._validityNotifier.value = false;
        _isSubmitted = false;
        return ValueListenableBuilder<bool>(
          valueListenable: widget._validityNotifier,
          builder: (BuildContext context, bool value, Widget? child) {
            return FloatingActionButton(
              backgroundColor: value ? Colors.black : Colors.white12,
              onPressed: () {
                if (!_isSubmitted) {
                  widget._callBack();
                  setState(() {
                    _isSubmitted = true;
                  });
                }
              },
              child: _isSubmitted
                  ? CircularProgressIndicator()
                  : Icon(
                      widget._icon,
                      color: Colors.white,
                    ),
            );
          },
        );
      },
      buildWhen: widget._buildWhen,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
