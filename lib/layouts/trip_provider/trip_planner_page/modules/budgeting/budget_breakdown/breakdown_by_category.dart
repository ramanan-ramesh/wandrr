import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/contracts/budgeting_module.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/constants.dart';

class BreakdownByCategoryChart extends StatefulWidget {
  final BudgetingModuleFacade budgetingModule;
  const BreakdownByCategoryChart({super.key, required this.budgetingModule});

  @override
  State<BreakdownByCategoryChart> createState() =>
      _BreakdownByCategoryChartState();
}

class _BreakdownByCategoryChartState extends State<BreakdownByCategoryChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<ExpenseCategory, double>>(
        future: widget.budgetingModule.retrieveTotalExpensePerCategory(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<ExpenseCategory, double>> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              constraints: BoxConstraints(minHeight: 300, maxHeight: 600),
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
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
                  centerSpaceRadius: 0,
                  sections: _createExpenseCategorySections(snapshot.data!),
                ),
              ),
            );
          }
          return SizedBox.shrink();
        });
  }

  var _expenseChartSectionColors = [
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
            color: Colors.black.withOpacity(.5),
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
