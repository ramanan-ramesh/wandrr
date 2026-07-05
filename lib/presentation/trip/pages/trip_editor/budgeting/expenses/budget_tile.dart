import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/services/budgeting_service.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

class BudgetTile extends StatefulWidget {
  static const Duration _kAnimationDuration = Duration(milliseconds: 500);

  const BudgetTile({super.key});

  @override
  State<BudgetTile> createState() => _BudgetTileState();
}

class _BudgetTileState extends State<BudgetTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  StreamSubscription<bool>? _loadSub;
  bool _entranceTriggered = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entranceController, curve: Curves.easeOutCubic));
  }

  void _attachLoadSubscription(BuildContext context) {
    if (_loadSub != null) {
      return;
    }
    final activeTrip = context.tripRepository.activeTrip;
    if (activeTrip == null) {
      return;
    }

    if (activeTrip.isFullyLoadedValue) {
      // Already loaded — skip entrance animation, show immediately.
      _entranceTriggered = true;
      _entranceController.value = 1.0;
    } else {
      _loadSub = activeTrip.isFullyLoaded.listen((loaded) {
        if (loaded && mounted && !_entranceTriggered) {
          _entranceTriggered = true;
          _entranceController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _loadSub?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _attachLoadSubscription(context);

    return TripEntityUpdateHandler<TripMetadataFacade>(
      widgetBuilder: _createTile,
      shouldRebuild: (beforeUpdate, afterUpdate) {
        return beforeUpdate.budget != afterUpdate.budget;
      },
    );
  }

  Widget _createTile(BuildContext context) {
    final activeTrip = context.activeTrip;
    final budgetingService = context.budgetingService;
    final budget = activeTrip.tripMetadata.budget;
    return StreamBuilder<double>(
      stream: budgetingService.totalExpenditureStream,
      initialData: budgetingService.totalExpenditure,
      builder: (context, snapshot) {
        final totalExpenditure = snapshot.data ?? 0.0;
        final budgetAmount = budget.amount;

        final isOverBudget = totalExpenditure > budgetAmount;
        final color = isOverBudget
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;

        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
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
                      ? _buildHorizontalBudgetDisplay(context, budgetingService,
                          budget, color, totalExpenditure)
                      : _buildVerticalBudgetDisplay(context, budgetingService,
                          budget, color, totalExpenditure, isOverBudget),
                  const SizedBox(height: 4),
                  _createTotalExpensePercentageDisplay(
                      context, budget.amount, totalExpenditure, color),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _createTotalExpensePercentageDisplay(BuildContext context,
      double budgetAmount, double totalExpenditure, Color color) {
    final percentageUsed = budgetAmount > 0
        ? (totalExpenditure / budgetAmount * 100).clamp(0, 100)
        : 0.0;

    final isOverBudget = totalExpenditure > budgetAmount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: isOverBudget
          ? _buildAnimatedOverBudgetProgressBar(
              context, budgetAmount, totalExpenditure)
          : TweenAnimationBuilder<double>(
              duration: BudgetTile._kAnimationDuration,
              curve: Curves.easeInOut,
              tween: Tween<double>(end: percentageUsed / 100),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                );
              },
            ),
    );
  }

  Widget _buildHorizontalBudgetDisplay(
    BuildContext context,
    BudgetingServiceFacade budgetingService,
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
        // Animated count-up for the expenditure amount
        TweenAnimationBuilder<double>(
          duration: BudgetTile._kAnimationDuration,
          curve: Curves.easeOut,
          tween: Tween<double>(end: totalExpenditure),
          builder: (context, animatedValue, _) {
            return Text(
              budgetingService.formatCurrency(
                Money(currency: budget.currency, amount: animatedValue),
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            );
          },
        ),
        Text(
          'out of',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          budgetingService.formatCurrency(budget),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVerticalBudgetDisplay(
    BuildContext context,
    dynamic budgetingService,
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
              // Animated count-up for the expenditure amount
              child: TweenAnimationBuilder<double>(
                duration: BudgetTile._kAnimationDuration,
                curve: Curves.easeOut,
                tween: Tween<double>(end: totalExpenditure),
                builder: (context, animatedValue, _) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      budgetingService.formatCurrency(
                        Money(currency: budget.currency, amount: animatedValue),
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'of ${budgetingService.formatCurrency(budget)}',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAnimatedOverBudgetProgressBar(
      BuildContext context, double budgetAmount, double totalExpenditure) {
    final budgetPercentage = budgetAmount / totalExpenditure;

    return TweenAnimationBuilder<double>(
      duration: BudgetTile._kAnimationDuration,
      curve: Curves.easeInOut,
      tween: Tween<double>(end: budgetPercentage),
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
