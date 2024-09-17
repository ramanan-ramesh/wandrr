import 'package:flutter/material.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/trip_data/models/location.dart';

class PlacesListView extends StatelessWidget {
  PlacesListView(
      {super.key, required this.places, required this.onPlacesChanged});

  final List<LocationFacade> places;
  final Function() onPlacesChanged;

  @override
  Widget build(BuildContext context) {
    return _PlacesReOrderableListView(
        placesList: places,
        onPlacesChanged: () {
          onPlacesChanged();
        });
  }
}

class _PlacesReOrderableListView extends StatefulWidget {
  final List<LocationFacade> placesList;
  Function() onPlacesChanged;

  _PlacesReOrderableListView(
      {super.key, required this.placesList, required this.onPlacesChanged});

  @override
  State<_PlacesReOrderableListView> createState() =>
      _PlacesReOrderableListViewState();
}

class _PlacesReOrderableListViewState
    extends State<_PlacesReOrderableListView> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      onReorder: _onReorder,
      children: List.generate(
        widget.placesList.length,
        (index) {
          var place = widget.placesList.elementAt(index);
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
              HoverableDeleteButton(
                callBack: () {
                  setState(() {
                    widget.placesList.removeAt(index);
                  });
                  widget.onPlacesChanged();
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
      final item = widget.placesList.removeAt(oldIndex);
      widget.placesList.insert(newIndex, item);
    });
    widget.onPlacesChanged();
  }
}
