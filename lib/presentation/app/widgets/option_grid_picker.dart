import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// A single selectable option for [OptionGridPicker].
class OptionGridItem<T> {
  final T value;
  final IconData icon;
  final String label;

  const OptionGridItem({
    required this.value,
    required this.icon,
    required this.label,
  });
}

/// An expressive alternative to dropdowns.
///
/// Renders a compact trigger pill (selected icon + label + animated chevron).
/// On tap, opens a modal bottom sheet carrying a responsive icon-grid panel.
class OptionGridPicker<T> extends StatefulWidget {
  final List<OptionGridItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;

  /// Label shown in the trigger when nothing is selected.
  final String? hint;

  /// Title shown at the top of the sheet grid panel.
  final String? overlayTitle;

  const OptionGridPicker({
    required this.items,
    super.key,
    this.selectedValue,
    this.onChanged,
    this.hint,
    this.overlayTitle,
  });

  @override
  State<OptionGridPicker<T>> createState() => _OptionGridPickerState<T>();
}

class _OptionGridPickerState<T> extends State<OptionGridPicker<T>>
    with SingleTickerProviderStateMixin {
  late T? _selected;
  late final AnimationController _chevronCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedValue;
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OptionGridPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      setState(() => _selected = widget.selectedValue);
    }
  }

  OptionGridItem<T>? get _selectedItem => widget.items
      .cast<OptionGridItem<T>?>()
      .firstWhere((e) => e?.value == _selected, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accent =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final item = _selectedItem;

    return GestureDetector(
      onTap: widget.onChanged == null ? null : () => _openSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isLight ? 0.10 : 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (item != null) ...[
              // Icon badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (widget.hint != null) ...[
              Text(
                widget.hint!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Animated chevron
            RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 0.5).animate(
                CurvedAnimation(parent: _chevronCtrl, curve: Curves.easeInOut),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: accent.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accent =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    _chevronCtrl.forward();
    await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isLight ? 0.28 : 0.50),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => _OptionGridSheet<T>(
        items: widget.items,
        selectedValue: _selected,
        overlayTitle: widget.overlayTitle,
        accent: accent,
        isLight: isLight,
        onSelected: (value) {
          Navigator.of(sheetCtx).pop();
          setState(() => _selected = value);
          widget.onChanged?.call(value);
        },
      ),
    );
    _chevronCtrl.reverse();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet content
// ─────────────────────────────────────────────────────────────────────────────

class _OptionGridSheet<T> extends StatefulWidget {
  final List<OptionGridItem<T>> items;
  final T? selectedValue;
  final String? overlayTitle;
  final Color accent;
  final bool isLight;
  final ValueChanged<T> onSelected;

  const _OptionGridSheet({
    required this.items,
    required this.accent,
    required this.isLight,
    required this.onSelected,
    this.selectedValue,
    this.overlayTitle,
  });

  @override
  State<_OptionGridSheet<T>> createState() => _OptionGridSheetState<T>();
}

class _OptionGridSheetState<T> extends State<_OptionGridSheet<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBig = MediaQuery.sizeOf(context).width > 600;
    final panelBg =
        widget.isLight ? AppColors.lightSurfaceHeader : AppColors.darkSurface;

    return Align(
      alignment: isBig ? Alignment.center : Alignment.bottomCenter,
      child: Container(
        margin: isBig ? const EdgeInsets.all(40) : EdgeInsets.zero,
        constraints: isBig
            ? const BoxConstraints(maxWidth: 540)
            : const BoxConstraints(minWidth: double.infinity),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: isBig
              ? BorderRadius.circular(28)
              : const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: widget.accent.withValues(alpha: 0.18),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.14),
              blurRadius: 40,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: widget.isLight ? 0.08 : 0.32),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title row
            if (widget.overlayTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: widget.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.overlayTitle!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 10),

            // Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = isBig ? 4 : 3;
                  const spacing = 10.0;
                  final chipW =
                      (constraints.maxWidth - spacing * (crossCount - 1)) /
                          crossCount;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(widget.items.length, (i) {
                      return _StaggeredChip<T>(
                        item: widget.items[i],
                        isSelected:
                            widget.items[i].value == widget.selectedValue,
                        accent: widget.accent,
                        isLight: widget.isLight,
                        chipWidth: chipW,
                        staggerIndex: i,
                        totalItems: widget.items.length,
                        parentAnimation: _staggerCtrl,
                        onTap: () => widget.onSelected(widget.items[i].value),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual staggered chip
// ─────────────────────────────────────────────────────────────────────────────

class _StaggeredChip<T> extends StatelessWidget {
  final OptionGridItem<T> item;
  final bool isSelected;
  final Color accent;
  final bool isLight;
  final double chipWidth;
  final int staggerIndex;
  final int totalItems;
  final Animation<double> parentAnimation;
  final VoidCallback onTap;

  const _StaggeredChip({
    required this.item,
    required this.isSelected,
    required this.accent,
    required this.isLight,
    required this.chipWidth,
    required this.staggerIndex,
    required this.totalItems,
    required this.parentAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Distribute stagger across [0.05 … 0.65] of the parent animation
    const maxStagger = 0.55;
    final start = (staggerIndex / totalItems.clamp(1, 100)) * maxStagger;
    final end = (start + 0.45).clamp(0.0, 1.0);
    final itemAnim = CurvedAnimation(
      parent: parentAnimation,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    final selectedBg = accent.withValues(alpha: isLight ? 0.14 : 0.22);
    final unselectedBg = isLight
        ? AppColors.neutral200.withValues(alpha: 0.80)
        : AppColors.darkSurfaceVariant.withValues(alpha: 0.70);
    final selectedBorder = accent.withValues(alpha: 0.60);
    final unselectedBorder = isLight
        ? AppColors.neutral300.withValues(alpha: 0.70)
        : AppColors.neutral700.withValues(alpha: 0.45);

    return AnimatedBuilder(
      animation: itemAnim,
      builder: (context, child) => Transform.scale(
        scale: itemAnim.value.clamp(0.0, 1.0),
        child: Opacity(
          opacity: itemAnim.value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          curve: Curves.easeOutCubic,
          width: chipWidth,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? selectedBorder : unselectedBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 210),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isSelected ? 0.24 : 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: isSelected
                      ? accent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? accent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
