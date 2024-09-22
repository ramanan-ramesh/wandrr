import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';

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
    var activeTrip = context.getActiveTrip();
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
          var expensesPerDay = snapshot.data ?? <DateTime, double>{};
          if (expensesPerDay.isEmpty) {
            return PlatformTextElements.createHeader(
                context: context,
                text: context.withLocale().noExpensesAssociatedWithDate);
          }
          return Container(
            constraints: BoxConstraints(minHeight: 300, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: BarChart(
                  BarChartData(
                      barTouchData: barTouchData,
                      titlesData: _createTilesData(expensesPerDay),
                      borderData: borderData,
                      barGroups: _createBarChartGroups(expensesPerDay).toList(),
                      gridData: const FlGridData(show: false),
                      alignment: BarChartAlignment.spaceAround,
                      maxY: expensesPerDay.entries
                          .map((e) => e.value)
                          .reduce(max)),
                  swapAnimationDuration: Duration(milliseconds: 150),
                  // Optional
                  swapAnimationCurve: Curves.linear, // Optional
                ),
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

  Widget getLeftTitles(double value, TitleMeta meta) {
    var tripMetadata = context.getActiveTrip().tripMetadata;

    var numberOfDaysOfTrip =
        tripMetadata.startDate!.calculateDaysInBetween(tripMetadata.endDate!);
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
    var tripMetadata = context.getActiveTrip().tripMetadata;
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
