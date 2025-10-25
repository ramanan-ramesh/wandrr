import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/creator_bottom_sheet.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class TripEditorPage extends StatelessWidget {
  const TripEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return _TripEditorPageInternal(
        body: Row(
          children: [
            Expanded(child: Container(color: Colors.red)),
            Expanded(child: BudgetingPage()),
          ],
        ),
      );
    }
    return const _TripEditorSmallLayout();
  }
}

class _TripEditorSmallLayout extends StatefulWidget {
  const _TripEditorSmallLayout();

  @override
  State<_TripEditorSmallLayout> createState() =>
      _TripEditorSmallLayoutPageState();
}

class _TripEditorSmallLayoutPageState extends State<_TripEditorSmallLayout> {
  int _currentPageIndex = 0;
  late List<Widget> _pages = <Widget>[];

  @override
  void initState() {
    super.initState();
    _pages = [
      Container(color: Colors.green),
      BudgetingPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _TripEditorPageInternal(
      body: _pages[_currentPageIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _currentPageIndex,
        onNavBarItemTapped: (selectedPageIndex) {
          if (selectedPageIndex == _currentPageIndex) {
            return;
          }
          setState(() {
            _currentPageIndex = selectedPageIndex;
          });
        },
      ),
    );
  }
}

class _TripEditorPageInternal extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  const _TripEditorPageInternal({required this.body, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TripEditorAppBar(),
      extendBody: true,
      floatingActionButton: _createAddButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Widget _createAddButton(BuildContext pageContext) {
    var isBigLayout = pageContext.isBigLayout;
    var button = SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: FittedBox(
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                context: pageContext,
                isScrollControlled: true,
                builder: (dialogContext) => MultiRepositoryProvider(
                      providers: [
                        RepositoryProvider(
                            create: (context) => pageContext.appDataRepository),
                        RepositoryProvider(
                            create: (context) => pageContext.tripRepository),
                        RepositoryProvider(
                            create: (context) =>
                                pageContext.apiServicesRepository),
                      ],
                      child: BlocProvider(
                        create: (context) =>
                            BlocProvider.of<TripManagementBloc>(pageContext),
                        child: TripEntityCreatorBottomSheet(supportedActions: [
                          TripEditorAction.expense,
                          TripEditorAction.travel,
                          TripEditorAction.stay,
                          TripEditorAction.tripData,
                        ]),
                      ),
                    ));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
    if (isBigLayout) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: button,
      );
    }
    return button;
  }
}
