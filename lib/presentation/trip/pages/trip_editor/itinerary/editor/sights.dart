import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

/// Tab content for managing sights (places) for a day's itinerary.
/// Allows adding, editing (location/time/description/expense), deleting sights.
class ItinerarySightsEditor extends StatefulWidget {
  final List<SightFacade> sights;
  final VoidCallback onSightsChanged;
  final DateTime day;

  const ItinerarySightsEditor({
    super.key,
    required this.sights,
    required this.onSightsChanged,
    required this.day,
  });

  @override
  State<ItinerarySightsEditor> createState() => _ItinerarySightsEditorState();
}

class _ItinerarySightsEditorState extends State<ItinerarySightsEditor> {
  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab(
      items: widget.sights,
      addButtonLabel: 'Add Sight',
      addButtonIcon: Icons.add_location_alt_rounded,
      createItem: () => SightFacade.newEntry(
        tripId: context.activeTrip.tripMetadata.id!,
        day: widget.day,
        defaultCurrency: context.activeTrip.tripMetadata.budget.currency,
        contributors: context.activeTrip.tripMetadata.contributors,
      ),
      onItemsChanged: widget.onSightsChanged,
      titleBuilder: (s) => s.name.isNotEmpty
          ? s.name
          : (s.location?.context.name ?? 'Untitled Sight'),
      previewBuilder: (ctx, s) => s.visitTime != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(_formatTime(s.visitTime!),
                    style: Theme.of(ctx).textTheme.labelSmall),
              ],
            )
          : const SizedBox.shrink(),
      accentColorBuilder: (s) =>
          s.name.isNotEmpty ? AppColors.success : AppColors.error,
      isValidBuilder: (s) => s.validate(),
      expandedBuilder: (ctx, index, sight, notifyParent) =>
          _buildSightEditor(ctx, sight, notifyParent),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _buildSightEditor(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(sight, notifyParent),
        const SizedBox(height: 12),
        _buildLocationSection(context, sight, notifyParent),
        const SizedBox(height: 12),
        _buildTimeSection(context, sight, notifyParent),
        const SizedBox(height: 12),
        _buildExpenseSection(context, sight, notifyParent),
        const SizedBox(height: 12),
        _buildDescriptionSection(context, sight, notifyParent),
        const SizedBox(height: 8),
        Text(
          sight.validate() ? 'Valid' : 'Incomplete',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: sight.validate() ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildTitleField(SightFacade sight, VoidCallback notifyParent) {
    final controller = TextEditingController(text: sight.name);
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'Enter sight name',
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        filled: true,
      ),
      onChanged: (val) {
        sight.name = val.trim();
        notifyParent();
      },
    );
  }

  Widget _buildLocationSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.buildSectionHeader(context,
            icon: Icons.place_rounded,
            title: 'Location',
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: 12),
        PlatformGeoLocationAutoComplete(
          selectedLocation: sight.location,
          onLocationSelected: (loc) {
            sight.location = loc;
            if (sight.name.isEmpty) sight.name = loc.context.name;
            notifyParent();
          },
        ),
      ],
    );
  }

  Widget _buildTimeSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    final timeOfDay = sight.visitTime != null
        ? TimeOfDay.fromDateTime(sight.visitTime!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.buildSectionHeader(context,
            icon: Icons.access_time_rounded,
            title: 'Visit Time',
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                    timeOfDay == null ? 'Set time' : timeOfDay.format(context)),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: timeOfDay ?? TimeOfDay.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    final d = sight.day;
                    sight.visitTime = DateTime(
                        d.year, d.month, d.day, picked.hour, picked.minute);
                    notifyParent();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Clear time',
              onPressed: timeOfDay == null
                  ? null
                  : () {
                      sight.visitTime = null;
                      notifyParent();
                    },
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.buildSectionHeader(context,
            icon: Icons.attach_money_rounded,
            title: 'Expense',
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: 12),
        ExpenditureEditTile(
          expenseUpdator: sight.expense,
          isEditable: true,
          callback: (paidBy, splitBy, totalExpense) {
            sight.expense.paidBy = Map.from(paidBy);
            sight.expense.splitBy = List.from(splitBy);
            sight.expense.totalExpense = totalExpense;
            notifyParent();
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    final controller = TextEditingController(text: sight.description ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.buildSectionHeader(context,
            icon: Icons.description_rounded,
            title: 'Description',
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Details',
            hintText: 'Details about this sight...',
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            filled: true,
          ),
          onChanged: (val) {
            sight.description = val.trim();
            notifyParent();
          },
        ),
      ],
    );
  }
}
