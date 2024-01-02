import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/check_list.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';

class OpenedPlanDataListItem extends StatefulWidget {
  final PlanDataUpdator initialPlanDataUpdator;
  final bool isPlanDataList;
  Function(PlanDataUpdator, bool) planDataUpdated;

  OpenedPlanDataListItem(
      {super.key,
      required this.initialPlanDataUpdator,
      required this.planDataUpdated,
      required this.isPlanDataList});

  @override
  State<OpenedPlanDataListItem> createState() => _OpenedPlanDataListItemState();
}

class _OpenedPlanDataListItemState extends State<OpenedPlanDataListItem> {
  late PlanDataUpdator _planDataUpdator;

  @override
  void initState() {
    super.initState();
    _planDataUpdator = widget.initialPlanDataUpdator.clone();
  }

  bool _canUpdatePlanData() {
    var isAnyNoteEmpty = false;
    var isAnyCheckListEmpty = false;
    var newNoteUpdators = _planDataUpdator.noteUpdators;
    if (newNoteUpdators != null) {
      if (newNoteUpdators
          .any((element) => element.note == null || element.note!.isEmpty)) {
        isAnyNoteEmpty = true;
      }
    }

    var checkListUpdators = _planDataUpdator.checkListUpdators;
    if (checkListUpdators != null) {
      if (checkListUpdators.isNotEmpty) {
        if (checkListUpdators.any((element) =>
            element.items != null &&
            element.items!.isNotEmpty &&
            element.items!.any((element) => element.item.isEmpty))) {
          isAnyCheckListEmpty = true;
        }
      }
    }

    var allInitialNoteUpdators =
        widget.initialPlanDataUpdator.noteUpdators ?? [];
    var allCurrentNoteUpdators = _planDataUpdator.noteUpdators ?? [];
    var allInitialCheckLists =
        widget.initialPlanDataUpdator.checkListUpdators ?? [];
    var allCurrentCheckLists = _planDataUpdator.checkListUpdators ?? [];
    var allInitialPlaces =
        widget.initialPlanDataUpdator.locationListUpdator?.places ?? [];
    var allCurrentPlaces = _planDataUpdator.locationListUpdator?.places ?? [];

    var areNotesEqual =
        listEquals(allInitialNoteUpdators, allCurrentNoteUpdators);
    var areCheckListsEqual =
        listEquals(allInitialCheckLists, allCurrentCheckLists);
    var arePlacesEqual = listEquals(allInitialPlaces, allCurrentPlaces);
    var areTitlesEqual = (widget.initialPlanDataUpdator.title ?? '') ==
        (_planDataUpdator.title ?? '');
    return (!arePlacesEqual ||
            !areCheckListsEqual ||
            !areNotesEqual ||
            !areTitlesEqual) &&
        !isAnyNoteEmpty &&
        !isAnyCheckListEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: _NotesListView(
              isPlanDataList: widget.isPlanDataList,
              planDataUpdator: _planDataUpdator,
              onNotesChanged: (newNotes) {
                _planDataUpdator.noteUpdators = newNotes;
                var canUpdatePlanData = _canUpdatePlanData();
                if (canUpdatePlanData) {
                  widget.planDataUpdated(_planDataUpdator, canUpdatePlanData);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: _CheckListView(
              isPlanDataList: widget.isPlanDataList,
              planDataUpdator: _planDataUpdator,
              onCheckListsChanged: (newCheckLists) {
                _planDataUpdator.checkListUpdators = newCheckLists;
                var canUpdatePlanData = _canUpdatePlanData();
                if (canUpdatePlanData) {
                  widget.planDataUpdated(_planDataUpdator, canUpdatePlanData);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: _PlacesListView(
              isPlanDataList: widget.isPlanDataList,
              planDataUpdator: _planDataUpdator,
              onPlacesChanged: (newPlaces) {
                _planDataUpdator.locationListUpdator =
                    LocationListUpdator.fromLocationList(
                        places: List.from(newPlaces),
                        planDataId: _planDataUpdator.id,
                        tripId: _planDataUpdator.tripId);
                var canUpdatePlanData = _canUpdatePlanData();
                if (canUpdatePlanData) {
                  widget.planDataUpdated(_planDataUpdator, canUpdatePlanData);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildLocationInput(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: _buildNoteCreator(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: _buildCheckListCreator(context),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckListCreator(BuildContext context) {
    return PlatformButtonElements.createFAB(
      icon: Icons.checklist_rounded,
      context: context,
      callback: () {
        var newCheckListEntry = CheckListUpdator.createNewUIEntry(
            tripId: _planDataUpdator.tripId, planDataId: _planDataUpdator.id);
        newCheckListEntry.items = [CheckListItem(item: '', isChecked: false)];
        var shouldAddCheckList = false;
        if (_planDataUpdator.checkListUpdators != null) {
          if (!_planDataUpdator.checkListUpdators!.any((element) =>
              element.items != null || element.items!.isNotEmpty)) {
            _planDataUpdator.checkListUpdators!.add(newCheckListEntry);
            shouldAddCheckList = true;
          }
        } else {
          _planDataUpdator.checkListUpdators = [newCheckListEntry];
          shouldAddCheckList = true;
        }
        if (shouldAddCheckList) {
          setState(() {});

          widget.planDataUpdated(_planDataUpdator, false);
        }
      },
    );
  }

  Widget _buildNoteCreator(BuildContext context) {
    return PlatformButtonElements.createFAB(
      icon: Icons.note_rounded,
      context: context,
      callback: () {
        var newNoteEntry = NoteUpdator.createNewUIEntry(
            tripId: _planDataUpdator.tripId, planDataId: _planDataUpdator.id);
        var shouldAddNote = false;
        if (_planDataUpdator.noteUpdators != null) {
          if (!_planDataUpdator.noteUpdators!.any(
              (element) => element.note == null || element.note!.isEmpty)) {
            shouldAddNote = true;
            _planDataUpdator.noteUpdators!.add(newNoteEntry);
          }
        } else {
          shouldAddNote = true;
          _planDataUpdator.noteUpdators = [newNoteEntry];
        }
        if (shouldAddNote) {
          setState(() {});
          widget.planDataUpdated(_planDataUpdator, false);
        }
      },
    );
  }

  PlatformGeoLocationAutoComplete _buildLocationInput() {
    return PlatformGeoLocationAutoComplete(
      initialText: '',
      onLocationSelected: (location) {
        var shouldAddPlace = false;
        if (_planDataUpdator.locationListUpdator != null) {
          if (_planDataUpdator.locationListUpdator!.places != null &&
              !_planDataUpdator.locationListUpdator!.places!
                  .contains(location)) {
            _planDataUpdator.locationListUpdator!.places!.add(location);
            shouldAddPlace = true;
          } else {
            _planDataUpdator.locationListUpdator!.places = [location];
            shouldAddPlace = true;
          }
        } else {
          _planDataUpdator.locationListUpdator =
              LocationListUpdator.fromLocationList(
                  places: [location],
                  planDataId: _planDataUpdator.id,
                  tripId: _planDataUpdator.tripId);
          shouldAddPlace = true;
        }
        if (shouldAddPlace) {
          setState(() {});
          widget.planDataUpdated(_planDataUpdator, _canUpdatePlanData());
        }
      },
    );
  }
}

class _NotesListView extends StatefulWidget {
  _NotesListView(
      {super.key,
      required PlanDataUpdator planDataUpdator,
      required this.isPlanDataList,
      required this.onNotesChanged})
      : noteUpdators = planDataUpdator.noteUpdators ?? [];

  final List<NoteUpdator> noteUpdators;
  final Function(List<NoteUpdator>) onNotesChanged;
  final bool isPlanDataList;

  @override
  State<_NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<_NotesListView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return ListView.separated(
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            var noteUpdator = widget.noteUpdators.elementAt(index);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NoteListItem(
                    noteUpdator: noteUpdator,
                    onNoteChanged: (newNote) {
                      noteUpdator.note = newNote;
                      widget.onNotesChanged(widget.noteUpdators);
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: _HoverableDeleteButton(
                    callBack: () {
                      setState(() {
                        widget.noteUpdators.remove(noteUpdator);
                      });
                      widget.onNotesChanged(widget.noteUpdators);
                    },
                  ),
                ),
              ],
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return Padding(padding: EdgeInsets.symmetric(vertical: 5.0));
          },
          itemCount: widget.noteUpdators.length,
        );
      },
      buildWhen: (previous, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        }
        if (currentState is PlanDataUpdated) {
          if (currentState.operation == DataState.Created) {
            return true;
          } else if (currentState.operation == DataState.Deleted) {
            return true;
          } else if (currentState.operation == DataState.Updated) {
            if (!listEquals(currentState.planDataUpdator.noteUpdators ?? [],
                widget.noteUpdators)) {
              return true;
            }
          }
        }
        return false;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}

class _HoverableDeleteButton extends StatefulWidget {
  VoidCallback callBack;

  _HoverableDeleteButton({super.key, required this.callBack});

  @override
  State<_HoverableDeleteButton> createState() => _HoverableDeleteButtonState();
}

class _HoverableDeleteButtonState extends State<_HoverableDeleteButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: InkWell(
        onTap: null,
        splashFactory: NoSplash.splashFactory,
        child: IconButton(
          icon: Icon(Icons.delete_rounded),
          color: _isHovered ? Colors.black : Colors.white,
          onPressed: () {
            widget.callBack();
          },
        ),
      ),
    );
  }
}

class _NoteListItem extends StatefulWidget {
  final NoteUpdator noteUpdator;
  Function(String) onNoteChanged;

  _NoteListItem(
      {super.key, required this.noteUpdator, required this.onNoteChanged});

  @override
  State<_NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends State<_NoteListItem> {
  late NoteUpdator _noteUpdator;
  late TextEditingController _noteEditingController;

  @override
  void initState() {
    super.initState();
    _noteEditingController =
        TextEditingController(text: widget.noteUpdator.note);
    _noteUpdator = widget.noteUpdator.clone();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: PlatformTextField(
            controller: _noteEditingController,
            onTextChanged: (newValue) {
              if (newValue != widget.noteUpdator.note) {
                setState(() {
                  _noteUpdator.note = newValue;
                });
                widget.onNoteChanged(newValue);
              }
            },
          ),
        ),
        AnimatedOpacity(
          opacity: _noteUpdator.note != widget.noteUpdator.note ? 1.0 : 0.0,
          duration: Duration(seconds: 1),
          child: Align(
            alignment: Alignment.bottomRight,
            child: PlatformButtonElements.createFAB(
                icon: Icons.check_rounded, context: context),
          ),
        )
      ],
    );
  }
}

class _CheckListView extends StatelessWidget {
  _CheckListView(
      {super.key,
      required PlanDataUpdator planDataUpdator,
      required this.isPlanDataList,
      required this.onCheckListsChanged})
      : _checkListUpdators = planDataUpdator.checkListUpdators ?? [];

  final List<CheckListUpdator> _checkListUpdators;
  final Function(List<CheckListUpdator>) onCheckListsChanged;
  final bool isPlanDataList;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previous, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        }
        if (currentState is PlanDataUpdated) {
          if (currentState.operation == DataState.Created) {
            return true;
          } else if (currentState.operation == DataState.Deleted) {
            return true;
          } else if (currentState.operation == DataState.Updated) {
            if (!listEquals(
                currentState.planDataUpdator.checkListUpdators ?? [],
                _checkListUpdators)) {
              return true;
            }
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        return ListView.separated(
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            var checkList = _checkListUpdators.elementAt(index);
            return _CheckList(
              checkListUpdator: checkList,
              checkListChanged: (newCheckList) {
                checkList = newCheckList;
                onCheckListsChanged(_checkListUpdators);
              },
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
          },
          itemCount: _checkListUpdators.length,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}

class _CheckList extends StatelessWidget {
  Function(CheckListUpdator) checkListChanged;
  final CheckListUpdator _checkListUpdator;
  final TextEditingController _titleEditingController;

  _CheckList(
      {super.key,
      required CheckListUpdator checkListUpdator,
      required this.checkListChanged})
      : _checkListUpdator = checkListUpdator.clone(),
        _titleEditingController =
            TextEditingController(text: checkListUpdator.title);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          PlatformTextElements.createTextField(
            context: context,
            controller: _titleEditingController,
            border: InputBorder.none,
            onTextChanged: (newValue) {
              if (newValue != _checkListUpdator.title) {
                _checkListUpdator.title = newValue;
                checkListChanged(_checkListUpdator);
              }
            },
          ),
          _ReOrderableCheckListItems(
            checkListUpdator: _checkListUpdator,
            checkListItemsChanged: (List<CheckListItem> newCheckListItems) {
              if (!listEquals(_checkListUpdator.items, newCheckListItems)) {
                _checkListUpdator.items = newCheckListItems;
                checkListChanged(_checkListUpdator);
              }
            },
          )
        ],
      ),
    );
  }
}

class _ReOrderableCheckListItems extends StatefulWidget {
  CheckListUpdator checkListUpdator;
  Function(List<CheckListItem>) checkListItemsChanged;

  _ReOrderableCheckListItems(
      {super.key,
      required this.checkListUpdator,
      required this.checkListItemsChanged});

  @override
  State<_ReOrderableCheckListItems> createState() =>
      _ReOrderableCheckListItemsState();
}

class _ReOrderableCheckListItemsState
    extends State<_ReOrderableCheckListItems> {
  late List<CheckListItem> _checkListItems;

  @override
  void initState() {
    super.initState();
    _checkListItems = widget.checkListUpdator.items
            ?.map((e) => CheckListItem(item: e.item, isChecked: e.isChecked))
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      onReorder: _onReorder,
      children: List.generate(
        _checkListItems.length,
        (index) {
          var checkListItem = _checkListItems.elementAt(index);
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            key: GlobalKey(),
            children: [
              Expanded(
                child: _CheckListItem(
                    key: GlobalKey(),
                    checkListItem: checkListItem,
                    callback: (checkListItem) {
                      _checkListItems[index] = checkListItem;
                      widget.checkListItemsChanged(_checkListItems);
                    }),
              ),
              _HoverableDeleteButton(callBack: () {
                setState(() {
                  _checkListItems.remove(checkListItem);
                });
                widget.checkListItemsChanged(_checkListItems);
              })
            ],
          );
        },
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _checkListItems.removeAt(oldIndex);
      _checkListItems.insert(newIndex, item);
    });
    widget.checkListItemsChanged(_checkListItems);
  }
}

class _CheckListItem extends StatefulWidget {
  final CheckListItem checkListItem;
  Function(CheckListItem) callback;

