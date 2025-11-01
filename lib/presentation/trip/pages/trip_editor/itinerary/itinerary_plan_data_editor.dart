import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/note.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/editor/checklists.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';

import 'editor/notes.dart';
import 'editor/sights.dart';

class ItineraryPlanDataEditor extends StatefulWidget {
  final ItineraryPlanData planData;
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
      _ItineraryPlanDataEditorState();
}

class _ItineraryPlanDataEditorState extends State<ItineraryPlanDataEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ItineraryPlanData get _planData => widget.planData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Apply initial tab selection from config
    switch (widget.config.planDataType) {
      case PlanDataType.sight:
        _tabController.index = 0;
      case PlanDataType.note:
        _tabController.index = 1;
      case PlanDataType.checklist:
        _tabController.index = 2;
    }
    // Schedule creation/highlight after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.config is CreateNewItineraryPlanDataComponentConfig) {
        _createNewItineraryPlanDataComponent(widget.config.planDataType);
      }
      setState(() {});
    });
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
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final double tabViewHeight = MediaQuery.of(context).size.height * 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, isLightTheme),
        const SizedBox(height: 12),
        _buildTabBar(context),
        const SizedBox(height: 8),
        SizedBox(
          height: tabViewHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSightsTab(context),
              _buildNotesTab(context),
              _buildCheckListsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isLightTheme) {
    return EditorTheme.buildSection(
      context: context,
      child: Row(
        children: [
          Icon(Icons.explore_rounded,
              color:
                  context.isLightTheme ? AppColors.info : AppColors.infoLight,
              size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${context.localizations.itinerary} - ${_planData.day.day}/${_planData.day.month}/${_planData.day.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return ChromeTabBar(
      iconsAndTitles: {
        Icons.place_outlined: 'Places',
        Icons.note_outlined: 'Notes',
        Icons.checklist_outlined: 'Checklists',
      },
      tabController: _tabController,
    );
  }

  Widget _buildSightsTab(BuildContext context) {
    return ItinerarySightsEditor(
      sights: _planData.sights,
      onSightsChanged: widget.onPlanDataUpdated,
      day: _planData.day,
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    return ItineraryNotesEditor(
      notes: _planData.notes,
      onNotesChanged: widget.onPlanDataUpdated,
    );
  }

  Widget _buildCheckListsTab(BuildContext context) {
    return ItineraryChecklistsEditor(
      checklists: _planData.checkLists,
      onChecklistsChanged: widget.onPlanDataUpdated,
    );
  }

  void _createNewItineraryPlanDataComponent(PlanDataType kind) {
    var tripMetadata = context.activeTrip.tripMetadata;
    switch (kind) {
      case PlanDataType.sight:
        {
          var newSight = SightFacade.newEntry(
              tripId: tripMetadata.id!,
              day: _planData.day,
              defaultCurrency: tripMetadata.budget.currency,
              contributors: tripMetadata.contributors);
          _planData.sights.add(newSight);
          widget.onPlanDataUpdated();
          break;
        }
      case PlanDataType.note:
        {
          var newNote =
              NoteFacade.newUiEntry(tripId: tripMetadata.id!, note: '');
          _planData.notes.add(newNote);
          widget.onPlanDataUpdated();
          break;
        }
      case PlanDataType.checklist:
        {
          var newChecklist =
              CheckListFacade.newUiEntry(tripId: tripMetadata.id!, items: []);
          _planData.checkLists.add(newChecklist);
          widget.onPlanDataUpdated();
          break;
        }
    }
  }
}
