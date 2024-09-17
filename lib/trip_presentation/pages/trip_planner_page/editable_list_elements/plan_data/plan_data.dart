import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/trip_data/models/check_list.dart';
import 'package:wandrr/trip_data/models/check_list_item.dart';
import 'package:wandrr/trip_data/models/note.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/widgets/geo_location_auto_complete.dart';

import 'checklists.dart';
import 'notes.dart';
import 'places.dart';

extension PlanDataValidatorExtension on UiElement<PlanDataFacade> {
  bool isValid(PlanDataFacade initialPlanData, bool isTitleRequired) {
    var currentPlanData = element;
    var isAnyNoteEmpty =
        currentPlanData.notes.any((noteFacade) => noteFacade.note.isEmpty);
    var isAnyCheckListEmpty = false;
    for (var checkList in currentPlanData.checkLists) {
      if (checkList.items.isEmpty ||
          checkList.items.any((checkListItem) => checkListItem.item.isEmpty)) {
        isAnyCheckListEmpty = true;
      }
    }
    var isTitleEmpty = currentPlanData.title?.isEmpty ?? true;

    var areNotesEqual =
        listEquals(initialPlanData.notes, currentPlanData.notes);
    var areCheckListsEqual =
        listEquals(initialPlanData.checkLists, currentPlanData.checkLists);
    var arePlacesEqual =
        listEquals(initialPlanData.places, currentPlanData.places);
    var areTitlesEqual = initialPlanData.title == currentPlanData.title;
    var areThereAnyNotesOrCheckListsOrPlaces =
        currentPlanData.notes.isNotEmpty ||
            currentPlanData.checkLists.isNotEmpty ||
            currentPlanData.places.isNotEmpty;
    return (!arePlacesEqual ||
            !areCheckListsEqual ||
            !areNotesEqual ||
            !areTitlesEqual) &&
        !isAnyNoteEmpty &&
        (isTitleRequired ? !isTitleEmpty : true) &&
        !isAnyCheckListEmpty &&
        areThereAnyNotesOrCheckListsOrPlaces;
  }
}

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
    var tripId = context.getActiveTrip().tripMetadata.id!;
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
