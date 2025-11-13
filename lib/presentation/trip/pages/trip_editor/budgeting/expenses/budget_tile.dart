import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class BudgetTile extends StatelessWidget {
  static const Duration _kAnimationDuration = Duration(milliseconds: 500);

  const BudgetTile();

  @override
  Widget build(BuildContext context) {
    final activeTrip = context.activeTrip;
    final budgetingModule = activeTrip.budgetingModule;
    final budget = activeTrip.tripMetadata.budget;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listener: (context, state) {},
      buildWhen: _shouldBuild,
      builder: (context, state) {
        return StreamBuilder<double>(
          stream: budgetingModule.totalExpenditureStream,
          initialData: budgetingModule.totalExpenditure,
          builder: (context, snapshot) {
            final totalExpenditure = snapshot.data ?? 0.0;
            final budgetAmount = budget.amount;
            final percentageUsed = budgetAmount > 0
                ? (totalExpenditure / budgetAmount * 100).clamp(0, 100)
                : 0.0;

            final isOverBudget = totalExpenditure > budgetAmount;
            final color = isOverBudget
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  context.isBigLayout
                      ? _buildHorizontalBudgetDisplay(context, budgetingModule,
                          budget, color, totalExpenditure)
                      : _buildVerticalBudgetDisplay(context, budgetingModule,
                          budget, color, totalExpenditure, isOverBudget),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: isOverBudget
                        ? _buildAnimatedOverBudgetProgressBar(
                            context, budgetAmount, totalExpenditure)
                        : TweenAnimationBuilder<double>(
                            duration: _kAnimationDuration,
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              begin: 0,
                              end: percentageUsed / 100,
                            ),
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 4,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _shouldBuild(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
      var updatedState = currentState as UpdatedTripEntity;
      if (updatedState.dataState == DataState.update) {
        var collectionItemChangeset =
            updatedState.tripEntityModificationData.modifiedCollectionItem
                as CollectionItemChangeSet<TripMetadataFacade>;
        if (collectionItemChangeset.beforeUpdate.budget !=
            collectionItemChangeset.afterUpdate.budget) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildHorizontalBudgetDisplay(
    BuildContext context,
    dynamic budgetingModule,
    Money budget,
    Color color,
    double totalExpenditure,
  ) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Icon(
          totalExpenditure > budget.amount
              ? Icons.warning_rounded
              : Icons.account_balance_wallet_rounded,
          size: 16,
          color: color,
        ),
        Text(
          budgetingModule.formatCurrency(
            Money(currency: budget.currency, amount: totalExpenditure),
          ),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'out of',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          budgetingModule.formatCurrency(budget),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVerticalBudgetDisplay(
    BuildContext context,
    dynamic budgetingModule,
    Money budget,
    Color color,
    double totalExpenditure,
    bool isOverBudget,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOverBudget
                  ? Icons.warning_rounded
                  : Icons.account_balance_wallet_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                budgetingModule.formatCurrency(
                  Money(currency: budget.currency, amount: totalExpenditure),
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 22),
            Text(
              'out of',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                budgetingModule.formatCurrency(budget),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedOverBudgetProgressBar(
      BuildContext context, double budgetAmount, double totalExpenditure) {
    final budgetPercentage = budgetAmount / totalExpenditure;

    return TweenAnimationBuilder<double>(
      duration: _kAnimationDuration,
      curve: Curves.easeInOut,
      tween: Tween<double>(
        begin: 0,
        end: budgetPercentage,
      ),
      builder: (context, animatedBudgetPercentage, child) {
        final animatedExcessPercentage = 1.0 - animatedBudgetPercentage;

        return SizedBox(
          height: 4,
          child: Stack(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              FractionallySizedBox(
                widthFactor: animatedBudgetPercentage,
                alignment: Alignment.centerLeft,
                child: Container(
                  color: Colors.green,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: animatedExcessPercentage,
                  alignment: Alignment.centerRight,
                  child: Container(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
