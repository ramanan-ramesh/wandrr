import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Data model for a single bubble tab
class BubbleTabData {
  final IconData icon;
  final String semanticLabel;
  final String? label;

  const BubbleTabData({
    required this.icon,
    required this.semanticLabel,
    this.label,
  });
}

/// A tab bar with circular/pill-shaped bubble indicators that highlight the
/// selected tab. Icons remain visible and tinted appropriately.
class BubbleTabBar extends StatelessWidget {
  final TabController controller;
  final List<BubbleTabData> tabs;
  final double height;
  final bool showLabels;

  const BubbleTabBar({
    required this.controller,
    required this.tabs,
    this.height = 44,
    this.showLabels = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    final selectedColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final unselectedColor =
        isLight ? AppColors.neutral500 : AppColors.neutral400;
    final bubbleColor = selectedColor.withValues(alpha: isLight ? 0.12 : 0.18);

    return Material(
      elevation: 2,
      shadowColor: isLight
          ? Colors.black.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.3),
      color: isLight ? Colors.white : AppColors.darkSurface,
      child: SizedBox(
        height: height,
        child: AnimatedBuilder(
          // Listen to animation (not controller) for immediate per-frame updates
          // during swipe gestures and animateTo() calls.
          animation: controller.animation!,
          builder: (context, _) {
            final animVal = controller.animation!.value;
            return Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = (animVal - index).abs() < 0.5;
                final tab = tabs[index];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.animateTo(index),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: showLabels ? 12 : 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? bubbleColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 20,
                              color:
                                  isSelected ? selectedColor : unselectedColor,
                              semanticLabel: tab.semanticLabel,
                            ),
                            if (showLabels && tab.label != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                tab.label!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? selectedColor
                                      : unselectedColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
