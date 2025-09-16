import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';

class FloatingJumpToListNavigator extends StatefulWidget {
  const FloatingJumpToListNavigator({super.key});

  @override
  _FloatingJumpToListNavigatorState createState() =>
      _FloatingJumpToListNavigatorState();
}

class _FloatingJumpToListNavigatorState
    extends State<FloatingJumpToListNavigator> {
  bool isOpen = false;
  Offset _position = const Offset(20, 300);
  static const double _spacing = 70;
  var _numberOfButtonsAboveMain = 0;
  var _numberOfButtonsBelowMain = 0;

  @override
  Widget build(BuildContext context) {
    _numberOfButtonsAboveMain = 0;
    _numberOfButtonsBelowMain = 0;
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
                      surfaceColor.withValues(alpha: 0.8),
                      surfaceColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
          _createVerticallyPlacedTripEntityButton(
            section: NavigationSections.tripOverview,
            index: 1,
            isAbove: true,
            baseTop: _position.dy,
            left: _position.dx + 8,
            icon: Icons.info_outline_rounded,
          ),
          _createVerticallyPlacedTripEntityButton(
            section: NavigationSections.transit,
            index: 0,
            isAbove: true,
            baseTop: _position.dy,
            left: _position.dx + 8,
            icon: Icons.directions_bus_rounded,
          ),
          _createVerticallyPlacedTripEntityButton(
            section: NavigationSections.lodging,
            index: 0,
            isAbove: false,
            baseTop: _position.dy,
            left: _position.dx + 8,
            icon: Icons.hotel_rounded,
          ),
          _createVerticallyPlacedTripEntityButton(
            section: NavigationSections.itinerary,
            index: 1,
            isAbove: false,
            baseTop: _position.dy,
            left: _position.dx + 8,
            icon: Icons.date_range_rounded,
          ),
          _createHorizontalTripEntityButton(
            section: NavigationSections.budgeting,
            index: 0,
            baseLeft: _position.dx,
            top: _position.dy,
            icon: Icons.attach_money_rounded,
          ),
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: Draggable(
              feedback: FloatingActionButton(
                heroTag: 'main',
                onPressed: _toggleMenu,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isOpen
                      ? const Icon(Icons.close, key: ValueKey('close'))
                      : const Icon(Icons.navigation_rounded,
                          key: ValueKey('menu')),
                ),
              ),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                final screenSize = MediaQuery.of(context).size;
                const buttonSize = 56.0; // Main FAB size
                const miniButtonSize = 40.0; // Mini FAB size
                const padding = 16.0; // Increased padding for safety

                // Calculate required vertical space
                final requiredSpaceAbove =
                    _numberOfButtonsAboveMain * _spacing + padding;

                // The bottom space calculation needs to include the full button heights
                final requiredSpaceBelow =
                    _numberOfButtonsBelowMain * _spacing +
                        padding +
                        miniButtonSize;

                // Calculate horizontal constraints
                const minX = padding;
                final maxX = screenSize.width - buttonSize - padding;

                // Calculate vertical constraints based on required space
                final minY = requiredSpaceAbove;
                final maxY =
                    screenSize.height - buttonSize - requiredSpaceBelow;

                final newX = details.offset.dx.clamp(minX, maxX);
                final newY = details.offset.dy.clamp(minY, maxY);

                setState(() {
                  _position = Offset(newX, newY);
                });
              },
              child: FloatingActionButton(
                heroTag: 'main',
                onPressed: _toggleMenu,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isOpen
                      ? const Icon(Icons.close, key: ValueKey('close'))
                      : const Icon(Icons.navigation_rounded,
                          key: ValueKey('menu')),
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

  Widget _createVerticallyPlacedTripEntityButton({
    required String section,
    required int index,
    required bool isAbove,
    required double baseTop,
    required double left,
    required IconData icon,
  }) {
    if (isAbove) {
      _numberOfButtonsAboveMain++;
    } else {
      _numberOfButtonsBelowMain++;
    }
    final offsetY = (index + 1) * _spacing * (isAbove ? -1 : 1);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: left,
      top: isOpen ? baseTop + offsetY : baseTop,
      child: AnimatedOpacity(
        opacity: isOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          mini: true,
          heroTag: section,
          onPressed: () {
            context.addTripManagementEvent(NavigateToSection(section: section));
            _toggleMenu();
          },
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget _createHorizontalTripEntityButton({
    required String section,
    required int index,
    required double baseLeft,
    required double top,
    required IconData icon,
  }) {
    // Get screen dimensions to check available space
    final screenWidth = MediaQuery.of(context).size.width;
    const buttonSize = 40.0; // Mini FAB size

    // Calculate available space on right side
    final availableRightSpace = screenWidth - baseLeft - buttonSize;

    // Determine if there's enough space on the right
    final useRightSide = availableRightSpace >= (index + 1) * _spacing;

    // Calculate offset based on which side we're using
    final offsetX = (index + 1) * _spacing * (useRightSide ? 1 : -1);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: isOpen ? baseLeft + offsetX : baseLeft,
      top: top + 8,
      // Small vertical offset for alignment
      child: AnimatedOpacity(
        opacity: isOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          mini: true,
          heroTag: 'horizontal_$section',
          onPressed: () {
            context.addTripManagementEvent(NavigateToSection(section: section));
            _toggleMenu();
          },
          child: Icon(icon),
        ),
      ),
    );
  }
}
