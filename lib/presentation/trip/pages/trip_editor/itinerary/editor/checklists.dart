import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list_item.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';

class ItineraryChecklistsEditor extends StatelessWidget {
  final List<CheckListFacade> checklists;
  final VoidCallback onChecklistsChanged;
  final int? initialExpandedIndex;

  const ItineraryChecklistsEditor({
    super.key,
    required this.checklists,
    required this.onChecklistsChanged,
    this.initialExpandedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab(
      items: checklists,
      addButtonLabel: context.localizations.addChecklist,
      addButtonIcon: Icons.checklist_rounded,
      createItem: () => CheckListFacade.newUiEntry(
        tripId: context.activeTripId,
        items: [],
      ),
      onItemsChanged: onChecklistsChanged,
      titleBuilder: _effectiveTitle,
      previewBuilder: (ctx, cl) => Text(
        '${cl.items.length} ${ctx.localizations.items}',
        style: Theme.of(ctx).textTheme.labelSmall,
      ),
      accentColorBuilder: (cl) =>
          (cl.title?.isNotEmpty ?? false) ? AppColors.success : AppColors.error,
      isValidBuilder: _isValid,
      expandedBuilder: (ctx, index, checklist, notifyParent) =>
          _ChecklistEditorContent(
        checklist: checklist,
        onChanged: onChecklistsChanged,
      ),
      initialExpandedIndex: initialExpandedIndex,
    );
  }

  String _effectiveTitle(CheckListFacade cl, BuildContext context) =>
      (cl.title?.trim().isEmpty ?? true)
          ? context.localizations.untitledChecklist
          : cl.title!.trim();

  bool _isValid(CheckListFacade cl) =>
      (cl.title?.isNotEmpty ?? false) && cl.items.isNotEmpty;
}

/// Stateful content for a single checklist editor
class _ChecklistEditorContent extends StatefulWidget {
  final CheckListFacade checklist;
  final VoidCallback onChanged;

  const _ChecklistEditorContent({
    required this.checklist,
    required this.onChanged,
  });

  @override
  State<_ChecklistEditorContent> createState() =>
      _ChecklistEditorContentState();
}

class _ChecklistEditorContentState extends State<_ChecklistEditorContent> {
  static const double _kSpacingSmall = 8.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kBorderRadiusLarge = 14.0;

  late TextEditingController _titleController;
  final Map<CheckListItem, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.checklist.title ?? '');
    _initializeKeys();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _initializeKeys() {
    for (final item in widget.checklist.items) {
      if (!_itemKeys.containsKey(item)) {
        _itemKeys[item] = GlobalKey();
      }
    }
  }

  void _tryAddItem() {
    if (widget.checklist.items.any((item) => item.item.trim().isEmpty)) {
      return;
    }
    final newItem = CheckListItem(item: '', isChecked: false);
    final newKey = GlobalKey();
    setState(() {
      widget.checklist.items.add(newItem);
      _itemKeys[newItem] = newKey;
    });
    widget.onChanged();
    // Focus the newly added item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = newKey.currentContext;
      if (context != null) {
        final state = context.findAncestorStateOfType<_ChecklistItemRowState>();
        state?._focusNode.requestFocus();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = widget.checklist.items[index];
      _itemKeys.remove(item);
      widget.checklist.items.removeAt(index);
    });
    widget.onChanged();
  }

  void _toggleItemChecked(int index) {
    setState(() {
      widget.checklist.items[index].isChecked =
          !widget.checklist.items[index].isChecked;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = (widget.checklist.title?.isNotEmpty ?? false) &&
        widget.checklist.items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title field
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: context.localizations.title,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius:
                  BorderRadius.all(Radius.circular(_kBorderRadiusLarge)),
            ),
            filled: true,
          ),
          scrollPadding: const EdgeInsets.only(bottom: 250),
          onChanged: (val) {
            widget.checklist.title = val;
            widget.onChanged();
          },
        ),
        const SizedBox(height: _kSpacingMedium),

        // Items section header
        EditorTheme.createSectionHeader(
          context,
          icon: Icons.list_rounded,
          title: context.localizations.items,
          iconColor: context.isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight,
        ),
        const SizedBox(height: _kSpacingSmall),

        // Items list
        ...widget.checklist.items.asMap().entries.map((entry) {
          final item = entry.value;
          return _ChecklistItemRow(
            key: _itemKeys[item] ?? ObjectKey(item),
            item: item,
            itemNumber: entry.key + 1,
            onChanged: widget.onChanged,
            onDelete: () => _removeItem(entry.key),
            onToggleChecked: () => _toggleItemChecked(entry.key),
          );
        }),

        const SizedBox(height: _kSpacingSmall),

        // Add item button
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(context.localizations.addItem),
          onPressed: _tryAddItem,
        ),
      ],
    );
  }
}

/// Individual checklist item row with self-managed state
class _ChecklistItemRow extends StatefulWidget {
  final CheckListItem item;
  final int itemNumber;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onToggleChecked;

  const _ChecklistItemRow({
    super.key,
    required this.item,
    required this.itemNumber,
    required this.onChanged,
    required this.onDelete,
    required this.onToggleChecked,
  });

  @override
  State<_ChecklistItemRow> createState() => _ChecklistItemRowState();
}

class _ChecklistItemRowState extends State<_ChecklistItemRow> {
  static const double _kBorderRadiusMedium = 12.0;
  static const double _kItemVerticalPadding = 4.0;

  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.item);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _kItemVerticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          Checkbox(
            value: widget.item.isChecked,
            onChanged: (_) => widget.onToggleChecked(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '${context.localizations.item} ${widget.itemNumber}',
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(
                    Radius.circular(_kBorderRadiusMedium),
                  ),
                ),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                decoration: widget.item.isChecked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: widget.item.isChecked
                    ? Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6)
                    : null,
              ),
              scrollPadding: const EdgeInsets.only(bottom: 250),
              onChanged: (val) {
                widget.item.item = val;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
            visualDensity: VisualDensity.compact,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
