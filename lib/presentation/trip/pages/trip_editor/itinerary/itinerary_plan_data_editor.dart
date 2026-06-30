import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/bubble_tab_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/editor/checklists.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

import 'editor/notes.dart';
import 'editor/sights.dart';

class ItineraryPlanDataEditor extends StatefulWidget {
  /// The detached clone of the plan data. This widget works on this object
  /// exclusively and never touches the repository's live instance.
  final ItineraryPlanData planData;

  /// Called whenever in-editor data changes so the validity notifier
  /// in ConflictAwareActionPage can be updated. Does NOT persist data.
  final VoidCallback onPlanDataUpdated;
  final ItineraryPlanDataEditorConfig config;

  const ItineraryPlanDataEditor({
    required this.planData,
    required this.onPlanDataUpdated,
    required this.config,
    super.key,
  });

  @override
  State<ItineraryPlanDataEditor> createState() =>
      ItineraryPlanDataEditorState();
}

class ItineraryPlanDataEditorState extends State<ItineraryPlanDataEditor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ---------------------------------------------------------------------------
  // Stable working lists. These are the sole source of truth during editing.
  // They are never written back to _planData until syncToEntity() is called
  // (which happens only when the user presses the FAB).
  // ---------------------------------------------------------------------------
  late final List<SightFacade> _stableSights;
  late final List<Note> _stableNotes;
  late final List<CheckListFacade> _stableChecklists;

  late final List<Widget> _tabWidgets;
  bool _tabWidgetsInitialized = false;

  ItineraryPlanData get planData => widget.planData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = _initialTabIndex(widget.config.planDataType);
    _tabController.addListener(_onTabChanged);

    // Snapshot the plan data into stable mutable lists once.
    // planData is already a clone so reading its getters here is safe.
    _stableSights = List<SightFacade>.from(planData.sights);
    _stableNotes = planData.notes.map(Note.new).toList();
    _stableChecklists = List<CheckListFacade>.from(planData.checkLists);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.config is CreateNewItineraryPlanDataComponentConfig) {
        _createNewItineraryPlanDataComponent(widget.config.planDataType);
      }
      setState(() {
        _tabWidgets = _buildTabWidgets();
        _tabWidgetsInitialized = true;
      });
      // Notify validity after any new item was appended.
      widget.onPlanDataUpdated();
    });
  }

  // ---------------------------------------------------------------------------
  // Called by EditorPageFactory's onActionInvoked BEFORE emitting the update
  // event. Writes the stable lists into _planData so the serialisation path
  // sees the correct data.
  // ---------------------------------------------------------------------------
  void syncToEntity() {
    planData.sights = List<SightFacade>.from(_stableSights);
    planData.notes = _stableNotes.map((n) => n.text).toList();
    planData.checkLists = List<CheckListFacade>.from(_stableChecklists);
  }

  /// Validates current editor state against the stable working lists.
  /// Used by the parent to keep the FAB enabled/disabled correctly.
  bool validateCurrentState() {
    final tempPlanData = ItineraryPlanData(
      tripId: planData.tripId,
      day: planData.day,
      id: planData.id,
      sights: _stableSights,
      notes: _stableNotes.map((n) => n.text).toList(),
      checkLists: _stableChecklists,
    );
    return tempPlanData.getValidationErrors().isEmpty;
  }

  /// Called by child editors whenever data changes. Syncs the stable working
  /// lists back to [planData] so the bloc always sees current data for
  /// validation, then notifies the parent.
  void _onDataChanged() {
    syncToEntity();
    widget.onPlanDataUpdated();
    // Refresh tab bar so item counts stay up-to-date.
    setState(() {});
  }

  List<Widget> _buildTabWidgets() => [
        ItinerarySightsEditor(
          sights: _stableSights,
          onSightsChanged: _onDataChanged,
          onSightTimesChanged: _onDataChanged,
          day: planData.day,
          initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.sight),
        ),
        ItineraryNotesEditor(
          stableNotes: _stableNotes,
          onNotesChanged: (_) => _onDataChanged(),
          initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.note),
        ),
        ItineraryChecklistsEditor(
          checklists: _stableChecklists,
          onChecklistsChanged: _onDataChanged,
          initialExpandedIndex:
              _getInitialExpandedIndex(PlanDataType.checklist),
        ),
      ];

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  int _initialTabIndex(PlanDataType type) {
    switch (type) {
      case PlanDataType.sight:
        return 0;
      case PlanDataType.note:
        return 1;
      case PlanDataType.checklist:
        return 2;
    }
  }

  @override
  void didUpdateWidget(covariant ItineraryPlanDataEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planData != planData) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDateHeader(),
        const SizedBox(height: 8),
        _buildTabBar(),
        const SizedBox(height: 6),
        if (_tabWidgetsInitialized)
          IndexedStack(
            index: _tabController.index,
            children: _tabWidgets,
          )
        else
          const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  /// Read-only date header — shows the itinerary day using the app's standard
  /// text colour (no blue accent) so it matches the rest of the trip editor.
  Widget _buildDateHeader() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = planData.day;
    final dateLabel = '${months[day.month - 1]} ${day.day}, ${day.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    // Show counts next to tab labels so users know how many items exist per tab.
    // Format: "Places (3)" — only shown when the list is non-empty.
    String countedLabel(String base, int count) =>
        count > 0 ? '$base ($count)' : base;

    return BubbleTabBar(
      controller: _tabController,
      showLabels: true,
      height: 46,
      tabs: [
        BubbleTabData(
          icon: Icons.place_outlined,
          semanticLabel: context.localizations.places,
          label:
              countedLabel(context.localizations.places, _stableSights.length),
        ),
        BubbleTabData(
          icon: Icons.note_outlined,
          semanticLabel: context.localizations.notes,
          label: countedLabel(context.localizations.notes, _stableNotes.length),
        ),
        BubbleTabData(
          icon: Icons.checklist_outlined,
          semanticLabel: context.localizations.checklists,
          label: countedLabel(
              context.localizations.checklists, _stableChecklists.length),
        ),
      ],
    );
  }

  int? _getInitialExpandedIndex(PlanDataType type) {
    final config = widget.config;
    if (config is CreateNewItineraryPlanDataComponentConfig &&
        config.planDataType == type) {
      switch (type) {
        case PlanDataType.sight:
          return _stableSights.isNotEmpty ? _stableSights.length - 1 : null;
        case PlanDataType.note:
          return _stableNotes.isNotEmpty ? _stableNotes.length - 1 : null;
        case PlanDataType.checklist:
          return _stableChecklists.isNotEmpty
              ? _stableChecklists.length - 1
              : null;
      }
    }
    if (config is UpdateItineraryPlanDataComponentConfig &&
        config.planDataType == type) {
      return config.index;
    }
    return null;
  }

  void _createNewItineraryPlanDataComponent(PlanDataType kind) {
    final tripMetadata = context.activeTrip.tripMetadata;
    switch (kind) {
      case PlanDataType.sight:
        _stableSights.add(SightFacade.newEntry(
          tripId: tripMetadata.id!,
          day: planData.day,
          defaultCurrency: tripMetadata.budget.currency,
          contributors: tripMetadata.contributors,
        ));
      case PlanDataType.note:
        _stableNotes.add(Note(''));
      case PlanDataType.checklist:
        _stableChecklists.add(CheckListFacade.newUiEntry(
          tripId: tripMetadata.id!,
          items: const [],
        ));
    }
  }
}
