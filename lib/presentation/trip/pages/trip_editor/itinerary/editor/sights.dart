import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/location_timezone_date_time.dart';
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
  final List<SightFacade> sights;
  final VoidCallback onSightsChanged;

  /// Called only when sight times change (add/remove/reorder sights, or
  /// visit time changes). This should trigger conflict detection.
  final VoidCallback onSightTimesChanged;
  final DateTime day;
  final int? initialExpandedIndex;

  const ItinerarySightsEditor({
    required this.sights,
    required this.onSightsChanged,
    required this.onSightTimesChanged,
    required this.day,
    super.key,
    this.initialExpandedIndex,
  });

  @override
  State<ItinerarySightsEditor> createState() => _ItinerarySightsEditorState();
}

class _ItinerarySightsEditorState extends State<ItinerarySightsEditor> {
  // Reused layout constants
  static const double _kSpacingMedium = 12.0;
  static const double _kBorderRadiusLarge = 14.0;

  /// Tracks the last known "time signature" of the sights list.
  /// Used to detect when structural changes (add/delete/reorder) affect
  /// visit times, without triggering conflict detection on every edit.
  String _lastTimeSignature = '';

  @override
  void initState() {
    super.initState();
    _lastTimeSignature = _computeTimeSignature();
  }

  /// Computes a signature string representing the current visit times.
  String _computeTimeSignature() {
    return widget.sights
        .where((s) => s.visitTime != null)
        .map((s) =>
            '${s.id ?? s.hashCode}:${s.visitTime!.millisecondsSinceEpoch}')
        .join(',');
  }

  /// Called when items change. Checks if times were affected
  /// and triggers conflict detection only if needed.
  void _onItemsChanged() {
    widget.onSightsChanged();
    final newSignature = _computeTimeSignature();
    if (newSignature != _lastTimeSignature) {
      _lastTimeSignature = newSignature;
      widget.onSightTimesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.tripRepository.activeTrip!.isFullyLoaded,
      initialData: context.tripRepository.activeTrip!.isFullyLoadedValue,
      builder: (context, snapshot) {
        final isLoaded = snapshot.data ?? false;
        return CommonCollapsibleTab<SightFacade>(
          isLoading: !isLoaded,
          items: widget.sights,
          addButtonLabel: context.localizations.addSight,
          addButtonIcon: Icons.add_location_alt_rounded,
          createItem: () {
            var activeTrip = context.activeTrip;
            var tripMetadata = activeTrip.tripMetadata;
            return SightFacade.newEntry(
              tripId: tripMetadata.id!,
              day: widget.day,
              defaultCurrency: tripMetadata.budget.currency,
              contributors: tripMetadata.contributors,
            );
          },
          onItemsChanged: _onItemsChanged,
          titleBuilder: (s, context) => s.name.isNotEmpty
              ? s.name
              : (s.location?.context.name ??
                  context.localizations.untitledSight),
          previewBuilder: (ctx, s) => s.visitTime != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(_formatTime(_displayVisitTime(s)!),
                        style: Theme.of(ctx).textTheme.labelSmall),
                  ],
                )
              : const SizedBox.shrink(),
          accentColorBuilder: (s) =>
              s.name.isNotEmpty ? AppColors.success : AppColors.error,
          isValidBuilder: (s) => s.getValidationErrors().isEmpty,
          expandedBuilder: (ctx, index, sight, notifyParent) =>
              _buildSightEditor(ctx, sight, notifyParent),
          initialExpandedIndex: widget.initialExpandedIndex,
        );
      },
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  DateTime? _displayVisitTime(SightFacade sight) {
    if (sight.visitTime == null) {
      return null;
    }
    return LocationTimezoneDateTime.decodeUtcToWallClock(
      storedDateTime: sight.visitTime!,
      location: sight.location,
    );
  }

