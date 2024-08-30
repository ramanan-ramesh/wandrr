import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Sidebar extends StatefulWidget {
  Sidebar({Key? key}) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  static const double _drawerWidth = 200;
  final _dateFormat = DateFormat.yMMMMd();

  final List<_MainSidebarItem> _mainSidebarItems = [];

  late ValueNotifier<(_MainSidebarItem, _ChildSidebarItem?)> _selectionNotifier;

  var _isOpen = true;

  @override
  Widget build(BuildContext context) {
    if (_mainSidebarItems.isEmpty) {
      _initializeItems(context);
    }

    return AnimatedSize(
        duration: const Duration(milliseconds: 500),
        curve: Curves.linearToEaseOut,
        child: SizedBox(
          width: _isOpen
              ? _drawerWidth
              : 60, //TODO: Or we should change this 60 value also?
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _mainSidebarItems.length,
                  itemBuilder: _buildMainListItem,
                ),
              ),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: FloatingActionButton(
                      backgroundColor: Colors.black,
                      onPressed: () {
                        setState(() {
                          _isOpen = !_isOpen;
                        });
                      },
                      child: Icon(
                        _isOpen ? Icons.close : Icons.menu_open_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ))
            ],
          ),
        ));
    return AnimatedContainer(
      decoration: BoxDecoration(
        border: Border.symmetric(
            vertical: BorderSide(color: Colors.white, width: 0.5)),
      ),
      curve: Curves.linearToEaseOut,
      duration: const Duration(milliseconds: 500),
      width: _isOpen ? _drawerWidth : 60,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _mainSidebarItems.length,
              itemBuilder: _buildMainListItem,
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.black,
                  onPressed: () {
                    setState(() {
                      _isOpen = !_isOpen;
                    });
                  },
                  child: Icon(
                    _isOpen ? Icons.close : Icons.menu_open_rounded,
                    color: Colors.white,
                  ),
                ),
              ))
        ],
      ),
    );
  }

  void _initializeItems(BuildContext context) {
    // var activeTrip = RepositoryProvider.of<TripManagement>(context).activeTrip!;
    // var appLocalizations = AppLocalizations.of(context)!;
    // //Overview
    // var overviewChildSidebarItems = <_ChildSidebarItem>[];
    // overviewChildSidebarItems
    //     .add(_ChildSidebarItem(' \u2022 ', appLocalizations.transit));
    // overviewChildSidebarItems
    //     .add(_ChildSidebarItem(' \u2022 ', appLocalizations.hotelsAndLodging));
    // overviewChildSidebarItems
    //     .add(_ChildSidebarItem(' \u2022 ', appLocalizations.itinerary));
    // var overviewMainSidebarItem = _MainSidebarItem(Icons.anchor_rounded,
    //     appLocalizations.overview, overviewChildSidebarItems);
    // _mainSidebarItems.add(overviewMainSidebarItem);
    // //Itinerary
    // var itineraryChildSidebarItems = <_ChildSidebarItem>[];
    // for (var itinerary in activeTrip.itineraries) {
    //   var month = DateFormat.MMM().format(itinerary.day).toUpperCase();
    //   var closeValue = '$month\n${itinerary.day.day.toString()}';
    //   itineraryChildSidebarItems.add(
    //       _ChildSidebarItem(closeValue, _dateFormat.format(itinerary.day)));
    // }
    // var itineraryMainSidebarItem = _MainSidebarItem(Icons.date_range,
    //     appLocalizations.itinerary, itineraryChildSidebarItems);
    // _mainSidebarItems.add(itineraryMainSidebarItem);
    // //Budget
    // var budgetSidebarItems = <_ChildSidebarItem>[
    //   _ChildSidebarItem(appLocalizations.view, appLocalizations.view)
    // ];
    // var budgetMainSidebarItem = _MainSidebarItem(Icons.attach_money_rounded,
    //     appLocalizations.budget, budgetSidebarItems);
    // _mainSidebarItems.add(budgetMainSidebarItem);
    // //Select a default side bar item
    // _selectionNotifier = new ValueNotifier((_mainSidebarItems.first, null));
  }

  Widget _buildMainListItem(BuildContext context, int index) {
    var sidebarItem = _mainSidebarItems[index];
    if (_isOpen) {
      return _OpenedSidebarMainItem(
          selectionNotifier: _selectionNotifier, mainEntry: sidebarItem);
    } else {
      return _ClosedSidebarMainItem(
          selectionNotifier: _selectionNotifier, mainEntry: sidebarItem);
    }
  }
}

class _MainSidebarItem {
  final IconData close;
  final String open;
  List<_ChildSidebarItem> childSidebarItems;

