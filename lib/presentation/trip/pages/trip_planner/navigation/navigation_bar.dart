import 'package:flutter/material.dart';

class TripNavigationBar extends StatelessWidget {
  const TripNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _createNavigationIcon(Icons.info_outline_rounded),
        _createNavigationIcon(Icons.directions_bus_rounded),
        _createNavigationIcon(Icons.hotel_rounded),
        _createNavigationIcon(Icons.date_range_rounded),
      ],
    );
  }

  Widget _createNavigationIcon(IconData icon) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0, bottom: 8.0),
      child: CircleAvatar(
          foregroundColor: Colors.black,
          backgroundColor: Colors.green,
          child: Icon(icon)),
    );
  }
}
