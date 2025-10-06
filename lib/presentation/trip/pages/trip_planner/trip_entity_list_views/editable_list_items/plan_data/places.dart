import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';

class PlacesListView extends StatelessWidget {
  const PlacesListView(
      {required this.places, required this.onPlacesChanged, super.key});

  final List<LocationFacade> places;
  final Function() onPlacesChanged;

  @override
  Widget build(BuildContext context) {
    return _PlacesReOrderableListView(
        placesList: places, onPlacesChanged: onPlacesChanged);
  }
}

class _PlacesReOrderableListView extends StatefulWidget {
  final List<LocationFacade> placesList;
  final Function() onPlacesChanged;

  const _PlacesReOrderableListView(
      {required this.placesList, required this.onPlacesChanged});

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
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        widget.placesList.length,
        (index) {
          var place = widget.placesList.elementAt(index);
          return Row(
            key: GlobalKey(),
            children: [
              Expanded(
                child: PlatformCard(
                  child: ListTile(
                    leading: Text((index + 1).toString()),
                    title: Text(place.toString()),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded),
                onPressed: () {
                  setState(() {
                    widget.placesList.removeAt(index);
                  });
                },
              ),
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
