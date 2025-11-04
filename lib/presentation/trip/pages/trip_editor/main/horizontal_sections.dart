import 'package:flutter/material.dart';

import 'collapsible_section.dart';

const double _kCompactSectionBorderRadius = 12.0;
const double _kCompactSectionIconBorderRadius = 8.0;
const double _kCompactSectionWidth = 120.0;
const double _kCompactSectionIconSize = 20.0;
const double _kCompactSectionIconPadding = 6.0;
const double _kCompactSectionContainerPadding = 8.0;
const double _kCompactSectionBorderWidth = 1.5;
const int _kAlphaGradientStart = 120;
const int _kAlphaGradientEnd = 180;
const int _kAlphaBorder = 102;
const int _kAlphaIcon = 160;

class HorizontalSectionsList extends StatelessWidget {
  final List<CollapsibleSection> sections;
  final void Function(int) onSectionTap;

  const HorizontalSectionsList({
    super.key,
    required this.sections,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = sections[index];
          return _CompactSectionItem(
            section: section,
            onTap: () => onSectionTap(index),
          );
        },
      ),
    );
  }
}

class _CompactSectionItem extends StatelessWidget {
  final CollapsibleSection section;
  final VoidCallback onTap;

  const _CompactSectionItem({
    required this.section,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _CompactSectionColors.fromTheme(theme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kCompactSectionBorderRadius),
        child: Container(
          width: _kCompactSectionWidth,
          padding: const EdgeInsets.all(_kCompactSectionContainerPadding),
          decoration: BoxDecoration(
            gradient: colors.backgroundGradient,
            borderRadius: BorderRadius.circular(_kCompactSectionBorderRadius),
            border: Border.all(
              color: colors.borderColor,
              width: _kCompactSectionBorderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(colors),
              const SizedBox(height: 6),
              _buildTitle(theme, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(_CompactSectionColors colors) {
    return Container(
      padding: const EdgeInsets.all(_kCompactSectionIconPadding),
      decoration: BoxDecoration(
        gradient: colors.iconGradient,
        borderRadius: BorderRadius.circular(_kCompactSectionIconBorderRadius),
      ),
      child: Icon(
        section.icon,
        color: Colors.white,
        size: _kCompactSectionIconSize,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, _CompactSectionColors colors) {
    return Text(
      section.title,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CompactSectionColors {
  final LinearGradient backgroundGradient;
  final Color borderColor;
  final LinearGradient iconGradient;

  const _CompactSectionColors._({
    required this.backgroundGradient,
    required this.borderColor,
    required this.iconGradient,
  });

  factory _CompactSectionColors.fromTheme(ThemeData theme) {
    final bgColor = theme.colorScheme.surfaceContainerHighest;
    final iconColor = theme.iconTheme.color ?? theme.colorScheme.outline;
    return _CompactSectionColors._(
      backgroundGradient: LinearGradient(
        colors: [
          bgColor.withAlpha(_kAlphaGradientStart),
          bgColor.withAlpha(_kAlphaGradientEnd),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: theme.colorScheme.outline.withAlpha(_kAlphaBorder),
      iconGradient: LinearGradient(
        colors: [
          iconColor.withAlpha(_kAlphaIcon),
          iconColor.withAlpha(_kAlphaGradientEnd)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
