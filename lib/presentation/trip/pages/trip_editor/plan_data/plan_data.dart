import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list_item.dart';
import 'package:wandrr/data/trip/models/plan_data/note.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'checklists.dart';
import 'notes.dart';
import 'places.dart';

class PlanDataListItem extends StatefulWidget {
  final PlanDataFacade planData;
  final VoidCallback planDataUpdated;

  const PlanDataListItem(
      {required this.planData, required this.planDataUpdated, super.key});

  @override
  State<PlanDataListItem> createState() => _PlanDataListItemState();
}

class _PlanDataListItemState extends State<PlanDataListItem> {
  PlanDataFacade get _planData => widget.planData;

  @override
  void didUpdateWidget(covariant PlanDataListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.planData != oldWidget.planData) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var tripId = context.activeTrip.tripMetadata.id!;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: NotesListView(
              notes: _planData.notes,
              onNotesChanged: () {
                widget.planDataUpdated();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: CheckListsView(
              checkLists: _planData.checkLists,
              onCheckListsChanged: () {
                widget.planDataUpdated();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: PlacesListView(
              places: _planData.places,
              onPlacesChanged: () {
                widget.planDataUpdated();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildLocationInput(tripId),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: _buildNoteCreator(tripId),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: _buildCheckListCreator(tripId),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckListCreator(String tripId) {
    return FloatingActionButton(
      child: const Icon(Icons.checklist_rounded),
      onPressed: () {
        var newCheckListEntry = CheckListFacade.newUiEntry(
            items: [CheckListItem(item: '', isChecked: false)], tripId: tripId);
        var isAnyCheckListEmpty = false;
        for (final checkList in _planData.checkLists) {
          if (checkList.items.isEmpty ||
              checkList.items
                  .any((checkListItem) => checkListItem.item.isEmpty)) {
            isAnyCheckListEmpty = true;
          }
        }
        if (!isAnyCheckListEmpty) {
          _planData.checkLists.add(newCheckListEntry);
          setState(() {});

          widget.planDataUpdated();
        }
      },
    );
  }

  Widget _buildNoteCreator(String tripId) {
    return FloatingActionButton(
      onPressed: () {
        var newNoteEntry = NoteFacade.newUiEntry(note: '', tripId: tripId);
        var isAnyNoteEmpty =
            _planData.notes.any((noteFacade) => noteFacade.note.isEmpty);
        if (!isAnyNoteEmpty) {
          _planData.notes.add(newNoteEntry);
          setState(() {});
          widget.planDataUpdated();
        }
      },
      child: const Icon(Icons.note_rounded),
    );
  }

  PlatformGeoLocationAutoComplete _buildLocationInput(String tripId) {
    return PlatformGeoLocationAutoComplete(
      onLocationSelected: (location) {
        if (!_planData.places.contains(location)) {
          _planData.places.add(location);
          widget.planDataUpdated();
          setState(() {});
        }
      },
    );
  }
}
