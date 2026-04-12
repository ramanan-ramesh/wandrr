import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/editor_page_factory.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class TripEntityCreatorBottomSheet extends StatefulWidget {
  final Iterable<TripEditorAction> supportedActions;

  /// Notifier for the currently displayed itinerary day.
  /// Used to know which day to create new itinerary items for.
  final DateTime currentlyDisplayedItineraryDate;

  const TripEntityCreatorBottomSheet({
    required this.supportedActions,
    required this.currentlyDisplayedItineraryDate,
    super.key,
  });

  @override
  State<TripEntityCreatorBottomSheet> createState() =>
      _TripEntityCreatorBottomSheetState();
}

class _TripEntityCreatorBottomSheetState
    extends State<TripEntityCreatorBottomSheet> {
  TripEditorAction? selectedAction;
  Widget? _cachedEditorPage;

  /// The day that will be used when creating a new itinerary item.
  /// Defaults to the currently displayed itinerary day; the user may change it.
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.currentlyDisplayedItineraryDate;
  }

  @override
  Widget build(BuildContext context) {
    const fabBottomMargin = 25.0;
    const bottomPadding =
        TripEditorPageConstants.fabSize + fabBottomMargin + 16.0;

    return DraggableScrollableSheet(
      expand: false,
      shouldCloseOnMinExtent: false,
      initialChildSize: selectedAction != null ? 0.8 : 0.7,
      maxChildSize: 0.85,
      minChildSize: selectedAction != null ? 0.8 : 0.5,
      builder: (context, scrollController) {
        if (selectedAction == null) {
          return _createSupportedActionsListView(
              scrollController, bottomPadding);
        }
        // Build the editor page once and cache it. Subsequent builder calls
        // (from scrolling) reuse the cached widget so editableClone/keys
        // remain stable.
        _cachedEditorPage ??= _buildEditorPage(context, scrollController);
        return _cachedEditorPage!;
      },
    );
  }

  Widget _buildEditorPage(
      BuildContext context, ScrollController scrollController) {
    final entity = selectedAction!.createEntity(context);
    final factory = EditorPageFactory(
      tripData: context.activeTrip,
      title:
          selectedAction!.getSubtitle(context.localizations, isEditing: false),
      isEditing: false,
      onClosePressed: () => setState(() {
        selectedAction = null;
        _cachedEditorPage = null;
      }),
      scrollController: scrollController,
    );
    return factory.createPage(entity) ?? const SizedBox.shrink();
  }

  Widget _createSupportedActionsListView(
      ScrollController scrollController, double bottomPadding) {
    // Build the list: supported actions + itinerary item tile
    final tiles = <Widget>[
      ...widget.supportedActions.map(
        (action) => _buildSupportedActionTile(action, context),
      ),
      _buildItineraryItemTile(context),
    ];

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: bottomPadding),
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
      itemBuilder: (BuildContext context, int index) => tiles[index],
      itemCount: tiles.length,
    );
  }

  Widget _buildSupportedActionTile(
      TripEditorAction action, BuildContext context) {
    final icon = action.icon;
    final title = action.getCreatorTitle(context.localizations);
    final subtitle =
        action.getSubtitle(context.localizations, isEditing: false);
    return ListTile(
      key: const ValueKey('TripEntityCreator_Action_ListTile'),
      contentPadding: const EdgeInsets.all(20.0),
      onTap: () {
        if (selectedAction == action) {
          return;
        }

        setState(() {
          selectedAction = action;
        });
      },
      leading: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color!.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28.0,
        ),
      ),
      title: title == null
          ? null
          : Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
      subtitle: Text(subtitle),
    );
  }

  /// Builds the "Itinerary Item" tile with a day selector and three sub-action buttons.
  Widget _buildItineraryItemTile(BuildContext context) {
    final tripMetadata = context.activeTrip.tripMetadata;
    final startDate = tripMetadata.startDate!;
    final endDate = tripMetadata.endDate!;

    return ListTile(
      contentPadding: const EdgeInsets.all(20.0),
      leading: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color!.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.travel_explore_rounded, size: 28.0),
      ),
      title: Row(
        children: [
          Text(
            context.localizations.itinerary,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          _ItineraryDaySelector(
            selectedDay: _selectedDay,
            startDate: startDate,
            endDate: endDate,
            onDaySelected: (day) => setState(() => _selectedDay = day),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sub-action buttons ────────────────────────────────────────────
          Row(
            children: [
              _ItinerarySubAction(
                icon: Icons.place_rounded,
                label: context.localizations.sight,
                onTap: () => _onItinerarySubActionTapped(PlanDataType.sight),
              ),
              const SizedBox(width: 12),
              _ItinerarySubAction(
                icon: Icons.note_add_rounded,
                label: context.localizations.note,
                onTap: () => _onItinerarySubActionTapped(PlanDataType.note),
              ),
              const SizedBox(width: 12),
              _ItinerarySubAction(
                icon: Icons.checklist_rounded,
                label: context.localizations.checklist,
                onTap: () =>
                    _onItinerarySubActionTapped(PlanDataType.checklist),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onItinerarySubActionTapped(PlanDataType type) {
    final day = _selectedDay;
    final event = EditItineraryPlanData(
      day: day,
      planDataEditorConfig: CreateNewItineraryPlanDataComponentConfig(
        planDataType: type,
        date: day,
      ),
    );
    Navigator.of(context).pop();
    context.addTripManagementEvent(event);
  }
}

/// A compact chip-style date selector for picking the itinerary day.
class _ItineraryDaySelector extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onDaySelected;

  const _ItineraryDaySelector({
    required this.selectedDay,
    required this.startDate,
    required this.endDate,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformDatePicker(
      selectedDate: selectedDay,
      calendarConfig: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: startDate,
        lastDate: endDate,
        currentDate: selectedDay,
      ),
      onDateSelected: onDaySelected,
    );
  }
}

/// A small rounded button for itinerary sub-actions (sight/note/checklist).
class _ItinerarySubAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ItinerarySubAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
