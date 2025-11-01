import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list_item.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';

class ItineraryChecklistsEditor extends StatefulWidget {
  final List<CheckListFacade> checklists;
  final VoidCallback onChecklistsChanged;

  const ItineraryChecklistsEditor({
    super.key,
    required this.checklists,
    required this.onChecklistsChanged,
  });

  @override
  State<ItineraryChecklistsEditor> createState() =>
      _ItineraryChecklistsEditorState();
}

class _ItineraryChecklistsEditorState extends State<ItineraryChecklistsEditor> {
  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab(
      items: widget.checklists,
      addButtonLabel: 'Add Checklist',
      addButtonIcon: Icons.checklist_rounded,
      createItem: () => CheckListFacade.newUiEntry(
          tripId: context.activeTrip.tripMetadata.id!, items: []),
      onItemsChanged: widget.onChecklistsChanged,
      titleBuilder: (cl) =>
          cl.title?.trim().isEmpty ?? true ? 'Checklist' : cl.title!.trim(),
      previewBuilder: (ctx, cl) => Text('${cl.items.length} items',
          style: Theme.of(ctx).textTheme.labelSmall),
      accentColorBuilder: (cl) =>
          cl.title?.isNotEmpty ?? false ? AppColors.success : AppColors.error,
      isValidBuilder: (cl) =>
          (cl.title?.isNotEmpty ?? false) && cl.items.isNotEmpty,
      expandedBuilder: (ctx, index, checklist, notifyParent) =>
          _buildChecklistEditor(ctx, checklist, notifyParent),
    );
  }

  Widget _buildChecklistEditor(BuildContext context, CheckListFacade checklist,
      VoidCallback notifyParent) {
    final titleController = TextEditingController(text: checklist.title ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter checklist title',
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            filled: true,
          ),
          onChanged: (val) {
            checklist.title = val.trim();
            notifyParent();
          },
        ),
        const SizedBox(height: 12),
        EditorTheme.buildSectionHeader(context,
            icon: Icons.list_rounded,
            title: 'Items',
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: 8),
        ...checklist.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final itemController = TextEditingController(text: item.item);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                      hintText: 'Item ${idx + 1}',
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      filled: true,
                    ),
                    onChanged: (val) {
                      item.item = val.trim();
                      notifyParent();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error),
                  tooltip: 'Delete item',
                  onPressed: () {
                    checklist.items.removeAt(idx);
                    notifyParent();
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item'),
          onPressed: () {
            checklist.items.add(CheckListItem(item: '', isChecked: false));
            notifyParent();
          },
        ),
        const SizedBox(height: 8),
        Text(
          (checklist.title?.isNotEmpty ?? false) && checklist.items.isNotEmpty
              ? 'Valid'
              : 'Incomplete',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: (checklist.title?.isNotEmpty ?? false) &&
                        checklist.items.isNotEmpty
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
