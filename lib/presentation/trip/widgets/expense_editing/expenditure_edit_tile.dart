import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

import 'paid_by_tab.dart';
import 'split_by_tab.dart';

class ExpenditureEditTile extends StatefulWidget {
  final Map<String, double> paidBy;
  final List<String> splitBy;
  final String currency;
  final bool isEditable;
  final void Function(
          Map<String, double> paidBy, List<String> splitBy, Money totalExpense)?
      callback;

  ExpenditureEditTile(
      {required ExpenseFacade expenseFacade,
      required this.isEditable,
      super.key,
      this.callback})
      : paidBy = expenseFacade.paidBy,
        splitBy = expenseFacade.splitBy,
        currency = expenseFacade.totalExpense.currency;

  @override
  State<ExpenditureEditTile> createState() => _ExpenditureEditTileState();
}

class _ExpenditureEditTileState extends State<ExpenditureEditTile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late CurrencyData _currentCurrencyInfo;
  final Map<String, Color> _contributorsVsColors = {};
  late final ValueNotifier<Money> _totalExpenseValueNotifier;
  late Map<String, double> _currentPaidBy;
  late List<String> _currentSplitBy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _totalExpenseValueNotifier = ValueNotifier<Money>(Money(
        currency: widget.currency,
        amount: widget.paidBy.values
            .fold(0.0, (previousValue, element) => previousValue + element)));
    _initializeExpense();
  }

  @override
  void didUpdateWidget(covariant ExpenditureEditTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.paidBy, _currentPaidBy) ||
        !listEquals(oldWidget.splitBy, _currentSplitBy) ||
        oldWidget.currency != _currentCurrencyInfo.code) {
      setState(_initializeExpense);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeContributors(context);
    if (widget.isEditable) {
      if (_contributorsVsColors.length == 1) {
        return _createTotalExpenseField(context, true);
      }
      return _createEditorForMultipleContributors(context);
    } else {
      return _createReadonlyExpenditureTile(context);
    }
  }

  void _initializeExpense() {
    _currentPaidBy = Map.from(widget.paidBy);
    _currentSplitBy = List.from(widget.splitBy);
    _currentCurrencyInfo = context.supportedCurrencies
        .firstWhere((element) => element.code == widget.currency);
    _recalculateTotalExpense();
  }

  void _recalculateTotalExpense() {
    _totalExpenseValueNotifier.value = Money(
        currency: _currentCurrencyInfo.code,
        amount: _currentPaidBy.values
            .fold(0.0, (previousValue, element) => previousValue + element));
  }

  Widget _createEditorForMultipleContributors(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ValueListenableBuilder(
              valueListenable: _totalExpenseValueNotifier,
              builder: (context, value, child) {
                return _createTotalExpenseField(context, false);
              }),
        ),
        _buildTabBar(context),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300, minHeight: 200),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPaidByTab(),
              _buildSplitByPage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createReadonlyExpenditureTile(BuildContext context) {
    var formattedText = context.activeTrip.budgetingModule
        .formatCurrency(_totalExpenseValueNotifier.value);
    var columnItems = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: PlatformTextElements.createSubHeader(
              context: context,
              shouldBold: widget.isEditable,
              text: formattedText),
        ),
      ),
    ];
    var shouldHideSplitByData = _totalExpenseValueNotifier.value.amount == 0 ||
        _currentSplitBy.isEmpty ||
        _currentSplitBy.length == 1 &&
            _currentSplitBy.single == context.activeUser!.userName;
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

  Widget _createTotalExpenseField(
      BuildContext context, bool canEditAmountField) {
    return PlatformMoneyEditField(
      isAmountEditable: canEditAmountField,
      initialAmount: _totalExpenseValueNotifier.value.amount,
      allCurrencies: context.supportedCurrencies,
      selectedCurrency: _currentCurrencyInfo,
      onAmountUpdated: (_) {
        _currentPaidBy[context.activeUser!.userName] = _;
        _recalculateTotalExpense();
        _invokeUpdatedCallback();
      },
      onCurrencySelected: (_) {
        setState(() {
          _currentCurrencyInfo = _;
          _recalculateTotalExpense();
          _invokeUpdatedCallback();
        });
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return ChromeTabBar(
      iconsAndTitles: {
        Icons.payments_rounded: context.localizations.paidBy,
        Icons.group_rounded: 'Split Among',
      },
      tabController: _tabController,
    );
  }

  void _invokeUpdatedCallback() {
    widget.callback?.call(
        _currentPaidBy, _currentSplitBy, _totalExpenseValueNotifier.value);
  }

  void _initializeContributors(BuildContext context) {
    var contributors = context.activeTrip.tripMetadata.contributors;
    var allContributors = List.from(contributors);
    allContributors.sort();
    for (var index = 0; index < allContributors.length; index++) {
      var contributor = allContributors.elementAt(index);
      _contributorsVsColors[contributor] = AppColors.travelAccents[index];
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
      contributorsVsColors: _contributorsVsColors,
      paidBy: _currentPaidBy,
      callback: (paidBy) {
        _currentPaidBy = Map.from(paidBy);
        _recalculateTotalExpense();
        _invokeUpdatedCallback();
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
