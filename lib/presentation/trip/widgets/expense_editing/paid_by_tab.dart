import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_amount_edit_field.dart';

class PaidByTab extends StatelessWidget {
  final Map<String, double> paidBy;
  final void Function(Map<String, double> paidBy) callback;
  final String defaultCurrencySymbol;

  const PaidByTab(
      {required this.callback,
      required this.defaultCurrencySymbol,
      required this.paidBy,
      super.key});

  @override
  Widget build(BuildContext context) {
    var currentUserName = context.activeUser!.userName;
    var allContributions = _createContributions(context, currentUserName);
    var currentContributors = context.activeTrip.tripMetadata.contributors;

    return ListView.builder(
      itemCount: allContributions.length,
      itemBuilder: (context, index) {
        var contributor = allContributions[index];
        final isNoLongerTripmate = !currentContributors.contains(contributor);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildPaidByContributor(
              contributor, context, currentUserName, isNoLongerTripmate),
        );
      },
    );
  }

  List<String> _createContributions(
      BuildContext context, String currentUserName) {
    var contributors = context.activeTrip.tripMetadata.contributors.toList();

    // Include people from paidBy who may no longer be contributors
    final allPeople = <String>{...contributors, ...paidBy.keys};
    var allContributions = allPeople.toList();

    // Move current user to the top
    allContributions.remove(currentUserName);
    allContributions.insert(0, currentUserName);

    return allContributions;
  }

  Widget _buildPaidByContributor(String contributor, BuildContext context,
      String currentUserName, bool isNoLongerTripmate) {
    double contribution;
    if (paidBy.containsKey(contributor)) {
      contribution = paidBy[contributor]!;
    } else {
      contribution = 0;
    }

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final displayName = contributor == currentUserName
        ? context.localizations.you
        : contributor.split('@').first;

    return ListTile(
      isThreeLine: true,
      title: _ExpenseEditField(
        onChanged: (amountValue) {
          if (amountValue.isEmpty) {
            paidBy[contributor] = 0;
            callback(paidBy);
          } else {
            paidBy[contributor] = double.parse(amountValue);
            callback(paidBy);
          }
        },
        initialExpense: contribution.toStringAsFixed(2),
        currencySymbol: defaultCurrencySymbol,
      ),
      subtitle: Row(
        children: [
          if (isNoLongerTripmate) ...[
            Tooltip(
              message: 'No longer a tripmate',
              child: Icon(
                Icons.person_off,
                size: 14,
                color:
                    isLightTheme ? AppColors.warning : AppColors.warningLight,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              displayName,
              softWrap: true,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: contributor == currentUserName
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isNoLongerTripmate
                    ? (isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight)
                    : null,
                fontStyle:
                    isNoLongerTripmate ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEditField extends StatefulWidget {
  final Function(String) onChanged;
  final String currencySymbol;
  final String initialExpense;

  const _ExpenseEditField(
      {required this.onChanged,
      required this.initialExpense,
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
          ),
        ),
      ),
    );
  }
}