  _CheckListItem(
      {super.key, required this.checkListItem, required this.callback});

  @override
  State<_CheckListItem> createState() => _CheckListItemState();
}

class _CheckListItemState extends State<_CheckListItem> {
  late TextEditingController _itemEditingController;
  late CheckListItem _checkListItem;

  @override
  void initState() {
    super.initState();
    _checkListItem = CheckListItem(
        item: widget.checkListItem.item,
        isChecked: widget.checkListItem.isChecked);
    _itemEditingController = TextEditingController(text: _checkListItem.item);
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: PlatformTextField(
        controller: _itemEditingController,
        onTextChanged: (newValue) {
          if (newValue != _checkListItem.item) {
            _checkListItem.item = newValue;
            widget.callback(_checkListItem);
          }
        },
      ),
      value: _checkListItem.isChecked,
      onChanged: (value) {
        setState(() {
          _checkListItem.isChecked = !_checkListItem.isChecked;
          widget.callback(_checkListItem);
        });
      },
    );
  }
}

class _PlacesListView extends StatelessWidget {
  _PlacesListView(
      {super.key,
      required this.planDataUpdator,
      required this.onPlacesChanged,
      required this.isPlanDataList})
      : _locationListUpdator = planDataUpdator.locationListUpdator;

  final PlanDataUpdator planDataUpdator;
  final LocationListUpdator? _locationListUpdator;
  final Function(List<LocationFacade>) onPlacesChanged;
  final bool isPlanDataList;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        } else if (currentState is PlanDataUpdated) {
          if (currentState.planDataUpdator.tripId == planDataUpdator.tripId &&
              currentState.planDataUpdator.id == planDataUpdator.id) {
            return true;
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        return _PlacesReOrderableListView(
            placesList: _locationListUpdator?.places ?? [],
            onPlacesChanged: (newPlaces) {
              _locationListUpdator!.places = newPlaces;
              onPlacesChanged(newPlaces);
            });
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}

class _PlacesReOrderableListView extends StatefulWidget {
  final List<LocationFacade> placesList;
  Function(List<LocationFacade>) onPlacesChanged;

  _PlacesReOrderableListView(
      {super.key, required this.placesList, required this.onPlacesChanged});

  @override
  State<_PlacesReOrderableListView> createState() =>
      _PlacesReOrderableListViewState();
}

class _PlacesReOrderableListViewState
    extends State<_PlacesReOrderableListView> {
  late List<LocationFacade> _places;

  @override
  void initState() {
    super.initState();
    _places = List.from(widget.placesList);
  }

  @override
  Widget build(BuildContext context) {
    _places = List.from(widget.placesList);
    return ReorderableListView(
      shrinkWrap: true,
      onReorder: _onReorder,
      children: List.generate(
        _places.length,
        (index) {
          var place = _places.elementAt(index);
          return Row(
            key: GlobalKey(),
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Text((index + 1).toString()),
                    title: Text(place.toString()),
                  ),
                ),
              ),
              _HoverableDeleteButton(
                callBack: () {
                  setState(() {
                    _places.remove(place);
                  });
                  widget.onPlacesChanged(_places);
                },
              )
            ],
          );
        },
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _places.removeAt(oldIndex);
      _places.insert(newIndex, item);
    });
    widget.onPlacesChanged(_places);
  }
}
