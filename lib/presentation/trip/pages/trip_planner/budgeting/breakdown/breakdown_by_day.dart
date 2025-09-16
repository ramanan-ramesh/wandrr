import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
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
  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    var budgetingModule = activeTrip.budgetingModule;
    var tripMetadata = activeTrip.tripMetadata;
    var budgetCurrency = tripMetadata.budget.currency;
    return FutureBuilder<Map<DateTime, double>>(
      future: budgetingModule.retrieveTotalExpensePerDay(
          tripMetadata.startDate!, tripMetadata.endDate!),
      builder: (BuildContext context,
          AsyncSnapshot<Map<DateTime, double>> snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          var expensesPerDay = snapshot.data!;
          if (budgetingModule.totalExpenditure == 0) {
            return Center(
              child: PlatformTextElements.createSubHeader(
                  context: context,
                  textAlign: TextAlign.center,
                  text: context.localizations.noExpensesAssociatedWithDate),
            );
          }
          var dailyExpenseIndicators = <Widget>[];
          var totalExpense = expensesPerDay.values.reduce((a, b) => a + b);
          for (final dailyExpense in expensesPerDay.entries) {
            var percentageOfTotalExpense =
                totalExpense == 0 ? 0.0 : dailyExpense.value / totalExpense;
            var date = DateFormat('EEE, MMM d').format(dailyExpense.key);
            date = date.substring(date.indexOf(',') + 1);
            if (percentageOfTotalExpense == 0.0) {
              continue;
            }
            Widget dailyExpenseIndicator = Padding(
              padding: const EdgeInsets.all(20.0),
              child: PlatformCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activeTrip.budgetingModule.formatCurrency(Money(
                                currency: budgetCurrency,
                                amount: dailyExpense.value)),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(
                        value: percentageOfTotalExpense,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
            dailyExpenseIndicators.add(dailyExpenseIndicator);
          }
          return SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(minHeight: 300, maxHeight: 500),
              child: ListView(
                children: dailyExpenseIndicators,
              ),
            ),
          );
        }

        return const CircularProgressIndicator();
      },
    );
  }
}
