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
  // Reused layout constants
  static const double _kSpacingSmall = 8.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kHeaderIconSize = 26.0;
  static const double _kTabViewHeightFactor = 0.6; // portion of screen height

  late final TabController _tabController;

  ItineraryPlanData get _planData => widget.planData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = _initialTabIndex(widget.config.planDataType);

    // Schedule creation/highlight after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.config is CreateNewItineraryPlanDataComponentConfig) {
        _createNewItineraryPlanDataComponent(widget.config.planDataType);
      }
      setState(() {});
    });
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
    final double tabViewHeight =
        MediaQuery.of(context).size.height * _kTabViewHeightFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: _kSpacingMedium),
        _buildTabBar(),
        const SizedBox(height: _kSpacingSmall),
        SizedBox(
          height: tabViewHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSightsTab(),
              _buildNotesTab(),
              _buildCheckListsTab(),
            ],
          ),
        ),
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

  Widget _buildSightsTab() => ItinerarySightsEditor(
        sights: _planData.sights,
        onSightsChanged: widget.onPlanDataUpdated,
        day: _planData.day,
      );

  Widget _buildNotesTab() => ItineraryNotesEditor(
        notes: _planData.notes,
        onNotesChanged: widget.onPlanDataUpdated,
      );

  Widget _buildCheckListsTab() => ItineraryChecklistsEditor(
        checklists: _planData.checkLists,
        onChecklistsChanged: widget.onPlanDataUpdated,
      );

  void _createNewItineraryPlanDataComponent(PlanDataType kind) {
    final tripMetadata = context.activeTrip.tripMetadata;
    switch (kind) {
      case PlanDataType.sight:
        {
          _planData.sights.add(
            SightFacade.newEntry(
              tripId: tripMetadata.id!,
              day: _planData.day,
              defaultCurrency: tripMetadata.budget.currency,
              contributors: tripMetadata.contributors,
            ),
          );
          break;
        }
      case PlanDataType.note:
        {
          _planData.notes.add(
            NoteFacade.newUiEntry(
              tripId: tripMetadata.id!,
              note: '',
            ),
          );
          break;
        }
      case PlanDataType.checklist:
        {
          _planData.checkLists.add(
            CheckListFacade.newUiEntry(
              tripId: tripMetadata.id!,
              items: [],
            ),
          );
          break;
        }
    }
    widget.onPlanDataUpdated();
  }
}
