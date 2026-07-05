import 'package:flutter/material.dart';

class PrintStaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const PrintStaggeredColumn({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          _PrintStaggeredItem(index: i, child: children[i]),
      ],
    );
  }
}

class _PrintStaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _PrintStaggeredItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final rawStart = index * 0.05;
    final intervalStart = rawStart > 0.85 ? 0.85 : rawStart;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Interval(intervalStart, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class PrintCompactSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const PrintCompactSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: enabled
                          ? null
                          : cs.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: Switch.adaptive(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrintSectionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onSelected;

  const PrintSectionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      selected: selected,
      onSelected: enabled ? onSelected : null,
      showCheckmark: false,
      selectedColor: cs.primaryContainer,
      backgroundColor: cs.surfaceContainerHighest,
      side: BorderSide(
        color: !enabled
            ? cs.outlineVariant
            : selected
                ? cs.primary
                : cs.outline,
        width: selected ? 1.5 : 1.0,
      ),
      labelStyle: TextStyle(
        color: !enabled
            ? cs.onSurfaceVariant.withValues(alpha: 0.7)
            : selected
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
