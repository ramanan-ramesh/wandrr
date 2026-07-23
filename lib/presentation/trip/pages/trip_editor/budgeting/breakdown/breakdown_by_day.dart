// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';

class BreakdownByDayChart extends StatefulWidget {
  const BreakdownByDayChart({super.key});

  @override
  State<BreakdownByDayChart> createState() => _BreakdownByDayChartState();
}

class _BreakdownByDayChartState extends State<BreakdownByDayChart>
    with AutomaticKeepAliveClientMixin {
  late final Future<Map<DateTime, double>> _dataFuture;

  // UI constants
  static const double _kCardPadding = 8.0;
  static const double _kOuterPadding = 20.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final activeTrip = context.activeTrip;
    _dataFuture = context.budgetingService.groupExpensePerDay(
      activeTrip.tripMetadata.startDate!,
      activeTrip.tripMetadata.endDate!,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final activeTrip = context.activeTrip;
    final budgetingService = context.budgetingService;
    final tripMetadata = activeTrip.tripMetadata;
    final budgetCurrency = tripMetadata.budget.currency;

    return FutureBuilder<Map<DateTime, double>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final isDone = snapshot.connectionState == ConnectionState.done;
        final data = snapshot.data;

        // Shimmer skeleton while data loads — Column avoids a nested scroller
        if (!isDone) {
          return Column(
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _kOuterPadding, vertical: _kOuterPadding / 2),
                child: ShimmerPlaceholder(
                  height: 80,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }

        if (data == null ||
            data.isEmpty ||
            budgetingService.totalExpenditure == 0) {
          return Center(
            child: PlatformTextElements.createSubHeader(
              context: context,
              textAlign: TextAlign.center,
              text: context.localizations.noExpensesAssociatedWithDate,
            ),
          );
        }

        final totalExpense = data.values.fold<double>(0, (a, b) => a + b);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        final items =
            data.entries.where((e) => e.value > 0).map((dailyExpense) {
          final percentage =
              totalExpense == 0 ? 0.0 : dailyExpense.value / totalExpense;
          final dateLabel = dailyExpense.key.dayDateMonthFormat;

          final cardColor =
              Theme.of(context).colorScheme.surfaceContainerHighest;
          final textColor = Theme.of(context).colorScheme.onSurface;
          final accentColor = Theme.of(context).colorScheme.primary;
          final progressBgColor = isDarkMode
              ? Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kOuterPadding,
              vertical: _kOuterPadding / 2,
            ),
            child: Card(
              elevation: 4,
              shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [cardColor, cardColor.withValues(alpha: 0.95)]
                        : [
                            cardColor.withValues(alpha: 0.9),
                            cardColor.withValues(alpha: 0.95),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_kCardPadding * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                dateLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: textColor),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              budgetingService.formatCurrency(
                                Money(
                                    currency: budgetCurrency,
                                    amount: dailyExpense.value),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: accentColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: progressBgColor,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList();

        // Column instead of ListView — no independent scroller,
        // parent SingleChildScrollView handles all scrolling.
        return Column(children: items);
      },
    );
  }
}
