import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class BreakdownByCategoryChart extends StatefulWidget {
  const BreakdownByCategoryChart({super.key});

  @override
  State<BreakdownByCategoryChart> createState() =>
      _BreakdownByCategoryChartState();
}

class _BreakdownByCategoryChartState extends State<BreakdownByCategoryChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    var budgetingModule = context.activeTrip.budgetingModuleFacade;
    return FutureBuilder<Map<ExpenseCategory, double>>(
        future: budgetingModule.retrieveTotalExpensePerCategory(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<ExpenseCategory, double>> snapshot) {
          var isLoadingData =
              snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.active;
          var isSnapshotDataValid = snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty;
          return Container(
            constraints: const BoxConstraints(minHeight: 300, maxHeight: 600),
            child: isLoadingData
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : (isSnapshotDataValid
                    ? PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          sectionsSpace: 0,
                          centerSpaceRadius: 35,
                          sections:
                              _createExpenseCategorySections(snapshot.data!),
                        ),
                      )
                    : const Center(
                        child: Text('No expenses created yet.'),
                      )),
          );
        });
  }

  static const _expenseChartSectionColors = [
    Colors.black,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.white,
    Colors.brown,
    Colors.pink,
    Colors.cyanAccent,
    Colors.deepOrange
  ];

  List<PieChartSectionData> _createExpenseCategorySections(
      Map<ExpenseCategory, double> totalExpensesPerExpenseCategory) {
    return List.generate(totalExpensesPerExpenseCategory.entries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      var totalExpenseAndCategory =
          totalExpensesPerExpenseCategory.entries.elementAt(i);
      return PieChartSectionData(
        color: _expenseChartSectionColors
            .elementAt(i % _expenseChartSectionColors.length),
        value: totalExpenseAndCategory.value,
        title: totalExpenseAndCategory.value.toStringAsFixed(2),
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: shadows,
        ),
        badgeWidget: _Badge(
          iconsForCategories[totalExpenseAndCategory.key]!,
          size: widgetSize,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    required this.size,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}
