import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isExpanded;
  final AnimationController rotationController;
  final VoidCallback onTap;
  static const double _cornerRadius = 14;

  const SectionHeader({
    required this.index,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.rotationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _SectionHeaderColors.fromTheme(theme, isExpanded);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: colors.backgroundGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_cornerRadius),
              topRight: Radius.circular(_cornerRadius),
              bottomLeft:
                  isExpanded ? Radius.zero : Radius.circular(_cornerRadius),
              bottomRight:
                  isExpanded ? Radius.zero : Radius.circular(_cornerRadius),
            ),
          ),
          child: Row(
            children: [
              _buildIcon(colors),
              const SizedBox(width: 16),
              Expanded(child: _buildTitle(theme, colors)),
              _buildChevron(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(_SectionHeaderColors colors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: colors.iconGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.iconShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, _SectionHeaderColors colors) {
    return Text(
      title,
      style: theme.textTheme.titleLarge!.copyWith(
        fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
        fontSize: isExpanded ? 20 : 18,
        color: colors.textColor,
        letterSpacing: isExpanded ? 0.5 : 0.2,
      ),
    );
  }

  Widget _buildChevron(_SectionHeaderColors colors) {
    return RotationTransition(
      turns: rotationController,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.chevronBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 32.0,
          color: colors.chevronColor,
        ),
      ),
    );
  }
}

class _SectionHeaderColors {
  final LinearGradient backgroundGradient;
  final LinearGradient iconGradient;
  final Color iconShadowColor;
  final Color textColor;
  final Color chevronColor;
  final Color chevronBgColor;

  _SectionHeaderColors._({
    required this.backgroundGradient,
    required this.iconGradient,
    required this.iconShadowColor,
    required this.textColor,
    required this.chevronColor,
    required this.chevronBgColor,
  });

  factory _SectionHeaderColors.fromTheme(ThemeData theme, bool isExpanded) {
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isExpanded
        ? AppColors.brandPrimary
        : theme.colorScheme.surfaceContainerHighest;
    final iconBgColor = isExpanded
        ? AppColors.brandPrimary
        : theme.colorScheme.outline.withAlpha(128);

    return _SectionHeaderColors._(
      backgroundGradient: LinearGradient(
        colors: [
          headerColor.withAlpha(isDark ? 180 : 102),
          headerColor.withAlpha(isDark ? 220 : 153),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconGradient: LinearGradient(
        colors: [iconBgColor, iconBgColor.withAlpha(204)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconShadowColor: isExpanded
          ? AppColors.brandPrimary.withAlpha(102)
          : theme.colorScheme.shadow.withAlpha(25),
      textColor: isExpanded
          ? (isDark ? Colors.white : AppColors.brandPrimary)
          : theme.colorScheme.onSurface.withAlpha(isDark ? 230 : 204),
      chevronColor: isExpanded
          ? (isDark ? Colors.white : AppColors.brandPrimary)
          : (isDark ? Colors.white : theme.colorScheme.onSurface),
      chevronBgColor: isExpanded
          ? (isDark
              ? AppColors.brandPrimary.withAlpha(180)
              : AppColors.brandPrimary.withAlpha(120))
          : (isDark
              ? theme.colorScheme.surface.withAlpha(220)
              : theme.colorScheme.outline.withAlpha(180)),
    );
  }
}
