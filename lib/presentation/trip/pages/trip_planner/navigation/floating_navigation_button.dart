import 'package:flutter/material.dart';

class FloatingTripNavigationButton extends StatefulWidget {
  @override
  _FloatingTripNavigationButtonState createState() =>
      _FloatingTripNavigationButtonState();
}

class _FloatingTripNavigationButtonState
    extends State<FloatingTripNavigationButton> {
  bool isOpen = false;
  Offset position = Offset(20, 300);
  static const double _spacing = 70;

  @override
  Widget build(BuildContext context) {
    var surfaceColor = Theme.of(context).colorScheme.surface;
    return GestureDetector(
      onTap: () {
        if (isOpen) {
          setState(() => isOpen = false);
        }
      },
      child: Stack(
        children: [
          if (isOpen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      surfaceColor.withOpacity(0.8), // Start color
                      surfaceColor.withOpacity(0.4), // End color
                    ],
                  ),
                ),
              ),
            ),

          // Trip entity buttons above close button
          _createTripEntityButton(
              tag: 'info',
              index: 1,
              isAbove: true,
              baseTop: position.dy,
              left: position.dx + 8,
              icon: Icons.info_outline_rounded),
          _createTripEntityButton(
            tag: 'transit',
            index: 0,
            isAbove: true,
            baseTop: position.dy,
            left: position.dx + 8,
            icon: Icons.directions_bus_rounded,
          ),

          // Trip entity buttons below close button
          _createTripEntityButton(
            tag: 'lodging',
            index: 0,
            isAbove: false,
            baseTop: position.dy,
            left: position.dx + 8,
            icon: Icons.hotel_rounded,
          ),
          _createTripEntityButton(
            tag: 'itinerary',
            index: 1,
            isAbove: false,
            baseTop: position.dy,
            left: position.dx + 8,
            icon: Icons.date_range_rounded,
          ),

          _createAlignedTripEntityButton(
            tag: 'aligned',
            baseTop: position.dy,
            baseLeft: position.dx,
            icon: Icons.map_rounded,
          ),

          // Main menu/close button
          Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              onPanUpdate: _updateMenuButtonPosition,
              child: FloatingActionButton(
                heroTag: 'main',
                onPressed: _toggleMenu,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: isOpen
                      ? Icon(Icons.close, key: ValueKey('close'))
                      : Icon(Icons.menu, key: ValueKey('menu')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMenu() {
    setState(() => isOpen = !isOpen);
  }

  void _updateMenuButtonPosition(DragUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;
    const buttonSize = 56.0;
    const spacing = 70.0;
    const padding = 8.0;

    const minX = padding;
    final maxX = screenSize.width - buttonSize - padding;

    const minY = 2 * spacing + padding;
    final maxY = screenSize.height - buttonSize - 2 * spacing - padding;

    final newX = (position.dx + details.delta.dx).clamp(minX, maxX);
    final newY = (position.dy + details.delta.dy).clamp(minY, maxY);

    setState(() {
      position = Offset(newX, newY);
    });
  }

  Widget _createTripEntityButton({
    required String tag,
    required int index,
    required bool isAbove,
    required double baseTop,
    required double left,
    required IconData icon,
  }) {
    final offsetY = (index + 1) * _spacing * (isAbove ? -1 : 1);

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: left,
      top: isOpen ? baseTop + offsetY : baseTop,
      child: AnimatedOpacity(
        opacity: isOpen ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: FloatingActionButton(
          mini: true,
          heroTag: tag,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pressed $tag')),
            );
            _toggleMenu();
          },
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget _createAlignedTripEntityButton({
    required String tag,
    required double baseTop,
    required double baseLeft,
    required IconData icon,
  }) {
    final screenSize = MediaQuery.of(context).size;
    const buttonSize = 56.0;
    const spacing = 70.0;
    const padding = 8.0;

    final hasSpaceOnRight =
        baseLeft + buttonSize + spacing + padding < screenSize.width;
    final offsetX = hasSpaceOnRight ? spacing : -spacing;

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: isOpen ? baseLeft + offsetX : baseLeft,
      top: baseTop,
      child: AnimatedOpacity(
        opacity: isOpen ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: FloatingActionButton(
          mini: true,
          heroTag: tag,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pressed $tag')),
            );
            _toggleMenu();
          },
          child: Icon(icon),
        ),
      ),
    );
  }
}
