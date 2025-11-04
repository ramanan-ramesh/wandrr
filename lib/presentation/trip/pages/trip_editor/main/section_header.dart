import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

const double _kHeaderCornerRadius = 14.0;
const double _kHeaderIconBorderRadius = 12.0;
const double _kHeaderIconPadding = 10.0;
const double _kHeaderChevronSize = 32.0;
const double _kHeaderChevronPadding = 6.0;
const double _kHeaderTitleFontSizeExpanded = 20.0;
const double _kHeaderTitleFontSizeCollapsed = 18.0;
const double _kHeaderTitleLetterSpacingExpanded = 0.5;
const double _kHeaderTitleLetterSpacingCollapsed = 0.2;
const double _kHeaderBoxShadowBlur = 8.0;
const double _kHeaderBoxShadowOffsetY = 2.0;
const double _kHeaderHorizontalPadding = 10.0;
const double _kHeaderVerticalPadding = 10.0;
const Duration _kChevronAnimationDuration = Duration(milliseconds: 300);
const double _kHeaderIconSize = 24.0;

class SectionHeader extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isExpanded;
  final AnimationController rotationController;
  final VoidCallback onTap;

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
        borderRadius: BorderRadius.circular(_kHeaderCornerRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _kHeaderHorizontalPadding,
            vertical: _kHeaderVerticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: colors.backgroundGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_kHeaderCornerRadius),
              topRight: Radius.circular(_kHeaderCornerRadius),
              bottomLeft: isExpanded
                  ? Radius.zero
                  : Radius.circular(_kHeaderCornerRadius),
              bottomRight: isExpanded
                  ? Radius.zero
                  : Radius.circular(_kHeaderCornerRadius),
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
      padding: const EdgeInsets.all(_kHeaderIconPadding),
      decoration: BoxDecoration(
        gradient: colors.iconGradient,
        borderRadius: BorderRadius.circular(_kHeaderIconBorderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.iconShadowColor,
            blurRadius: _kHeaderBoxShadowBlur,
            offset: const Offset(0, _kHeaderBoxShadowOffsetY),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: _kHeaderIconSize,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, _SectionHeaderColors colors) {
    return Text(
      title,
      style: theme.textTheme.titleLarge!.copyWith(
        fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
        fontSize: isExpanded
            ? _kHeaderTitleFontSizeExpanded
            : _kHeaderTitleFontSizeCollapsed,
        color: colors.textColor,
        letterSpacing: isExpanded
            ? _kHeaderTitleLetterSpacingExpanded
            : _kHeaderTitleLetterSpacingCollapsed,
      ),
    );
  }

  Widget _buildChevron(_SectionHeaderColors colors) {
    return RotationTransition(
      turns: rotationController,
      child: AnimatedContainer(
        duration: _kChevronAnimationDuration,
        padding: const EdgeInsets.all(_kHeaderChevronPadding),
        decoration: BoxDecoration(
          color: colors.chevronBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: _kHeaderChevronSize,
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
          ? (isDark ? Colors.white : theme.colorScheme.onPrimary)
          : (isDark ? Colors.white : theme.colorScheme.onSurface),
      chevronBgColor: isExpanded
          ? (isDark
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.grey.shade400)
          : (isDark
              ? theme.colorScheme.surface.withAlpha(220)
              : theme.colorScheme.outline.withAlpha(180)),
    );
  }
}