  _MainSidebarItem(this.close, this.open, this.childSidebarItems);

  @override
  bool operator ==(Object other) {
    if (other is! _MainSidebarItem) {
      return false;
    }
    return this.close == close &&
        this.open == other.open &&
        ListEquality().equals(childSidebarItems, other.childSidebarItems);
  }
}

class _ChildSidebarItem {
  final String close;
  final String open;

  _ChildSidebarItem(this.close, this.open);
}

class _OpenedSidebarMainItem extends StatelessWidget {
  final ValueNotifier<(_MainSidebarItem, _ChildSidebarItem?)> selectionNotifier;

  final _MainSidebarItem mainEntry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectionNotifier,
      builder: (BuildContext context,
          (_MainSidebarItem, _ChildSidebarItem?) value, Widget? child) {
        var currentSelection = selectionNotifier.value;
        var isMainEntrySelected = currentSelection.$1 == mainEntry;
        return Column(
          children: [
            _buildMainListTile(),
            if (isMainEntrySelected)
              Padding(
                padding: EdgeInsets.only(left: 5, top: 2),
                child: _buildChildEntries(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMainListTile() {
    var currentSelection = selectionNotifier.value;
    var isMainEntrySelected = currentSelection.$1 == mainEntry;
    return Material(
      clipBehavior: Clip.hardEdge,
      color: isMainEntrySelected ? Colors.black : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: ListTile(
        onTap: () {
          if (!isMainEntrySelected) {
            selectionNotifier.value = (mainEntry, null);
          }
        },
        leading: isMainEntrySelected
            ? Icon(
                Icons.arrow_circle_down,
                color: Colors.white,
              )
            : Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.black,
              ),
        title: Text(
          mainEntry.open,
          style: TextStyle(
              color: Colors.white,
              fontWeight: isMainEntrySelected ? FontWeight.bold : null),
        ),
      ),
    );
  }

  Widget _buildChildEntries() {
    return Column(
      children: mainEntry.childSidebarItems
          .map((childEntry) => _buildChildEntry(childEntry))
          .toList(),
    );
  }

  Widget _buildChildEntry(_ChildSidebarItem childSidebarItem) {
    return ValueListenableBuilder(
      valueListenable: selectionNotifier,
      builder: (BuildContext context,
          (_MainSidebarItem, _ChildSidebarItem?) value, Widget? child) {
        var isSelected = value.$2 == childSidebarItem;
        return GestureDetector(
          onTap: () {
            if (!isSelected) {
              selectionNotifier.value = (mainEntry, childSidebarItem);
            }
          },
          child: Material(
            color: isSelected ? Colors.black12 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Tab(
              text: childSidebarItem.open,
            ),
          ),
        );
      },
    );
  }

  _OpenedSidebarMainItem(
      {super.key, required this.mainEntry, required this.selectionNotifier});
}

class _ClosedSidebarMainItem extends StatelessWidget {
  final ValueNotifier<(_MainSidebarItem, _ChildSidebarItem?)> selectionNotifier;

  final _MainSidebarItem mainEntry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectionNotifier,
      builder: (BuildContext context,
          (_MainSidebarItem, _ChildSidebarItem?) value, Widget? child) {
        return Column(
          children: [_buildMainListTile(), _buildChildEntries()],
        );
      },
    );
  }

  Widget _buildMainListTile() {
    var currentSelection = selectionNotifier.value;
    var isMainEntrySelected = currentSelection.$1 == mainEntry;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: FloatingActionButton(
        backgroundColor: isMainEntrySelected ? Colors.black : Colors.white24,
        onPressed: () {
          if (!isMainEntrySelected) {
            selectionNotifier.value = (mainEntry, null);
          }
        },
        child: Icon(
          mainEntry.close,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChildEntries() {
    return Column(
      children: mainEntry.childSidebarItems
          .map((childEntry) => _buildChildEntry(childEntry))
          .toList(),
    );
  }

  Widget _buildChildEntry(_ChildSidebarItem childSidebarItem) {
    return ValueListenableBuilder(
      valueListenable: selectionNotifier,
      builder: (BuildContext context,
          (_MainSidebarItem, _ChildSidebarItem?) value, Widget? child) {
        var isSelected = value.$2 == childSidebarItem;
        return TextButton(
          onPressed: () {
            if (!isSelected) {
              selectionNotifier.value = (mainEntry, childSidebarItem);
            }
          },
          child: Text(
            childSidebarItem.close,
            style: TextStyle(color: isSelected ? Colors.black : Colors.white24),
          ),
        );
      },
    );
  }

  _ClosedSidebarMainItem(
      {super.key, required this.mainEntry, required this.selectionNotifier});
}
