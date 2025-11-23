import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class BreakdownByDayChart extends StatefulWidget {
  const BreakdownByDayChart({super.key});

  @override
  State<BreakdownByDayChart> createState() => _BreakdownByDayChartState();
}

class _BreakdownByDayChartState extends State<BreakdownByDayChart> {
  // UI constants
  static const double _kMinHeight = 300;
  static const double _kMaxHeight = 500;
  static const double _kCardPadding = 8.0;
  static const double _kOuterPadding = 20.0;
  static const double _kTitleFontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final activeTrip = context.activeTrip;
    final budgetingModule = activeTrip.budgetingModule;
    final tripMetadata = activeTrip.tripMetadata;
    final budgetCurrency = tripMetadata.budget.currency;

    return FutureBuilder<Map<DateTime, double>>(
      future: budgetingModule.retrieveTotalExpensePerDay(
        tripMetadata.startDate!,
        tripMetadata.endDate!,
      ),
      builder: (context, snapshot) {
        final isDone = snapshot.connectionState == ConnectionState.done;
        final data = snapshot.data;
        if (!isDone) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data == null ||
            data.isEmpty ||
            budgetingModule.totalExpenditure == 0) {
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

        final indicators =
            data.entries.where((e) => e.value > 0).map((dailyExpense) {
          final percentage =
              totalExpense == 0 ? 0.0 : dailyExpense.value / totalExpense;
          final dateLabel = dailyExpense.key.dayDateMonthFormat;

          // Use theme colors for better visual appeal
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
                        ? [
                            cardColor,
                            cardColor.withValues(alpha: 0.95),
                          ]
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
                              Icon(
                                Icons.calendar_today_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: _kTitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activeTrip.budgetingModule.formatCurrency(
                                Money(
                                    currency: budgetCurrency,
                                    amount: dailyExpense.value),
                              ),
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 8,
                                backgroundColor: progressBgColor,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList();

        return ConstrainedBox(
          constraints: const BoxConstraints(
              minHeight: _kMinHeight, maxHeight: _kMaxHeight),
          child: ListView(children: indicators),
        );
      },
    );
  }
}