  RelativeRect _getButtonPosition(BuildContext context) {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final offset = button.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + button.size.height,
      overlay.size.width - offset.dx - button.size.width,
      overlay.size.height - offset.dy - button.size.height,
    );
  }

  Widget _buildSightEditor(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(sight, notifyParent, context),
        const SizedBox(height: _kSpacingMedium),
        _buildLocationSection(context, sight, notifyParent),
        const SizedBox(height: _kSpacingMedium),
        _buildTimeSection(context, sight, notifyParent),
        const SizedBox(height: _kSpacingMedium),
        _buildDescriptionSection(context, sight, notifyParent),
        const SizedBox(height: _kSpacingMedium),
        _buildExpenseSection(context, sight, notifyParent),
      ],
    );
  }

  Widget _buildTitleField(
      SightFacade sight, VoidCallback notifyParent, BuildContext context) {
    return _SightTitleField(
      sight: sight,
      notifyParent: notifyParent,
      borderRadius: _kBorderRadiusLarge,
    );
  }

  Widget _buildLocationSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
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
          selectedLocation: sight.location,
          onLocationSelected: (loc) {
            if (sight.visitTime != null) {
              sight.visitTime = LocationTimezoneDateTime.retargetStoredDateTime(
                storedDateTime: sight.visitTime!,
                oldLocation: sight.location,
                newLocation: loc,
              );
            }
            sight.location = loc;
            notifyParent();
          },
        ),
      ],
    );
  }

  Widget _buildTimeSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    final visitTimeForDisplay = _displayVisitTime(sight);
    final timeOfDay = visitTimeForDisplay != null
        ? TimeOfDay.fromDateTime(visitTimeForDisplay)
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (sight.location != null)
              TimezoneIndicator(location: sight.location!),
            // Combined set/clear time button
            OutlinedButton.icon(
              icon: Icon(
                timeOfDay == null
                    ? Icons.access_time
                    : Icons.access_time_filled_rounded,
                size: 18,
              ),
              label: Text(
                timeOfDay == null
                    ? context.localizations.setTime
                    : timeOfDay.format(context),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () async {
                // If time is set, show a menu: edit or clear
                if (timeOfDay != null) {
                  final action = await showMenu<String>(
                    context: context,
                    position: _getButtonPosition(context),
                    items: [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(context.localizations.setTime),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.clear_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(context.localizations.clearTime),
                          ],
                        ),
                      ),
                    ],
                  );
                  if (action == 'clear') {
                    sight.visitTime = null;
                    notifyParent();
                    return;
                  }
                  if (action != 'edit') {
                    return;
                  }
                }
                if (!mounted || !context.mounted) {
                  return;
                }
                final picked = await showTimePicker(
                  context: context,
                  initialTime: timeOfDay ?? TimeOfDay.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context),
                    child: child!,
                  ),
                );
                if (!mounted || !context.mounted) {
                  return;
                }
                if (picked != null) {
                  final d = sight.day;
                  final wallClock = DateTime(
                    d.year,
                    d.month,
                    d.day,
                    picked.hour,
                    picked.minute,
                  );
                  sight.visitTime =
                      LocationTimezoneDateTime.encodeWallClockToUtc(
                    wallClock: wallClock,
                    location: sight.location,
                  );
                  notifyParent();
                }
              },
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
        EditorTheme.createSectionHeader(context,
            icon: Icons.attach_money_rounded,
            title: context.localizations.expense,
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight),
        const SizedBox(height: _kSpacingMedium),
        ExpenditureEditTile(
          key: ValueKey('expense_${sight.id ?? 'new'}'),
          expenseFacade: sight.expense,
          isEditable: true,
          callback: (paidBy, splitBy, totalExpense) {
            sight.expense.paidBy = Map.from(paidBy);
            sight.expense.splitBy = List.from(splitBy);
            sight.expense.currency = totalExpense.currency;
            notifyParent();
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
      BuildContext context, SightFacade sight, VoidCallback notifyParent) {
    var note = Note(sight.description ?? '');
    return EditorTheme.createSection(
      child: NoteEditor(
        key: ValueKey('sight_description_${sight.id}'),
        note: note,
        onChanged: () {
          sight.description = note.text;
          // Don't call notifyParent() here - it causes rebuilds on every keystroke
          // The data is already mutated via the Note object
          // Parent will be notified when the item is collapsed or on other actions
        },
      ),
      context: context,
    );
  }
}

/// Stateful widget for sight title field that maintains its own controller
/// to prevent losing focus during parent rebuilds
class _SightTitleField extends StatefulWidget {
  final SightFacade sight;
  final VoidCallback notifyParent;
  final double borderRadius;

  const _SightTitleField({
    required this.sight,
    required this.notifyParent,
    required this.borderRadius,
  });

  @override
  State<_SightTitleField> createState() => _SightTitleFieldState();
}

class _SightTitleFieldState extends State<_SightTitleField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.sight.name);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_SightTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller if the sight object itself changed
    if (widget.sight != oldWidget.sight) {
      _controller.removeListener(_onTextChanged);
      _controller.text = widget.sight.name;
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.sight.name = _controller.text;
    // Notify parent to update the header with new title
    widget.notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.localizations.title,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
        ),
        filled: true,
      ),
      scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
    );
  }
}
