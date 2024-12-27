import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/check_list.dart';
import 'package:wandrr/data/trip/models/check_list_item.dart';
import 'package:wandrr/data/trip/models/note.dart';
import 'package:wandrr/data/trip/models/plan_data.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'checklists.dart';
import 'notes.dart';
import 'places.dart';

class PlanDataListItem extends StatefulWidget {
  final UiElement<PlanDataFacade> initialPlanDataUiElement;
  Function(PlanDataFacade) planDataUpdated;

  PlanDataListItem(
      {super.key,
      required this.initialPlanDataUiElement,
      required this.planDataUpdated});

  @override
  State<PlanDataListItem> createState() => _PlanDataListItemState();
}

class _PlanDataListItemState extends State<PlanDataListItem> {
  late UiElement<PlanDataFacade> _planDataUiElement;

  @override
  void initState() {
    super.initState();
    _planDataUiElement = widget.initialPlanDataUiElement.clone();
    _planDataUiElement.element =
        widget.initialPlanDataUiElement.element.clone();
  }

  @override
  Widget build(BuildContext context) {
    var tripId = context.activeTrip.tripMetadata.id!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: NotesListView(
              notes: _planDataUiElement.element.notes,
              onNotesChanged: () {
                widget.planDataUpdated(_planDataUiElement.element);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: CheckListsView(
              checkLists: _planDataUiElement.element.checkLists,
              onCheckListsChanged: () {
                widget.planDataUpdated(_planDataUiElement.element);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: PlacesListView(
              places: _planDataUiElement.element.places,
              onPlacesChanged: () {
                widget.planDataUpdated(_planDataUiElement.element);
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
        child: Icon(Icons.checklist_rounded),
        onPressed: () {
          var newCheckListEntry = CheckListFacade.newUiEntry(
              items: [CheckListItem(item: '', isChecked: false)],
              tripId: tripId);
          var isAnyCheckListEmpty = false;
          for (var checkList in _planDataUiElement.element.checkLists) {
            if (checkList.items.isEmpty ||
                checkList.items
                    .any((checkListItem) => checkListItem.item.isEmpty)) {
              isAnyCheckListEmpty = true;
            }
          }
          if (!isAnyCheckListEmpty) {
            _planDataUiElement.element.checkLists.add(newCheckListEntry);
            setState(() {});

            widget.planDataUpdated(_planDataUiElement.element);
          }
        });
  }

  Widget _buildNoteCreator(String tripId) {
    return FloatingActionButton(
      onPressed: () {
        var newNoteEntry = NoteFacade.newUiEntry(note: '', tripId: tripId);
        var isAnyNoteEmpty = _planDataUiElement.element.notes
            .any((noteFacade) => noteFacade.note.isEmpty);
        if (!isAnyNoteEmpty) {
          _planDataUiElement.element.notes.add(newNoteEntry);
          setState(() {});
          widget.planDataUpdated(_planDataUiElement.element);
        }
      },
      child: Icon(Icons.note_rounded),
    );
  }

  PlatformGeoLocationAutoComplete _buildLocationInput(String tripId) {
    return PlatformGeoLocationAutoComplete(
      initialText: '',
      onLocationSelected: (location) {
        if (!_planDataUiElement.element.places.contains(location)) {
          _planDataUiElement.element.places.add(location);
          widget.planDataUpdated(_planDataUiElement.element);
          setState(() {});
        }
      },
    );
  }
}
