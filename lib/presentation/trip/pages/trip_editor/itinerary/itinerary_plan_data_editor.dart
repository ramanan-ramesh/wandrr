import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/blocs/trip_entity_editor/trip_entity_editor_events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/editor/checklists.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';
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
    super.key,
    required this.planData,
    required this.onPlanDataUpdated,
    required this.config,
  });

  @override
  State<ItineraryPlanDataEditor> createState() =>
      ItineraryPlanDataEditorState();
}

class ItineraryPlanDataEditorState extends State<ItineraryPlanDataEditor>
    with SingleTickerProviderStateMixin {
  static const double _kSpacingSmall = 8.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kHeaderIconSize = 26.0;

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

  ItineraryPlanData get _planData => widget.planData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = _initialTabIndex(widget.config.planDataType);
    _tabController.addListener(_onTabChanged);

    // Snapshot the plan data into stable mutable lists once.
    // _planData is already a clone so reading its getters here is safe.
    _stableSights = List<SightFacade>.from(_planData.sights);
    _stableNotes = _planData.notes.map(Note.new).toList();
    _stableChecklists = List<CheckListFacade>.from(_planData.checkLists);

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
    _planData.sights = List<SightFacade>.from(_stableSights);
    _planData.notes = _stableNotes.map((n) => n.text).toList();
    _planData.checkLists = List<CheckListFacade>.from(_stableChecklists);
  }

  /// Validates current editor state against the stable working lists.
  /// Used by the parent to keep the FAB enabled/disabled correctly.
  bool validateCurrentState() {
    final tempPlanData = ItineraryPlanData(
      tripId: _planData.tripId,
      day: _planData.day,
      id: _planData.id,
      sights: _stableSights,
      notes: _stableNotes.map((n) => n.text).toList(),
      checkLists: _stableChecklists,
    );
    return tempPlanData.validate();
  }

  List<Widget> _buildTabWidgets() => [
        ItinerarySightsEditor(
          sights: _stableSights,
          onSightsChanged: widget.onPlanDataUpdated,
          onSightTimesChanged: () {
            widget.onPlanDataUpdated();
            context.addTripEntityEditorEvent<ItineraryPlanData>(
              UpdateSightsTimeRange(List<SightFacade>.from(_stableSights)),
            );
          },
          day: _planData.day,
          initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.sight),
        ),
        ItineraryNotesEditor(
          stableNotes: _stableNotes,
          onNotesChanged: (_) => widget.onPlanDataUpdated(),
          initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.note),
        ),
        ItineraryChecklistsEditor(
          checklists: _stableChecklists,
          onChecklistsChanged: widget.onPlanDataUpdated,
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
    if (oldWidget.planData != _planData) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: _kSpacingMedium),
        _buildTabBar(),
        const SizedBox(height: _kSpacingSmall),
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

  Widget _buildHeader() {
    return EditorTheme.createSection(
      context: context,
      child: Row(
        children: [
          Icon(
            Icons.explore_rounded,
            color: context.isLightTheme ? AppColors.info : AppColors.infoLight,
            size: _kHeaderIconSize,
          ),
          const SizedBox(width: _kSpacingMedium),
          Expanded(
            child: Text(
              '${context.localizations.itinerary} - '
              '${_planData.day.day}/${_planData.day.month}/${_planData.day.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return ChromeTabBar(
      iconsAndTitles: {
        Icons.place_outlined: 'Places',
        Icons.note_outlined: 'Notes',
        Icons.checklist_outlined: 'Checklists',
      },
      tabController: _tabController,
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
          day: _planData.day,
          defaultCurrency: tripMetadata.budget.currency,
          contributors: tripMetadata.contributors,
        ));
      case PlanDataType.note:
        _stableNotes.add(Note(''));
      case PlanDataType.checklist:
        _stableChecklists.add(CheckListFacade.newUiEntry(
          tripId: tripMetadata.id!,
          items: [],
        ));
    }
  }
}
