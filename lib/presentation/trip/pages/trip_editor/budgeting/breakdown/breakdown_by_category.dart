import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import '../expenses/expenses_list_view.dart';

class BreakdownByCategoryChart extends StatefulWidget {
  const BreakdownByCategoryChart({super.key});

  @override
  State<BreakdownByCategoryChart> createState() =>
      _BreakdownByCategoryChartState();
}

class _BreakdownByCategoryChartState extends State<BreakdownByCategoryChart> {
  int touchedIndex = -1;

  // UI constants
  static const double _kMinHeight = 300;
  static const double _kMaxHeight = 600;
  static const double _kCenterSpaceRadius = 30.0;
  static const double _kTouchedRadius = 110.0;
  static const double _kUntouchedRadius = 100.0;
  static const double _kTouchedFontSize = 20.0;
  static const double _kUntouchedFontSize = 16.0;
  static const double _kBadgeTouchedSize = 55.0;
  static const double _kBadgeUntouchedSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final budgetingModule = context.activeTrip.budgetingModule;
    return FutureBuilder<Map<ExpenseCategory, double>>(
      future: budgetingModule.retrieveTotalExpensePerCategory(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active;
        final data = snapshot.data;
        final hasValidData = data != null && data.isNotEmpty;
        return Container(
          constraints: const BoxConstraints(
              minHeight: _kMinHeight, maxHeight: _kMaxHeight),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasValidData
                  ? PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse?.touchedSection == null) {
                                touchedIndex = -1;
                              } else {
                                touchedIndex = pieTouchResponse!
                                    .touchedSection!.touchedSectionIndex;
                              }
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: _kCenterSpaceRadius,
                        sections: _createExpenseCategorySections(data),
                      ),
                    )
                  : const Center(child: Text('No expenses created yet.')),
        );
      },
    );
  }

  static const _expenseChartSectionColors = AppColors.travelAccents;

  List<PieChartSectionData> _createExpenseCategorySections(
    Map<ExpenseCategory, double> totalExpensesPerExpenseCategory,
  ) {
    return List.generate(totalExpensesPerExpenseCategory.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? _kTouchedFontSize : _kUntouchedFontSize;
      final radius = isTouched ? _kTouchedRadius : _kUntouchedRadius;
      final widgetSize = isTouched ? _kBadgeTouchedSize : _kBadgeUntouchedSize;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final entry = totalExpensesPerExpenseCategory.entries.elementAt(i);
      return PieChartSectionData(
        color:
            _expenseChartSectionColors[i % _expenseChartSectionColors.length],
        value: entry.value,
        title: entry.value.toStringAsFixed(2),
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
          shadows: shadows,
        ),
        badgeWidget: _Badge(
          iconsForCategories[entry.key]!,
          size: widgetSize,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, {required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.isLightTheme
            ? AppColors.brandSecondary
            : AppColors.neutral200,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandSecondary,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.isLightTheme
                ? AppColors.brandSecondary.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(
          icon,
          color: context.isLightTheme ? Colors.white : AppColors.brandSecondary,
        ),
      ),
    );
  }
}
