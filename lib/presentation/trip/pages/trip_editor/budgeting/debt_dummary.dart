import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/contributor_badge.dart';

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
    final currentContributors = activeTrip.tripMetadata.contributors;

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
                          currentContributors: currentContributors,
                          appLocalizations: appLocalizations,
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
  final List<String> currentContributors;
  final AppLocalizations appLocalizations;

  const _DebtRow({
    required this.owedBy,
    required this.owedTo,
    required this.amountText,
    required this.currentUserName,
    required this.currentContributors,
    required this.appLocalizations,
  });

  static const double _kHorizontalSpacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ContributorBadge(
            contributorName: owedBy,
            currentUserName: currentUserName,
            currentContributors: currentContributors,
            localizedYouText: appLocalizations.you,
          ),
          const SizedBox(width: _kHorizontalSpacing / 3),
          FittedBox(child: Text(context.localizations.needsToPay)),
          const SizedBox(width: _kHorizontalSpacing / 3),
          ContributorBadge(
            contributorName: owedTo,
            currentUserName: currentUserName,
            currentContributors: currentContributors,
            localizedYouText: appLocalizations.you,
          ),
          const SizedBox(width: _kHorizontalSpacing / 3),
          FittedBox(child: Text(amountText)),
        ],
      ),
    );
  }
}
