import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
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
  static const double _kProgressHeight = 4.0;

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
        final indicators =
            data.entries.where((e) => e.value > 0).map((dailyExpense) {
          final percentage =
              totalExpense == 0 ? 0.0 : dailyExpense.value / totalExpense;
          final dateLabel = dailyExpense.key.dayFormat;
          return Padding(
            padding: const EdgeInsets.all(_kOuterPadding),
            child: PlatformCard(
              child: Padding(
                padding: const EdgeInsets.all(_kCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: _kTitleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activeTrip.budgetingModule.formatCurrency(
                            Money(
                                currency: budgetCurrency,
                                amount: dailyExpense.value),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage,
                      minHeight: _kProgressHeight,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                  ],
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
