import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';
import 'package:wandrr/presentation/trip/widgets/time_zone_indicator.dart';

/// Tab content for managing sights (places) for a day's itinerary.
/// Allows adding, editing (location/time/description/expense), deleting sights.
class ItinerarySightsEditor extends StatefulWidget {
  final List<Sight> sights;
  final void Function(List<Sight> updated) onSightsChanged;
  final DateTime day;
  final int? initialExpandedIndex;

  const ItinerarySightsEditor({
    super.key,
    required this.sights,
    required this.onSightsChanged,
    required this.day,
    this.initialExpandedIndex,
  });

  @override
  State<ItinerarySightsEditor> createState() => _ItinerarySightsEditorState();
}

class _ItinerarySightsEditorState extends State<ItinerarySightsEditor> {
  void _updateSight(int index, Sight updated) {
    final newList = List<Sight>.from(widget.sights);
    newList[index] = updated;
    widget.onSightsChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab<Sight>(
      items: widget.sights,
      addButtonLabel: context.localizations.addSight,
      addButtonIcon: Icons.add_location_alt_rounded,
      createItem: () {
        var activeTrip = context.activeTrip;
        var tripMetadata = activeTrip.tripMetadata;
        return Sight.newEntry(
          tripId: tripMetadata.id!,
          day: widget.day,
          defaultCurrency: tripMetadata.budget.currency,
          contributors: tripMetadata.contributors,
        );
      },
      onItemsChanged: () => widget.onSightsChanged(widget.sights),
      titleBuilder: (s, context) => s.name.isNotEmpty
          ? s.name
          : (s.location?.context.name ?? context.localizations.untitledSight),
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
      expandedBuilder: (ctx, index, sight, notifyParent) => _SightEditorContent(
        sight: sight,
        onSightChanged: (updated) {
          _updateSight(index, updated);
          notifyParent();
        },
      ),
      initialExpandedIndex: widget.initialExpandedIndex,
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Stateful editor content for a single sight
class _SightEditorContent extends StatefulWidget {
  final Sight sight;
  final void Function(Sight updated) onSightChanged;

  const _SightEditorContent({
    required this.sight,
    required this.onSightChanged,
  });

  @override
  State<_SightEditorContent> createState() => _SightEditorContentState();
}

class _SightEditorContentState extends State<_SightEditorContent> {
  static const double _kSpacingMedium = 12.0;
  static const double _kBorderRadiusLarge = 14.0;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sight.name);
    _descriptionController =
        TextEditingController(text: widget.sight.description ?? '');
  }

  @override
  void didUpdateWidget(_SightEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sight != oldWidget.sight) {
      _titleController.text = widget.sight.name;
      _descriptionController.text = widget.sight.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(context),
        const SizedBox(height: _kSpacingMedium),
        _buildLocationSection(context),
        const SizedBox(height: _kSpacingMedium),
        _buildTimeSection(context),
        const SizedBox(height: _kSpacingMedium),
        _buildDescriptionSection(context),
        const SizedBox(height: _kSpacingMedium),
        _buildExpenseSection(context),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: context.localizations.title,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(_kBorderRadiusLarge)),
        ),
        filled: true,
      ),
      scrollPadding: const EdgeInsets.only(bottom: 250),
      onChanged: (value) {
        widget.onSightChanged(widget.sight.copyWith(name: value));
      },
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.createSectionHeader(context,
            icon: Icons.place_rounded,
            title: context.localizations.location,
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: _kSpacingMedium),
        PlatformGeoLocationAutoComplete(
          selectedLocation: widget.sight.location,
          onLocationSelected: (loc) {
            widget.onSightChanged(widget.sight.copyWith(location: loc));
          },
        ),
      ],
    );
  }

  Widget _buildTimeSection(BuildContext context) {
    final timeOfDay = widget.sight.visitTime != null
        ? TimeOfDay.fromDateTime(widget.sight.visitTime!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.createSectionHeader(context,
            icon: Icons.access_time_rounded,
            title: 'Visit Time',
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: _kSpacingMedium),
        Row(
          children: [
            if (widget.sight.location != null)
              TimezoneIndicator(location: widget.sight.location!),
            if (widget.sight.location != null)
              const SizedBox(width: _kSpacingMedium),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(timeOfDay == null
                    ? context.localizations.setTime
                    : timeOfDay.format(context)),
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
                    final d = widget.sight.day;
                    widget.onSightChanged(widget.sight.copyWith(
                      visitTime: DateTime(
                          d.year, d.month, d.day, picked.hour, picked.minute),
                    ));
                  }
                },
              ),
            ),
            const SizedBox(width: _kSpacingMedium),
            IconButton(
              onPressed: timeOfDay == null
                  ? null
                  : () {
                      // Create draft to allow null visitTime
                      widget.onSightChanged(Sight.draft(
                        tripId: widget.sight.tripId,
                        id: widget.sight.id,
                        day: widget.sight.day,
                        name: widget.sight.name,
                        expense: widget.sight.expense,
                        location: widget.sight.location,
                        visitTime: null,
                        description: widget.sight.description,
                      ));
                    },
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTheme.createSectionHeader(context,
            icon: Icons.attach_money_rounded,
            title: context.localizations.expense,
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: _kSpacingMedium),
        ExpenditureEditTile(
          expenseFacade: widget.sight.expense,
          isEditable: true,
          callback: (paidBy, splitBy, totalExpense) {
            widget.onSightChanged(widget.sight.copyWith(
              expense: widget.sight.expense.copyWith(
                paidBy: Map.from(paidBy),
                splitBy: List.from(splitBy),
                currency: totalExpense.currency,
              ),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    var note = Note(_descriptionController.text);
    return EditorTheme.createSection(
      child: NoteEditor(
        key: ValueKey('sight_description_${widget.sight.id}'),
        note: note,
        onChanged: () {
          widget.onSightChanged(widget.sight.copyWith(description: note.text));
        },
      ),
      context: context,
    );
  }
}
