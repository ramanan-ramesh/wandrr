import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/widgets/expense_amount_edit_field.dart';

class PaidByTab extends StatelessWidget {
  final Map<String, double> paidBy;
  final void Function(Map<String, double> paidBy) callback;
  final Map<String, Color> contributorsVsColors;
  final String defaultCurrencySymbol;

  const PaidByTab(
      {required this.callback,
      required this.contributorsVsColors,
      required this.defaultCurrencySymbol,
      required this.paidBy,
      super.key});

  @override
  Widget build(BuildContext context) {
    var currentUserName = context.activeUser!.userName;
    var allContributions = _createContributions(context, currentUserName);
    return ListView.builder(
      itemCount: allContributions.length,
      itemBuilder: (context, index) {
        var contributorVsColor = allContributions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildPaidByContributor(
              contributorVsColor, context, currentUserName),
        );
      },
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

    String displayName = contributorVsColor.key;

    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundColor: contributorVsColor.value,
        radius: context.isBigLayout ? 24 : 20,
      ),
      title: _ExpenseEditField(
        onChanged: (amountValue) {
          if (amountValue.isEmpty) {
            paidBy[contributorVsColor.key] = 0;
            callback(paidBy);
          } else {
            paidBy[contributorVsColor.key] = double.parse(amountValue);
            callback(paidBy);
          }
        },
        initialExpense: contribution.toStringAsFixed(2),
        contributorColor: contributorVsColor.value,
        currencySymbol: defaultCurrencySymbol,
      ),
      subtitle: Text(
        displayName == currentUserName
            ? context.localizations.you
            : displayName,
        softWrap: true,
        maxLines: 2,
        style: TextStyle(
          fontSize: 13,
          fontWeight: displayName == currentUserName
              ? FontWeight.w600
              : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ExpenseEditField extends StatefulWidget {
  final Function(String) onChanged;
  final Color contributorColor;
  final String currencySymbol;
  final String initialExpense;

  const _ExpenseEditField(
      {required this.onChanged,
      required this.initialExpense,
      required this.contributorColor,
      required this.currencySymbol});

  @override
  State<_ExpenseEditField> createState() => _ExpenseEditFieldState();
}

class _ExpenseEditFieldState extends State<_ExpenseEditField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialExpense);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ExpenseEditField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialExpense != oldWidget.initialExpense &&
        widget.initialExpense != _controller.text) {
      _controller.text = widget.initialExpense;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformExpenseAmountEditField(
      controller: _controller,
      focusNode: _focusNode,
      amount: widget.initialExpense,
      textColor: Theme.of(context).colorScheme.onSurface,
      onExpenseAmountChanged: (newValue) {
        var newExpenseStringValue = newValue.toStringAsFixed(2);
        widget.onChanged(newExpenseStringValue);
      },
      inputDecoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        suffix: Text(
          widget.currencySymbol,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: widget.contributorColor,
          ),
        ),
      ),
    );
  }
}
