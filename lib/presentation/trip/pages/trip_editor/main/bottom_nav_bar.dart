import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

const double _kNavBarHeight = 70.0;
const double _kNavBarRadius = 50.0;
const double _kIconSizeSelected = 36.0;
const double _kIconSizeUnselected = 28.0;

extension _NavBarThemeExtension on BuildContext {
  Color get navBarSelectedColor => Theme.of(this).colorScheme.primary;

  Color get navBarUnselectedColor {
    final theme = Theme.of(this);
    final cs = theme.colorScheme;
    return isLightTheme
        ? cs.primaryContainer
        : cs.onSurfaceVariant.withValues(alpha: 0.35);
  }

  Color get navBarIconSelectedColor => Colors.white;

  Color get navBarIconUnselectedColor =>
      Theme.of(this).iconTheme.color ?? AppColors.brandSecondary;

  Color get navBarTextSelectedColor => Colors.white;

  Color get navBarTextUnselectedColor =>
      Theme.of(this).textTheme.bodySmall?.color ?? AppColors.brandSecondary;
}

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavBarItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavBarItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kNavBarHeight,
      color: Colors.transparent,
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_kNavBarRadius),
          topRight: Radius.circular(_kNavBarRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: _createNavBarItem(
                  context,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(_kNavBarRadius),
                    topRight: Radius.zero,
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  Icons.travel_explore_rounded,
                  'Itinerary'),
            ),
            Expanded(
              child: _createNavBarItem(
                  context,
                  1,
                  const BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: Radius.circular(_kNavBarRadius),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  Icons.wallet_travel_rounded,
                  'Budgeting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createNavBarItem(BuildContext context, int index,
      BorderRadius borderRadius, IconData icon, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selectedIndex == index
            ? context.navBarSelectedColor
            : context.navBarUnselectedColor,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavBarItemTapped(index),
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _NavItem(
              icon: icon,
              label: label,
              selected: selectedIndex == index,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize =
        selected ? _kIconSizeSelected : _kIconSizeUnselected;
    final Color iconColor = selected
        ? context.navBarIconSelectedColor
        : context.navBarIconUnselectedColor;
    final Color textColor = selected
        ? context.navBarTextSelectedColor
        : context.navBarTextUnselectedColor;
    final TextStyle baseStyle = selected
        ? Theme.of(context).textTheme.labelLarge!
        : Theme.of(context).textTheme.labelMedium!;
    final TextStyle textStyle = baseStyle.copyWith(
      color: textColor,
      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      fontSize: selected ? (baseStyle.fontSize! * 1.2) : baseStyle.fontSize,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: textStyle,
        ),
      ],
    );
  }
}
