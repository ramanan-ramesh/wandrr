import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
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

import 'editor/notes.dart';
import 'editor/sights.dart';

class ItineraryPlanDataEditor extends StatefulWidget {
  final ItineraryPlanData planData;
  final void Function(ItineraryPlanData) onPlanDataUpdated;
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

  late final TabController _tabController;
  late ItineraryPlanData _planData;

  @override
  void initState() {
    super.initState();
    _planData = widget.planData;
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
    if (oldWidget.planData != widget.planData) {
      _planData = widget.planData;
      setState(() {});
    }
  }

  void _updatePlanData(ItineraryPlanData updated) {
    setState(() {
      _planData = updated;
    });
    widget.onPlanDataUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = MediaQuery.of(context).size.height * 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: _kSpacingMedium),
        _buildTabBar(),
        const SizedBox(height: _kSpacingSmall),
        SizedBox(
          height:
              (availableHeight - keyboardHeight).clamp(300.0, availableHeight),
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
        onSightsChanged: (List<Sight> updatedSights) {
          _updatePlanData(_planData.copyWith(sights: updatedSights));
        },
        day: _planData.day,
        initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.sight),
      );

  Widget _buildNotesTab() => ItineraryNotesEditor(
        notes: _planData.notes,
        onNotesChanged: (newNotes) {
          _updatePlanData(_planData.copyWith(
            notes: newNotes.map((e) => e.text).toList(),
          ));
        },
        initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.note),
      );

  Widget _buildCheckListsTab() => ItineraryChecklistsEditor(
        checklists: _planData.checkLists,
        onChecklistsChanged: (updatedChecklists) {
          _updatePlanData(_planData.copyWith(checkLists: updatedChecklists));
        },
        initialExpandedIndex: _getInitialExpandedIndex(PlanDataType.checklist),
      );

  int? _getInitialExpandedIndex(PlanDataType type) {
    if (widget.config is UpdateItineraryPlanDataComponentConfig &&
        widget.config.planDataType == type) {
      return (widget.config as UpdateItineraryPlanDataComponentConfig).index;
    }
    return null;
  }

  void _createNewItineraryPlanDataComponent(PlanDataType kind) {
    final tripMetadata = context.activeTrip.tripMetadata;
    switch (kind) {
      case PlanDataType.sight:
        {
          final newSight = Sight.newEntry(
            tripId: tripMetadata.id!,
            day: _planData.day,
            defaultCurrency: tripMetadata.budget.currency,
            contributors: tripMetadata.contributors,
          );
          _updatePlanData(_planData.copyWith(
            sights: [..._planData.sights, newSight],
          ));
          break;
        }
      case PlanDataType.note:
        {
          _updatePlanData(_planData.copyWith(
            notes: [..._planData.notes, ''],
          ));
          break;
        }
      case PlanDataType.checklist:
        {
          final newChecklist = CheckList.newEntry(
            tripId: tripMetadata.id!,
          );
          _updatePlanData(_planData.copyWith(
            checkLists: [..._planData.checkLists, newChecklist],
          ));
          break;
        }
    }
  }
}
