import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/contributor_badge.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';

class DebtSummaryTile extends StatelessWidget {
  const DebtSummaryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTrip = context.activeTrip;
    final currentUserName = context.activeUser!.userName;
    final budgetingService = context.budgetingService;
    final appLocalizations = context.localizations;
    final currentContributors = activeTrip.tripMetadata.contributors;
    final isLight = context.isLightTheme;

    return FutureBuilder<Iterable<DebtData>>(
      future: budgetingService.calculateDebt(),
      builder: (context, snapshot) {
        final isDone = snapshot.connectionState == ConnectionState.done;
        final hasData = snapshot.hasData && snapshot.data != null;
        if (!isDone) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerPlaceholder(
                    height: 72,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          );
        }

        final debtDataList =
            hasData ? snapshot.data!.toList() : const <DebtData>[];
        final noExpenses =
            budgetingService.totalExpenditure == 0 || debtDataList.isEmpty;

        if (noExpenses) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 56,
                    color: isLight
                        ? AppColors.brandPrimary.withValues(alpha: 0.5)
                        : AppColors.brandPrimaryLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appLocalizations.noExpensesToSplit,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isLight
                              ? AppColors.neutral600
                              : AppColors.neutral400,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add shared expenses and they will appear here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLight
                              ? AppColors.neutral500
                              : AppColors.neutral500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: TripEditorPageConstants.fabContentPaddingBig + 16,
          ),
          child: Column(
            children: debtDataList
                .map((e) => _DebtCard(
                      owedBy: e.owedBy,
                      owedTo: e.owedTo,
                      amountText: budgetingService.formatCurrency(e.money),
                      currentUserName: currentUserName,
                      currentContributors: currentContributors,
                      appLocalizations: appLocalizations,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

/// Individual debt card with immersive surface styling
class _DebtCard extends StatelessWidget {
  final String owedBy;
  final String owedTo;
  final String amountText;
  final String currentUserName;
  final List<String> currentContributors;
  final AppLocalizations appLocalizations;

  const _DebtCard({
    required this.owedBy,
    required this.owedTo,
    required this.amountText,
    required this.currentUserName,
    required this.currentContributors,
    required this.appLocalizations,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    final isCurrentUserOwes = owedBy == currentUserName;
    final accent = isCurrentUserOwes ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContributorBadge(
                          contributorName: owedBy,
                          currentUserName: currentUserName,
                          currentContributors: currentContributors,
                          localizedYouText: appLocalizations.you,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              appLocalizations.needsToPay,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isLight
                                        ? AppColors.neutral600
                                        : AppColors.neutral400,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ContributorBadge(
                          contributorName: owedTo,
                          currentUserName: currentUserName,
                          currentContributors: currentContributors,
                          localizedYouText: appLocalizations.you,
                        ),
                      ],
                    ),
                  ),
                  // Amount badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isLight ? 0.12 : 0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      amountText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
