import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/widgets/expense_amount_edit_field.dart';

class PaidByTab extends StatelessWidget {
  final Map<String, double> paidBy;
  final void Function(Map<String, double> paidBy) callback;
  final Map<String, Color> contributorsVsColors;
  final double heightPerItem;
  final String defaultCurrencySymbol;

  const PaidByTab(
      {super.key,
      required this.heightPerItem,
      required this.callback,
      required this.contributorsVsColors,
      required this.defaultCurrencySymbol,
      required this.paidBy});

  @override
  Widget build(BuildContext context) {
    var currentUserName = context.activeUser!.userName;
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
            ? context.localizations.you
            : null,
        initialExpense: contribution.toStringAsFixed(2),
        contributorColor: contributorVsColor.value,
        currencySymbol: defaultCurrencySymbol);
  }
}

class _ExpenseEditField extends StatefulWidget {
  final Function(String) onChanged;
  final String? prefixText;
  final Color contributorColor;
  final String currencySymbol;
  final String initialExpense;

  const _ExpenseEditField(
      {required this.onChanged,
      this.prefixText,
      required this.initialExpense,
      required this.contributorColor,
      required this.currencySymbol});

  @override
  State<_ExpenseEditField> createState() => _ExpenseEditFieldState();
}

class _ExpenseEditFieldState extends State<_ExpenseEditField> {
  @override
  Widget build(BuildContext context) {
    return PlatformExpenseAmountEditField(
      amount: widget.initialExpense,
      textColor: Colors.white,
      onExpenseAmountChanged: (newValue) {
        var newExpenseStringValue = newValue.toStringAsFixed(2);
        widget.onChanged(newExpenseStringValue);
      },
      inputDecoration: InputDecoration(
        fillColor: Colors.white24,
        border: const OutlineInputBorder(),
        labelText: widget.prefixText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
