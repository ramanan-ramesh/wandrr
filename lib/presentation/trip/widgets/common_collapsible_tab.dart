import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Generic reusable collapsible tab list for itinerary editing pages.
/// Provides: add button + count header, reorderable list, per-item collapse/expand,
/// drag handle, delete button, arrow indicator, optional preview line, and
/// customizable expanded editor content.
class CommonCollapsibleTab<T> extends StatefulWidget {
  final List<T> items;
  final String addButtonLabel;
  final IconData addButtonIcon;
  final T Function() createItem;
  final VoidCallback onItemsChanged;
  final String Function(T item) titleBuilder;
  final Widget Function(BuildContext context, T item)? previewBuilder;
  final Color Function(T item)? accentColorBuilder;
  final Widget Function(
          BuildContext context, int index, T item, VoidCallback notifyParent)
      expandedBuilder;
  final bool Function(T item)? isValidBuilder;
  final Widget Function(
    BuildContext context,
    int index,
    T item,
    bool expanded,
    Color accentColor,
    VoidCallback toggle,
    VoidCallback delete,
    VoidCallback notifyParent,
  )? itemHeaderBuilder;
  final int? initialExpandedIndex;

  const CommonCollapsibleTab({
    super.key,
    required this.items,
    required this.addButtonLabel,
    required this.addButtonIcon,
    required this.createItem,
    required this.onItemsChanged,
    required this.titleBuilder,
    required this.expandedBuilder,
    this.previewBuilder,
    this.accentColorBuilder,
    this.isValidBuilder,
    this.itemHeaderBuilder,
    this.initialExpandedIndex,
  });

  @override
  State<CommonCollapsibleTab<T>> createState() =>
      _CommonCollapsibleTabState<T>();
}

class _CommonCollapsibleTabState<T> extends State<CommonCollapsibleTab<T>> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.initialExpandedIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState(context);
    }
    return Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildReorderableList()),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: Icon(widget.addButtonIcon),
            label: Text(widget.addButtonLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const Spacer(),
          Text(
            '${widget.items.length}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.isLightTheme
                      ? AppColors.neutral600
                      : AppColors.neutral400,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.addButtonIcon,
                size: 72,
                color: context.isLightTheme
                    ? AppColors.neutral400
                    : AppColors.neutral600),
            const SizedBox(height: 16),
            Text('No entries',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Add some to get started',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: Icon(widget.addButtonIcon),
              label: Text(widget.addButtonLabel),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return ReorderableListView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + keyboardHeight),
          itemCount: widget.items.length,
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = widget.items.removeAt(oldIndex);
              widget.items.insert(newIndex, item);
              widget.onItemsChanged();
            });
          },
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final expanded = _expandedIndex == index;
            final accent =
                widget.accentColorBuilder?.call(item) ?? AppColors.brandPrimary;
            final valid = widget.isValidBuilder?.call(item);
            final handleColor = valid == null
                ? accent
                : (valid ? AppColors.success : AppColors.error);
            return _CollapsibleEntry<T>(
              key: ObjectKey(item),
              index: index,
              item: item,
              expanded: expanded,
              accentColor: handleColor,
              titleBuilder: widget.titleBuilder,
              previewBuilder: widget.previewBuilder,
              onToggle: () =>
                  setState(() => _expandedIndex = expanded ? null : index),
              onDelete: () => _deleteItem(index),
              expandedBuilder: (ctx, notify) =>
                  widget.expandedBuilder(ctx, index, item, notify),
              notifyChanged: _notifyChanged,
              itemHeaderBuilder: widget.itemHeaderBuilder,
            );
          },
        );
      },
    );
  }

  void _addItem() {
    setState(() {
      widget.items.add(widget.createItem());
      _expandedIndex = widget.items.length - 1;
    });
    widget.onItemsChanged();
  }

  void _deleteItem(int index) {
    setState(() {
      widget.items.removeAt(index);
      if (_expandedIndex == index) _expandedIndex = null;
    });
    widget.onItemsChanged();
  }

  void _notifyChanged() {
    widget.onItemsChanged();
    setState(() {}); // refresh headers (title/preview)
  }
}

class _CollapsibleEntry<T> extends StatelessWidget {
  final int index;
  final T item;
  final bool expanded;
  final Color accentColor;
  final String Function(T) titleBuilder;
  final Widget Function(BuildContext, T)? previewBuilder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Widget Function(BuildContext, VoidCallback notifyParent)
      expandedBuilder;
  final VoidCallback notifyChanged;
  final Widget Function(
    BuildContext context,
    int index,
    T item,
    bool expanded,
    Color accentColor,
    VoidCallback toggle,
    VoidCallback delete,
    VoidCallback notifyParent,
  )? itemHeaderBuilder;

  const _CollapsibleEntry({
    super.key,
    required this.index,
    required this.item,
    required this.expanded,
    required this.accentColor,
    required this.titleBuilder,
    required this.previewBuilder,
    required this.onToggle,
    required this.onDelete,
    required this.expandedBuilder,
    required this.notifyChanged,
    this.itemHeaderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.isLightTheme
            ? Colors.white.withValues(alpha: 0.95)
            : AppColors.darkSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            if (itemHeaderBuilder != null)
              itemHeaderBuilder!(
                context,
                index,
                item,
                expanded,
                accentColor,
                onToggle,
                onDelete,
                notifyChanged,
              )
            else
              _buildHeader(context),
            if (expanded) _buildExpanded(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = titleBuilder(item);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.drag_handle_rounded, color: accentColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        title,
                        key: ValueKey(title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (previewBuilder != null) ...[
                      const SizedBox(height: 4),
                      previewBuilder!(context, item),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: accentColor),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_forever_rounded),
                color: AppColors.error,
                onPressed: onDelete,
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: expandedBuilder(context, notifyChanged),
    );
  }
}
