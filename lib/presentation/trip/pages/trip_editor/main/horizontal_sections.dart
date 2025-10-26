import 'package:flutter/material.dart';

import 'collapsible_section.dart';

class HorizontalSectionsList extends StatelessWidget {
  final List<int> sectionIndices;
  final List<CollapsibleSection> sections;
  final Function(int) onSectionTap;
  final Map<int, AnimationController> rotationControllers;

  const HorizontalSectionsList({
    required this.sectionIndices,
    required this.sections,
    required this.onSectionTap,
    required this.rotationControllers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sectionIndices.length,
        itemBuilder: (context, index) {
          final sectionIndex = sectionIndices[index];
          final section = sections[sectionIndex];
          return _CompactSectionItem(
            section: section,
            onTap: () => onSectionTap(sectionIndex),
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

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: colors.backgroundGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.borderColor,
                width: 1.5,
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
      ),
    );
  }

  Widget _buildIcon(_CompactSectionColors colors) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: colors.iconGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        section.icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, _CompactSectionColors colors) {
    return Text(
      section.title,
      style: theme.textTheme.bodySmall!.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textColor,
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
  final Color textColor;

  _CompactSectionColors._({
    required this.backgroundGradient,
    required this.borderColor,
    required this.iconGradient,
    required this.textColor,
  });

  factory _CompactSectionColors.fromTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.colorScheme.surfaceContainerHighest;
    final iconColor = theme.colorScheme.outline.withAlpha(128);

    return _CompactSectionColors._(
      backgroundGradient: LinearGradient(
        colors: [
          bgColor.withAlpha(isDark ? 180 : 102),
          bgColor.withAlpha(isDark ? 220 : 153),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: theme.colorScheme.outline.withAlpha(102),
      iconGradient: LinearGradient(
        colors: [iconColor, iconColor.withAlpha(204)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: theme.colorScheme.onSurface.withAlpha(isDark ? 230 : 204),
    );
  }
}
