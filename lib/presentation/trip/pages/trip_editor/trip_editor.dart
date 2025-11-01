import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/creator_bottom_sheet.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/editor_bottom_sheet.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'itinerary/itinerary_navigator.dart';

class TripEditorPage extends StatelessWidget {
  const TripEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return _TripEditorPageInternal(
        body: Row(
          children: [
            Expanded(child: const ItineraryNavigator()),
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
      const ItineraryNavigator(),
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
    return BlocListener<TripManagementBloc, TripManagementState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        appBar: TripEditorAppBar(
          onTitleClicked: () {
            context.addTripManagementEvent(
                UpdateTripEntity<TripMetadataFacade>.select(
                    tripEntity: context.activeTrip.tripMetadata));
          },
        ),
        extendBody: bottomNavigationBar == null,
        floatingActionButton: _createAddButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  void _onBlocStateChanged(BuildContext context, TripManagementState state) {
    if (state is SelectedExpenseLinkedTripEntity) {
      var expenseLinkedTripEntity =
          state.tripEntityModificationData.modifiedCollectionItem;
      _showTripEntityEditorBottomSheet<ExpenseLinkedTripEntity>(
        tripEditorAction: TripEditorAction.expense,
        tripEntity: expenseLinkedTripEntity,
        pageContext: context,
      );
    } else if (state is UpdatedTripEntity &&
        state.dataState == DataState.select) {
      var tripEntity = state.tripEntityModificationData.modifiedCollectionItem;
      if (tripEntity is TransitFacade) {
        _showTripEntityEditorBottomSheet<TransitFacade>(
          tripEditorAction: TripEditorAction.travel,
          tripEntity: tripEntity,
          pageContext: context,
        );
      } else if (tripEntity is LodgingFacade) {
        _showTripEntityEditorBottomSheet<LodgingFacade>(
          tripEditorAction: TripEditorAction.stay,
          tripEntity: tripEntity,
          pageContext: context,
        );
      } else if (tripEntity is TripMetadataFacade) {
        _showTripEntityEditorBottomSheet<TripMetadataFacade>(
          tripEditorAction: TripEditorAction.tripDetails,
          tripEntity: tripEntity,
          pageContext: context,
        );
      }
    } else if (state is SelectedItineraryPlanData) {
      _showTripEntityEditorBottomSheet<ItineraryPlanData>(
          tripEditorAction: TripEditorAction.itineraryData,
          tripEntity: state.planData,
          pageContext: context,
          planDataEditorConfig: state.planDataEditorConfig);
    }
  }

  Widget _createAddButton(BuildContext pageContext) {
    var isBigLayout = pageContext.isBigLayout;
    var button = SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: FittedBox(
        child: FloatingActionButton(
          onPressed: () {
            _showModalBottomSheet(
                TripEntityCreatorBottomSheet(supportedActions: [
                  TripEditorAction.expense,
                  TripEditorAction.travel,
                  TripEditorAction.stay,
                ]),
                pageContext);
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

  void _showTripEntityEditorBottomSheet<T extends TripEntity>(
      {required T tripEntity,
      required TripEditorAction tripEditorAction,
      required BuildContext pageContext,
      ItineraryPlanDataEditorConfig? planDataEditorConfig}) {
    _showModalBottomSheet(
        TripEntityEditorBottomSheet<T>(
          tripEditorAction: tripEditorAction,
          tripEntity: tripEntity,
          planDataEditorConfig: planDataEditorConfig,
        ),
        pageContext);
  }

  void _showModalBottomSheet(Widget child, BuildContext pageContext) {
    showModalBottomSheet(
        context: pageContext,
        isScrollControlled: true,
        builder: (dialogContext) => MultiRepositoryProvider(
              providers: [
                RepositoryProvider.value(value: pageContext.appDataRepository),
                RepositoryProvider.value(value: pageContext.tripRepository),
                RepositoryProvider.value(
                    value: pageContext.apiServicesRepository),
              ],
              child: BlocProvider.value(
                value: BlocProvider.of<TripManagementBloc>(pageContext),
                child: child,
              ),
            ));
  }
}
