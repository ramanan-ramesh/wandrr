// Custom Chrome-style tab indicator
import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class ChromeTabBar extends StatelessWidget {
  final TabController? tabController;
  final Map<IconData, String> iconsAndTitles;

  const ChromeTabBar(
      {super.key, this.tabController, required this.iconsAndTitles});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final selectedColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final unselectedColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;
    final tabBgColor =
        isLightTheme ? AppColors.neutral200 : AppColors.darkSurface;
    final contentBgColor =
        isLightTheme ? Colors.white : AppColors.darkSurfaceVariant;
    final sideBorderColor =
        isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
    return DecoratedBox(
        decoration: BoxDecoration(
          color: tabBgColor,
          border: Border(
            bottom: BorderSide(
              color: isLightTheme ? AppColors.neutral300 : AppColors.neutral700,
              width: 1,
            ),
          ),
        ),
        child: TabBar(
          controller: tabController,
          labelColor: selectedColor,
          unselectedLabelColor: unselectedColor,
          indicator: _ChromeTabIndicator(
            backgroundColor: contentBgColor,
            topBorderColor: selectedColor,
            sideBorderColor: sideBorderColor,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor:
              isLightTheme ? AppColors.neutral300 : AppColors.neutral700,
          dividerHeight: 1,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          labelPadding: EdgeInsets.zero,
          tabs: iconsAndTitles.entries.map((entry) {
            return Tab(
              icon: Icon(entry.key, size: 20),
              text: entry.value,
              height: 72,
            );
          }).toList(),
        ));
  }
}

class _ChromeTabIndicator extends Decoration {
  final Color backgroundColor;
  final Color topBorderColor;
  final Color sideBorderColor;

  const _ChromeTabIndicator({
    required this.backgroundColor,
    required this.topBorderColor,
    required this.sideBorderColor,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _TabPainter(
      backgroundColor: backgroundColor,
      topBorderColor: topBorderColor,
      sideBorderColor: sideBorderColor,
    );
  }
}

class _TabPainter extends BoxPainter {
  final Color backgroundColor;
  final Color topBorderColor;
  final Color sideBorderColor;

  _TabPainter({
    required this.backgroundColor,
    required this.topBorderColor,
    required this.sideBorderColor,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );

    // Draw background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Draw top border (thicker for better visibility)
    final topBorderPaint = Paint()
      ..color = topBorderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final topPath = Path()
      ..moveTo(rect.left + 12, rect.top)
      ..lineTo(rect.right - 12, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + 12),
        radius: const Radius.circular(12),
      );
    canvas.drawPath(topPath, topBorderPaint);

    // Draw side borders (slightly thicker)
    final sideBorderPaint = Paint()
      ..color = sideBorderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Left border
    final leftPath = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + 12)
      ..arcToPoint(
        Offset(rect.left + 12, rect.top),
        radius: const Radius.circular(12),
      );
    canvas.drawPath(leftPath, sideBorderPaint);

    // Right border
    final rightPath = Path()
      ..moveTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top + 12)
      ..arcToPoint(
        Offset(rect.right - 12, rect.top),
        radius: const Radius.circular(12),
        clockwise: false,
      );
    canvas.drawPath(rightPath, sideBorderPaint);
  }
}
