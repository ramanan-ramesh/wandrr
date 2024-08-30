import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/layouts/constants.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

class ExpenditureEditTile extends StatefulWidget {
  Map<String, double> paidBy;
  List<String> splitBy;
  CurrencyWithValue totalExpense;
  bool isEditable;

  //TODO: Don't invoke this callback with nullables
  void Function(Map<String, double>? paidBy, List<String>? splitBy,
      CurrencyWithValue? totalExpense)? callback;

  ExpenditureEditTile(
      {super.key,
      required ExpenseModelFacade expenseUpdator,
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
  late Map<String, dynamic> _currentCurrencyInfo;
  final Map<String, Color> _contributorsVsColors = {};
  static const double _heightPerItem = 40;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _initializeContributors(BuildContext context) {
    var contributors = RepositoryProvider.of<TripRepositoryModelFacade>(context)
        .activeTrip!
        .tripMetadata
        .contributors;
    var allContributors = List.from(contributors);
    allContributors.sort();
    for (int index = 0; index < allContributors.length; index++) {
      var contributor = allContributors.elementAt(index);
      _contributorsVsColors[contributor] = contributorColors[index];
    }
    _currentCurrencyInfo = currencies.firstWhere(
        (element) => element['code'] == widget.totalExpense.currency);
  }

  @override
  Widget build(BuildContext context) {
    _initializeContributors(context);
    if (widget.isEditable) {
      return Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 2.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    PlatformTextElements.createSubHeader(
                        context: context,
                        shouldBold: widget.isEditable,
                        text: widget.totalExpense.amount.toStringAsFixed(2)),
                    Flexible(
                      child: PlatformCurrencyDropDown(
                          currencyInfo: _currentCurrencyInfo,
                          allCurrencies: currencies,
                          callBack: (currencyInfo) {
                            if (currencyInfo['name'] !=
                                _currentCurrencyInfo['name']) {
                              setState(() {
                                widget.totalExpense = CurrencyWithValue(
                                    currency: currencyInfo['code'],
                                    amount: widget.totalExpense.amount);
                                _currentCurrencyInfo = currencyInfo;
                                widget.callback!(
                                    widget.paidBy, null, widget.totalExpense);
                              });
                            }
                          }),
                    ),
                  ],
                ),
              ),
              _createTabBar(),
              SizedBox(
                height: (_contributorsVsColors.length + 1) * _heightPerItem,
                child: Container(
                  color: Colors.black12,
                  child: Center(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPaidByTab(), _buildSplitByPage()],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: PlatformTextElements.createSubHeader(
                context: context,
                shouldBold: widget.isEditable,
                text: widget.totalExpense.toString()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.splitBy} : ',
                  style: TextStyle(color: Colors.white),
                ),
                _buildSplitByIcons(),
              ],
            ),
          )
        ],
      );
    }
  }

  Widget _buildSplitByIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _contributorsVsColors.values
          .map((e) => Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: e,
                  shape: BoxShape.circle,
                ),
              ))
          .toList(),
    );
  }

  TabBar _createTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: AppLocalizations.of(context)!.paidBy),
        Tab(text: AppLocalizations.of(context)!.split),
      ],
    );
  }

  Widget _buildPaidByTab() {
    return _PaidByTab(
      heightPerItem: _heightPerItem,
      contributorsVsColors: _contributorsVsColors,
      paidBy: widget.paidBy,
      callback: (paidBy) {
        widget.paidBy = Map.from(paidBy);
        var totalExpenseAmount = widget.paidBy.values
            .fold(0.0, (previousValue, element) => previousValue + element);
        if (totalExpenseAmount != widget.totalExpense.amount) {
          setState(() {
            widget.totalExpense = CurrencyWithValue(
                currency: widget.totalExpense.currency,
                amount: totalExpenseAmount);
            if (widget.callback != null) {
              widget.callback!(widget.paidBy, null, widget.totalExpense);
            }
          });
        }
      },
      defaultCurrencySymbol: _currentCurrencyInfo['symbol'],
    );
  }

  Widget _buildSplitByPage() {
    return _SplitByTab(
        callback: (splitBy) {
          widget.splitBy = List.from(splitBy);
        },
        splitBy: widget.splitBy,
        contributorsVsColors: _contributorsVsColors);
  }
}

class _PaidByTab extends StatelessWidget {
  final Map<String, double> paidBy;
  final void Function(Map<String, double> paidBy) callback;
  final Map<String, Color> contributorsVsColors;
  final double heightPerItem;
  final String defaultCurrencySymbol;

