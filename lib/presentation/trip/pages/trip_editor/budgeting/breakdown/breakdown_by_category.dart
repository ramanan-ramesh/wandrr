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
  // Cached once in initState — never recreated on scroll/tab switches within
  // the same refresh cycle. Recreated intentionally when ValueKey changes.
  late final Future<Map<ExpenseCategory, double>> _dataFuture;

  // ValueNotifier so only the PieChart rebuilds on touch, not the FutureBuilder.
  final ValueNotifier<int> _touchedIndex = ValueNotifier<int>(-1);

  @override
  void initState() {
    super.initState();
    _dataFuture =
        context.activeTrip.budgetingModule.retrieveTotalExpensePerCategory();
  }

  @override
  void dispose() {
    _touchedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<ExpenseCategory, double>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active;
        final data = snapshot.data;
        final hasValidData = data != null && data.isNotEmpty;

        return Container(
          constraints: const BoxConstraints(minHeight: 300, maxHeight: 600),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasValidData
                  ? _InteractivePieChart(
                      data: data,
                      touchedIndex: _touchedIndex,
                    )
                  : const Center(child: Text('No expenses created yet.')),
        );
      },
    );
  }
}

/// Isolated widget that owns touch interaction. Rebuilds only itself via
/// ValueNotifier — the FutureBuilder above is never triggered again.
class _InteractivePieChart extends StatelessWidget {
  final Map<ExpenseCategory, double> data;
  final ValueNotifier<int> touchedIndex;

  // UI constants
  static const double _kCenterSpaceRadius = 30.0;
  static const double _kTouchedRadius = 110.0;
  static const double _kUntouchedRadius = 100.0;
  static const double _kTouchedFontSize = 20.0;
  static const double _kUntouchedFontSize = 16.0;
  static const double _kBadgeTouchedSize = 55.0;
  static const double _kBadgeUntouchedSize = 40.0;
  static const _expenseChartSectionColors = AppColors.travelAccents;

  const _InteractivePieChart({
    required this.data,
    required this.touchedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: touchedIndex,
      builder: (context, touched, _) {
        return PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, pieTouchResponse) {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse?.touchedSection == null) {
                  touchedIndex.value = -1;
                } else {
                  touchedIndex.value =
                      pieTouchResponse!.touchedSection!.touchedSectionIndex;
                }
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 0,
            centerSpaceRadius: _kCenterSpaceRadius,
            sections: _buildSections(context, touched),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context, int touched) {
    return List.generate(data.length, (i) {
      final isTouched = i == touched;
      final entry = data.entries.elementAt(i);
      return PieChartSectionData(
        color:
            _expenseChartSectionColors[i % _expenseChartSectionColors.length],
        value: entry.value,
        title: entry.value.toStringAsFixed(2),
        radius: isTouched ? _kTouchedRadius : _kUntouchedRadius,
        titleStyle: TextStyle(
          fontSize: isTouched ? _kTouchedFontSize : _kUntouchedFontSize,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget: _Badge(
          iconsForCategories[entry.key]!,
          size: isTouched ? _kBadgeTouchedSize : _kBadgeUntouchedSize,
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
