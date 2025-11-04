import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class DebtSummaryTile extends StatelessWidget {
  const DebtSummaryTile({super.key});

  // UI constants
  static const double _kRowVerticalPadding = 5.0;

  @override
  Widget build(BuildContext context) {
    final activeTrip = context.activeTrip;
    final currentUserName = context.activeUser!.userName;
    final budgetingModule = activeTrip.budgetingModule;
    final appLocalizations = context.localizations;
    final contributors = [...activeTrip.tripMetadata.contributors]..sort();
    final contributorColors = <String, Color>{
      for (var i = 0; i < contributors.length; i++)
        contributors[i]: AppColors.travelAccents[i]
    };

    return FutureBuilder<Iterable<DebtData>>(
      future: budgetingModule.retrieveDebtDataList(),
      builder: (context, snapshot) {
        final isDone = snapshot.connectionState == ConnectionState.done;
        final hasData = snapshot.hasData && snapshot.data != null;
        if (!isDone) {
          return const Center(child: CircularProgressIndicator());
        }
        final debtDataList =
            hasData ? snapshot.data!.toList() : const <DebtData>[];
        final noExpenses =
            budgetingModule.totalExpenditure == 0 || debtDataList.isEmpty;

        final childWidget = noExpenses
            ? Center(child: Text(context.localizations.noExpensesToSplit))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: debtDataList
                    .map((e) => _DebtRow(
                          owedBy: e.owedBy,
                          owedTo: e.owedTo,
                          amountText: budgetingModule.formatCurrency(e.money),
                          currentUserName: currentUserName,
                          appLocalizations: appLocalizations,
                          owedByColor: contributorColors[e.owedBy]!,
                          owedToColor: contributorColors[e.owedTo]!,
                        ))
                    .toList(),
              );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: _kRowVerticalPadding),
          child: childWidget,
        );
      },
    );
  }
}

class _DebtRow extends StatelessWidget {
  final String owedBy;
  final String owedTo;
  final String amountText;
  final String currentUserName;
  final AppLocalizations appLocalizations;
  final Color owedByColor;
  final Color owedToColor;

  const _DebtRow({
    required this.owedBy,
    required this.owedTo,
    required this.amountText,
    required this.currentUserName,
    required this.appLocalizations,
    required this.owedByColor,
    required this.owedToColor,
  });

  static const double _kHorizontalSpacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ContributorBadge(
            contributorName: owedBy,
            currentUserName: currentUserName,
            color: owedByColor,
            appLocalizations: appLocalizations,
          ),
          const SizedBox(width: _kHorizontalSpacing / 3),
          FittedBox(child: Text(context.localizations.needsToPay)),
          const SizedBox(width: _kHorizontalSpacing / 3),
          _ContributorBadge(
            contributorName: owedTo,
            currentUserName: currentUserName,
            color: owedToColor,
            appLocalizations: appLocalizations,
          ),
          const SizedBox(width: _kHorizontalSpacing / 3),
          FittedBox(child: Text(amountText)),
        ],
      ),
    );
  }
}

class _ContributorBadge extends StatelessWidget {
  final String contributorName;
  final String currentUserName;
  final Color color;
  final AppLocalizations appLocalizations;

  const _ContributorBadge({
    required this.contributorName,
    required this.currentUserName,
    required this.color,
    required this.appLocalizations,
  });

  static const double _kBadgeSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final displayName = contributorName == currentUserName
        ? appLocalizations.you
        : contributorName.split('@').first;
    return TextButton.icon(
      onPressed: null,
      icon: Container(
        width: _kBadgeSize,
        height: _kBadgeSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      label: Text(displayName),
    );
  }
}
