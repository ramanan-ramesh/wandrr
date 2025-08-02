import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/currency_data.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
import 'package:wandrr/presentation/app/widgets/tab_bar.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/currency_drop_down.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

import 'paid_by_tab.dart';
import 'split_by_tab.dart';

class ExpenditureEditTile extends StatefulWidget {
  final Map<String, double> paidBy;
  final List<String> splitBy;
  final Money totalExpense;
  final bool isEditable;
  final void Function(
          Map<String, double> paidBy, List<String> splitBy, Money totalExpense)?
      callback;

  ExpenditureEditTile(
      {super.key,
      required ExpenseFacade expenseUpdator,
      this.callback,
      required this.isEditable})
      : paidBy = expenseUpdator.paidBy,
        splitBy = expenseUpdator.splitBy,
        totalExpense = expenseUpdator.totalExpense;

  @override
  State<ExpenditureEditTile> createState() => _ExpenditureEditTileState();
}

class _ExpenditureEditTileState extends State<ExpenditureEditTile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CurrencyData _currentCurrencyInfo;
  final Map<String, Color> _contributorsVsColors = {};
  static const double _heightPerItem = 40;
  late ValueNotifier<Money> _totalExpenseValueNotifier;
  late Map<String, double> _currentPaidBy;
  late List<String> _currentSplitBy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentPaidBy = Map.from(widget.paidBy);
    _currentSplitBy = List.from(widget.splitBy);
    _totalExpenseValueNotifier = ValueNotifier(widget.totalExpense);
  }

  @override
  Widget build(BuildContext context) {
    _initializeContributors(context);
    _totalExpenseValueNotifier.value = widget.totalExpense;
    if (widget.isEditable) {
      return _createEditableExpenditureTile(context);
    } else {
      return _createReadonlyExpenditureTile(context);
    }
  }

  Column _createReadonlyExpenditureTile(BuildContext context) {
    var columnItems = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: PlatformTextElements.createSubHeader(
              context: context,
              shouldBold: widget.isEditable,
              text: _totalExpenseValueNotifier.value.toString()),
        ),
      ),
    ];
    var shouldHideSplitByData = widget.totalExpense.amount == 0 ||
        widget.splitBy.isEmpty ||
        widget.splitBy.length == 1 &&
            widget.splitBy.single == context.activeUser!.userName;
    if (!shouldHideSplitByData) {
      columnItems.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          '${context.localizations.splitBy} : ',
        ),
      ));
      columnItems.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: _buildSplitByIcons(),
      ));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: columnItems,
    );
  }

  Widget _createEditableExpenditureTile(BuildContext context) {
    if (_contributorsVsColors.length == 1) {
      var currentUserName = context.activeUser!.userName;
      var allCurrencies = context.supportedCurrencies;
      return PlatformMoneyEditField(
        isAmountEditable: true,
        initialAmount: _totalExpenseValueNotifier.value.amount,
        allCurrencies: allCurrencies,
        selectedCurrencyData: _currentCurrencyInfo,
        onAmountUpdatedCallback: (updatedAmount) {
          _currentPaidBy[currentUserName] = updatedAmount;
          _totalExpenseValueNotifier.value =
              Money(currency: _currentCurrencyInfo.code, amount: updatedAmount);
          _invokeUpdatedCallback();
        },
        currencySelectedCallback: (CurrencyData selectedCurrencyInfo) {
          setState(() {
            _currentCurrencyInfo = selectedCurrencyInfo;
            _totalExpenseValueNotifier.value = Money(
                currency: selectedCurrencyInfo.code,
                amount: _totalExpenseValueNotifier.value.amount);
            _invokeUpdatedCallback();
          });
        },
      );
    }
    return PlatformCard(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: _createTotalExpenseIndicator(context),
            ),
            PlatformTabBar(
              tabBarItems: <String, Widget>{
                context.localizations.paidBy: _buildPaidByTab(),
                context.localizations.split: _buildSplitByPage(),
              },
              tabController: _tabController,
              maxTabViewHeight:
                  (_contributorsVsColors.length + 1) * _heightPerItem,
            ),
          ],
        ),
      ),
    );
  }

  Row _createTotalExpenseIndicator(BuildContext context) {
    return Row(
      children: [
        ValueListenableBuilder<Money>(
          valueListenable: _totalExpenseValueNotifier,
          builder: (BuildContext context, Money value, Widget? child) {
            return PlatformTextElements.createSubHeader(
                context: context,
                shouldBold: widget.isEditable,
                text: value.amount.toStringAsFixed(2));
          },
        ),
        Flexible(
          child: PlatformCurrencyDropDown(
              selectedCurrencyData: _currentCurrencyInfo,
              allCurrencies: context.supportedCurrencies,
              currencySelectedCallback: (currencyInfo) {
                if (currencyInfo.name != _currentCurrencyInfo.name) {
                  setState(() {
                    _totalExpenseValueNotifier.value = Money(
                        currency: currencyInfo.code,
                        amount: _totalExpenseValueNotifier.value.amount);
                    _currentCurrencyInfo = currencyInfo;
                    _invokeUpdatedCallback();
                  });
                }
              }),
        ),
      ],
    );
  }

  void _invokeUpdatedCallback() {
    if (widget.callback != null) {
      widget.callback!(
          _currentPaidBy, _currentSplitBy, _totalExpenseValueNotifier.value);
    }
  }

  void _initializeContributors(BuildContext context) {
    var contributors = context.activeTrip.tripMetadata.contributors;
    var allContributors = List.from(contributors);
    allContributors.sort();
    for (int index = 0; index < allContributors.length; index++) {
      var contributor = allContributors.elementAt(index);
      _contributorsVsColors[contributor] = contributorColors[index];
    }
    _currentCurrencyInfo = context.supportedCurrencies.firstWhere(
        (element) => element.code == _totalExpenseValueNotifier.value.currency);
  }

  Widget _buildSplitByIcons() {
    return Wrap(
      children: _contributorsVsColors.entries
          .where((element) => _currentSplitBy.contains(element.key))
          .map((e) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: e.value,
                    shape: BoxShape.circle,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPaidByTab() {
    return PaidByTab(
      heightPerItem: _heightPerItem,
      contributorsVsColors: _contributorsVsColors,
      paidBy: _currentPaidBy,
      callback: (paidBy) {
        _currentPaidBy = Map.from(paidBy);
        var totalExpenseAmount = _currentPaidBy.values
            .fold(0.0, (previousValue, element) => previousValue + element);
        if (totalExpenseAmount != _totalExpenseValueNotifier.value.amount) {
          _totalExpenseValueNotifier.value = Money(
              currency: _totalExpenseValueNotifier.value.currency,
              amount: totalExpenseAmount);
          _invokeUpdatedCallback();
        }
      },
      defaultCurrencySymbol: _currentCurrencyInfo.symbol,
    );
  }

  Widget _buildSplitByPage() {
    return SplitByTab(
        callback: (splitBy) {
          _currentSplitBy = List.from(splitBy);
          _invokeUpdatedCallback();
        },
        splitBy: _currentSplitBy,
        contributorsVsColors: _contributorsVsColors);
  }
}
