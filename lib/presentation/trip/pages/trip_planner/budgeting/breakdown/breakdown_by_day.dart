import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

extension ColorExtension on Color {
  /// Convert the color to a darken color based on the [percent]
  Color darken([int percent = 40]) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }
}

class BreakdownByDayChart extends StatefulWidget {
  BreakdownByDayChart({super.key});

  @override
  State<BreakdownByDayChart> createState() => _BreakdownByDayChartState();
}

class _BreakdownByDayChartState extends State<BreakdownByDayChart> {
  @override
  Widget build(BuildContext context) {
    var activeTrip = context.activeTrip;
    var budgetingModule = activeTrip.budgetingModuleFacade;
    var tripMetadata = activeTrip.tripMetadata;
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
          for (var dailyExpense in expensesPerDay.entries) {
            var percentageOfTotalExpense =
                totalExpense == 0 ? 0.0 : dailyExpense.value / totalExpense;
            String date = DateFormat('EEE, MMM d').format(dailyExpense.key);
            date = date.substring(date.indexOf(',') + 1);
            if (percentageOfTotalExpense == 0.0) {
              continue;
            }
            Widget dailyExpenseIndicator = Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${dailyExpense.value.toStringAsFixed(2)} ${tripMetadata.budget.currency.toUpperCase()}',
                            style: TextStyle(
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
              constraints: BoxConstraints(minHeight: 300, maxHeight: 500),
              child: ListView(
                children: dailyExpenseIndicators,
              ),
            ),
          );
        }

        return CircularProgressIndicator();
      },
    );
  }

  BarTouchData get barTouchData => BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 8,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.round().toString(),
              const TextStyle(
                color: Color(0xFF50E4FF),
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );

  FlTitlesData _createTilesData(Map<DateTime?, double> totalExpensesPerDay) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: getLeftTitles,
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 55,
          getTitlesWidget: (value, meta) =>
              getRightTitles(value, meta, totalExpensesPerDay),
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  FlBorderData get borderData => FlBorderData(
        show: false,
      );

  LinearGradient get _barsGradient => LinearGradient(
        colors: [
          Colors.green.darken(40),
          Colors.green,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  Widget _getLeftTitles(DateTime dateTime, TitleMeta meta) {
    String text = DateFormat('EEE, MMM d').format(dateTime);
    text = text.substring(text.indexOf(',') + 1);
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: RotatedBox(
        quarterTurns: 3,
        child: SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getLeftTitles(double value, TitleMeta meta) {
    var tripMetadata = context.activeTrip.tripMetadata;

    var numberOfDaysOfTrip = tripMetadata.startDate!
        .calculateDaysInBetween(tripMetadata.endDate!, includeExtraDay: true);
    var index = value.toInt() % numberOfDaysOfTrip;
    var currentDay = tripMetadata.startDate!.add(Duration(days: index));
    String text = DateFormat('EEE, MMM d').format(currentDay);
    text = text.substring(text.indexOf(',') + 1);
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: RotatedBox(
        quarterTurns: 3,
        child: SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getRightTitles(double value, TitleMeta meta,
      Map<DateTime?, double> totalExpensesPerDay) {
    var tripMetadata = context.activeTrip.tripMetadata;
    var numberOfDaysOfTrip =
        tripMetadata.startDate!.calculateDaysInBetween(tripMetadata.endDate!);

    var index = value.toInt() % numberOfDaysOfTrip;
    var expenseAmount = totalExpensesPerDay.entries.elementAt(index).value;
    String text =
        expenseAmount == 0 ? '     ' : expenseAmount.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: RotatedBox(
        quarterTurns: 3,
        child: SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4,
          child: Text(
            text,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  Iterable<BarChartGroupData> _createBarChartGroups(
      Map<DateTime?, double> expensesPerDay) sync* {
    int xValue = 0;
    for (var expenseInDay in expensesPerDay.entries) {
      yield BarChartGroupData(
          x: xValue,
          barRods: [
            BarChartRodData(toY: expenseInDay.value, gradient: _barsGradient)
          ],
          groupVertically: true);
      xValue++;
    }
  }
}
