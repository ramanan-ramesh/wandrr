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
      initialChildSize: selectedAction != null ? 0.85 : 0.45,
      maxChildSize: selectedAction != null ? 0.85 : 0.45,
      minChildSize: selectedAction != null ? 0.85 : 0.3,
      builder: (context, scrollController) {
        if (selectedAction == null) {
          return _createSupportedActionsView(
            scrollController,
            bottomPadding,
          );
        }
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

  Widget _createSupportedActionsView(
      ScrollController scrollController, double bottomPadding) {
    final actions = widget.supportedActions.toList();

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Entity action cards in a responsive row ──
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(
                  child: _ActionCard(
                    action: actions[i],
                    onTap: () {
                      if (selectedAction == actions[i]) {
                        return;
                      }
                      setState(() {
                        selectedAction = actions[i];
                      });
                    },
                  ),
                ),
                if (i < actions.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // ── Itinerary item card (full width) ──
          _buildItineraryCard(context),
        ],
      ),
    );
  }

  /// Builds the itinerary card spanning full width with day selector and sub-actions.
  Widget _buildItineraryCard(BuildContext context) {
    final tripMetadata = context.activeTrip.tripMetadata;
    final startDate = tripMetadata.startDate!;
    final endDate = tripMetadata.endDate!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isLight
            ? theme.colorScheme.primaryContainer.withAlpha(40)
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(isLight ? 50 : 40),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: icon + title + day picker ──
          Row(
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.localizations.itinerary,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _ItineraryDaySelector(
                selectedDay: _selectedDay,
                startDate: startDate,
                endDate: endDate,
                onDaySelected: (day) => setState(() => _selectedDay = day),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Sub-action buttons ──
          Row(
            children: [
              _ItinerarySubAction(
                icon: Icons.place_rounded,
                label: context.localizations.sight,
                onTap: () => _onItinerarySubActionTapped(PlanDataType.sight),
              ),
              const SizedBox(width: 8),
              _ItinerarySubAction(
                icon: Icons.note_add_rounded,
                label: context.localizations.note,
                onTap: () => _onItinerarySubActionTapped(PlanDataType.note),
              ),
              const SizedBox(width: 8),
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

/// A compact, visually expressive card showing icon + title only.
/// Uses a subtle gradient tint and rounded shape for a unique travel-app feel.
class _ActionCard extends StatelessWidget {
  final TripEditorAction action;
  final VoidCallback onTap;

  const _ActionCard({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final title = action.getCreatorTitle(context.localizations) ?? '';

    return Card(
      key: const ValueKey('TripEntityCreator_Action_ListTile'),
      elevation: isLight ? 1 : 0,
      shadowColor: theme.colorScheme.primary.withAlpha(40),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withAlpha(isLight ? 50 : 40),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? [
                      theme.colorScheme.primaryContainer.withAlpha(60),
                      theme.colorScheme.primary.withAlpha(20),
                    ]
                  : [
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.primary.withAlpha(25),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
