import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/bottom_nav_bar.dart';

class TripEditorPage extends StatefulWidget {
  const TripEditorPage({super.key});

  @override
  State<TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends State<TripEditorPage> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isBigLayout = context.isBigLayout;
    return Scaffold(
      appBar: TripEditorAppBar(),
      extendBody: true,
      floatingActionButton: isBigLayout
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _createAddButton(context),
            )
          : _createAddButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: isBigLayout
          ? _createLayoutForBigScreen()
          : _createLayoutForSmallScreen(),
      bottomNavigationBar: !context.isBigLayout
          ? BottomNavBar(
              selectedIndex: _currentPageIndex,
              onNavBarItemTapped: (selectedPageIndex) {
                if (selectedPageIndex == _currentPageIndex) {
                  return;
                }
                setState(() {
                  _currentPageIndex = selectedPageIndex;
                });
              },
            )
          : null,
    );
  }

  Widget _createAddButton(BuildContext context) {
    return SizedBox(
      height: 80.0,
      width: 80.0,
      child: FittedBox(
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _createLayoutForBigScreen() {
    return Row(
      children: [
        Expanded(child: Container(color: Colors.red)),
        Expanded(child: Container(color: Colors.blue)),
      ],
    );
  }

  Widget _createLayoutForSmallScreen() {
    final List<Widget> pages = [
      Container(color: Colors.green),
      Container(color: Colors.yellow),
    ];
    return pages[_currentPageIndex];
  }
}
