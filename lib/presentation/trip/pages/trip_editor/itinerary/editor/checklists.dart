import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list_item.dart';
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
  // Reused layout constants
  static const double _kSpacingSmall = 8.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kBorderRadiusLarge = 14.0;
  static const double _kBorderRadiusMedium = 12.0;
  static const double _kItemVerticalPadding = 4.0;

  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab(
      items: widget.checklists,
      addButtonLabel: 'Add Checklist',
      addButtonIcon: Icons.checklist_rounded,
      createItem: () =>
          CheckListFacade.newUiEntry(tripId: context.activeTripId, items: []),
      onItemsChanged: widget.onChecklistsChanged,
      titleBuilder: _effectiveTitle,
      previewBuilder: (ctx, cl) => Text(
        '${cl.items.length} items',
        style: Theme.of(ctx).textTheme.labelSmall,
      ),
      accentColorBuilder: (cl) =>
          (cl.title?.isNotEmpty ?? false) ? AppColors.success : AppColors.error,
      isValidBuilder: _isValid,
      expandedBuilder: (ctx, index, checklist, notifyParent) =>
          _buildChecklistEditor(checklist, notifyParent),
    );
  }

  // --- Helpers -----------------------------------------------------------
  String _effectiveTitle(CheckListFacade cl) =>
      (cl.title?.trim().isEmpty ?? true) ? 'Checklist' : cl.title!.trim();

  bool _isValid(CheckListFacade cl) =>
      (cl.title?.isNotEmpty ?? false) && cl.items.isNotEmpty;

  Widget _buildChecklistEditor(
    CheckListFacade checklist,
    VoidCallback notifyParent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key:
              ValueKey('checklist_title_${checklist.id ?? checklist.hashCode}'),
          initialValue: checklist.title ?? '',
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter checklist title',
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(
                Radius.circular(_kBorderRadiusLarge),
              ),
            ),
            filled: true,
          ),
          scrollPadding: const EdgeInsets.only(bottom: 250),
          onChanged: (val) {
            checklist.title = val;
          },
        ),
        const SizedBox(height: _kSpacingMedium),
        EditorTheme.createSectionHeader(
          context,
          icon: Icons.list_rounded,
          title: 'Items',
          iconColor: context.isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight,
        ),
        const SizedBox(height: _kSpacingSmall),
        ...checklist.items
            .asMap()
            .entries
            .map((entry) => _buildChecklistItemRow(
                  index: entry.key,
                  item: entry.value,
                  checklist: checklist,
                  notifyParent: notifyParent,
                )),
        const SizedBox(height: _kSpacingSmall),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item'),
          onPressed: () {
            checklist.items.add(CheckListItem(item: '', isChecked: false));
            notifyParent();
          },
        ),
        const SizedBox(height: _kSpacingSmall),
        _buildValidityIndicator(checklist),
      ],
    );
  }

  Widget _buildChecklistItemRow({
    required int index,
    required CheckListItem item,
    required CheckListFacade checklist,
    required VoidCallback notifyParent,
  }) {
    final itemKey = '${checklist.id ?? checklist.hashCode}_item_$index';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _kItemVerticalPadding),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey(itemKey),
              initialValue: item.item,
              decoration: InputDecoration(
                hintText: 'Item ${index + 1}',
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(
                    Radius.circular(_kBorderRadiusMedium),
                  ),
                ),
                filled: true,
              ),
              scrollPadding: const EdgeInsets.only(bottom: 250),
              onChanged: (val) {
                item.item = val;
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
            ),
            tooltip: 'Delete item',
            onPressed: () {
              checklist.items.removeAt(index);
              notifyParent();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValidityIndicator(CheckListFacade checklist) {
    final valid = _isValid(checklist);
    return Text(
      valid ? 'Valid' : 'Incomplete',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: valid ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