  _PaidByTab(
      {super.key,
      required this.heightPerItem,
      required this.callback,
      required this.contributorsVsColors,
      required this.defaultCurrencySymbol,
      required this.paidBy});

  @override
  Widget build(BuildContext context) {
    var currentUserName =
        RepositoryProvider.of<PlatformDataRepositoryFacade>(context)
            .appData
            .activeUser!
            .userName;
    var allContributions = _createContributions(context, currentUserName);
    var widgets = allContributions
        .map((contributorVsColor) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: SizedBox(
                height: heightPerItem,
                child: _buildPaidByContributor(
                    contributorVsColor, context, currentUserName),
              ),
            ))
        .toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,
    );
  }

  List<MapEntry<String, Color>> _createContributions(
      BuildContext context, String currentUserName) {
    var allContributions = contributorsVsColors.entries.toList();
    var personalContribution = allContributions
        .firstWhere((element) => element.key == currentUserName);
    allContributions.removeWhere((element) => element.key == currentUserName);
    allContributions.insert(0, personalContribution);
    return allContributions;
  }

  Widget _buildPaidByContributor(MapEntry<String, Color> contributorVsColor,
      BuildContext context, String currentUserName) {
    double contribution;
    if (paidBy.containsKey(contributorVsColor.key)) {
      contribution = paidBy[contributorVsColor.key]!;
    } else {
      contribution = 0;
    }
    return _ExpenseEditField(
        onChanged: (amountValue) {
          if (amountValue.isEmpty) {
            paidBy[contributorVsColor.key] = 0;
            callback(paidBy);
          } else {
            paidBy[contributorVsColor.key] = double.parse(amountValue);
            callback(paidBy);
          }
        },
        prefixText: contributorVsColor.key == currentUserName
            ? AppLocalizations.of(context)!.you
            : contributorVsColor.key,
        initialExpense: contribution.toStringAsFixed(2),
        contributorColor: contributorVsColor.value,
        currencySymbol: defaultCurrencySymbol);
  }
}

class _ExpenseEditField extends StatefulWidget {
  final Function(String) onChanged;
  final String prefixText;
  final Color contributorColor;
  final String currencySymbol;
  final String initialExpense;

  _ExpenseEditField(
      {super.key,
      required this.onChanged,
      required this.prefixText,
      required this.initialExpense,
      required this.contributorColor,
      required this.currencySymbol});

  @override
  State<_ExpenseEditField> createState() => _ExpenseEditFieldState();
}

class _ExpenseEditFieldState extends State<_ExpenseEditField> {
  late TextEditingController _textEditingController;
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialExpense;
    _textEditingController = TextEditingController(text: _currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(color: Colors.white),
      onChanged: (newValue) {
        if (newValue != _currentValue) {
          var differenceIndex = findDifferenceIndex(newValue, _currentValue);
          _textEditingController.selection =
              TextSelection.fromPosition(TextPosition(offset: differenceIndex));
          _currentValue = newValue;
          widget.onChanged(newValue);
        }
      },
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      controller: _textEditingController,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}'))
      ],
      decoration: InputDecoration(
        fillColor: Colors.white24,
        border: OutlineInputBorder(),
        prefixText: widget.prefixText,
        icon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.contributorColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        suffix: CircleAvatar(
          radius: 17,
          child: Text(
            widget.currencySymbol,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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

class _SplitByTab extends StatefulWidget {
  final void Function(List<String>) callback;
  final Map<String, Color> contributorsVsColors;
  List<String> splitBy;

  _SplitByTab(
      {required this.callback,
      required this.splitBy,
      required this.contributorsVsColors});

  @override
  State<_SplitByTab> createState() => _SplitByTabState();
}

class _SplitByTabState extends State<_SplitByTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.contributorsVsColors.entries
          .map(
            (contributorVsColor) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: SizedBox(
                height: 45,
                child: Material(
                  color: widget.splitBy.contains(contributorVsColor.key)
                      ? Colors.white24
                      : null,
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        if (!widget.splitBy.contains(contributorVsColor.key)) {
                          widget.splitBy.add(contributorVsColor.key);
                        }
                      });
                    },
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        contributorVsColor.key,
                        style: TextStyle(
                            color: widget
                                .contributorsVsColors[contributorVsColor]),
                      ),
                    ),
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            widget.contributorsVsColors[contributorVsColor.key],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
