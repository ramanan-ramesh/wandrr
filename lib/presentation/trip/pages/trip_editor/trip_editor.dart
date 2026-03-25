import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/creator_bottom_sheet.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/editor_bottom_sheet.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/app_bar/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'itinerary/itinerary_navigator.dart';

/// Main entry point for the trip editor page.
class TripEditorPage extends StatefulWidget {
  const TripEditorPage({super.key});

  @override
  State<TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends State<TripEditorPage> {
  final ValueNotifier<DateTime> _currentDateNotifier =
      ValueNotifier<DateTime>(DateTime.now());

  @override
  void dispose() {
    _currentDateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return _TripEditorPageInternal(
        currentDateNotifier: _currentDateNotifier,
        body: Row(
          children: [
            Expanded(
                child: ItineraryNavigator(
                    onNavigatedToDate: (date) =>
                        _currentDateNotifier.value = date)),
            const Expanded(child: BudgetingPage()),
          ],
        ),
      );
    }
    return _TripEditorSmallLayout(currentDateNotifier: _currentDateNotifier);
  }
}

class _TripEditorSmallLayout extends StatefulWidget {
  final ValueNotifier<DateTime> currentDateNotifier;

  const _TripEditorSmallLayout({required this.currentDateNotifier});

  @override
  State<_TripEditorSmallLayout> createState() =>
      _TripEditorSmallLayoutPageState();
}

class _TripEditorSmallLayoutPageState extends State<_TripEditorSmallLayout> {
  int _currentPageIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ItineraryNavigator(onNavigatedToDate: (date) {
        widget.currentDateNotifier.value = date;
      }),
      const BudgetingPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _TripEditorPageInternal(
      currentDateNotifier: widget.currentDateNotifier,
      body: _pages[_currentPageIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _currentPageIndex,
        onNavBarItemTapped: (selectedPageIndex) {
          if (selectedPageIndex == _currentPageIndex) return;
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
  final ValueNotifier<DateTime> currentDateNotifier;

  const _TripEditorPageInternal({
    required this.body,
    required this.currentDateNotifier,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripManagementBloc, TripManagementState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        appBar: const TripEditorAppBar(),
        extendBody: bottomNavigationBar == null,
        floatingActionButton: _createAddButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Column(
          children: [
            StreamBuilder<bool>(
              stream: context.tripRepository.activeTrip!.isFullyLoaded,
              initialData:
                  context.tripRepository.activeTrip!.isFullyLoadedValue,
              builder: (context, snapshot) {
                final isLoaded = snapshot.data ?? false;
                if (isLoaded) return const SizedBox.shrink();
                return const LinearProgressIndicator();
              },
            ),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  void _onBlocStateChanged(BuildContext context, TripManagementState state) {
    if (state is SelectedExpenseBearingTripEntity) {
      final expenseBearingTripEntity =
          state.tripEntityModificationData.modifiedCollectionItem;
      _showTripEntityEditorBottomSheet<ExpenseBearingTripEntity>(
        tripEditorAction: TripEditorAction.expense,
        tripEntity: expenseBearingTripEntity,
        pageContext: context,
      );
    } else if (state is UpdatedTripEntity &&
        state.dataState == DataState.update) {
      final modifiedItem =
          state.tripEntityModificationData.modifiedCollectionItem;
      if (modifiedItem is CollectionItemChangeSet<TripMetadataFacade>) {
        _handleTripMetadataUpdate(
          context: context,
          oldMetadata: modifiedItem.beforeUpdate,
          newMetadata: modifiedItem.afterUpdate,
        );
      }
    } else if (state is UpdatedTripEntity &&
        state.dataState == DataState.select) {
      final tripEntity =
          state.tripEntityModificationData.modifiedCollectionItem;
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
        planDataEditorConfig: state.planDataEditorConfig,
      );
    }
  }

  void _handleTripMetadataUpdate({
    required BuildContext context,
    required TripMetadataFacade oldMetadata,
    required TripMetadataFacade newMetadata,
  }) {
    // Conflict resolution now happens within ConflictAwareActionPage during editing.
    // This method only handles the special case of showing a snackbar when
    // contributors were removed (since their expenses are preserved for historical accuracy).

    final oldContributors = oldMetadata.contributors.toSet();
    final newContributors = newMetadata.contributors.toSet();
    final removedContributors = oldContributors.difference(newContributors);

    if (removedContributors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Past expenses with removed tripmates are preserved for historical accuracy',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _createAddButton(BuildContext pageContext) {
    if (pageContext.isBigLayout) {
      return Padding(
        padding: EdgeInsets.only(bottom: 24.0),
        child: SizedBox(
          height: TripEditorPageConstants.fabSize,
          width: TripEditorPageConstants.fabSize,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: 'tripEditorAddButtonWithNav',
              onPressed: () => _onAddButtonPressed(pageContext),
              child: Icon(Icons.add),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: FittedBox(
        child: FloatingActionButton(
          heroTag: 'tripEditorAddButton',
          onPressed: () => _onAddButtonPressed(pageContext),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _onAddButtonPressed(BuildContext pageContext) {
    final isLoaded =
        pageContext.tripRepository.activeTrip?.isFullyLoadedValue ?? false;
    if (!isLoaded) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Trip data is still loading...')),
      );
      return;
    }
    _showModalBottomSheet(
      TripEntityCreatorBottomSheet(
        supportedActions: [
          TripEditorAction.expense,
          TripEditorAction.travel,
          TripEditorAction.stay,
        ],
        currentlyDisplayedItineraryDate: currentDateNotifier.value,
      ),
      pageContext,
    );
  }

  void _showTripEntityEditorBottomSheet<T extends TripEntity>({
    required T tripEntity,
    required TripEditorAction tripEditorAction,
    required BuildContext pageContext,
    ItineraryPlanDataEditorConfig? planDataEditorConfig,
  }) {
    final isLoaded =
        pageContext.tripRepository.activeTrip?.isFullyLoadedValue ?? false;
    if (!isLoaded) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Trip data is still loading...')),
      );
      return;
    }
    _showModalBottomSheet(
      TripEntityEditorBottomSheet<T>(
        tripEditorAction: tripEditorAction,
        tripEntity: tripEntity,
        planDataEditorConfig: planDataEditorConfig,
      ),
      pageContext,
    );
  }

  void _showModalBottomSheet(Widget child, BuildContext pageContext) {
    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      builder: (dialogContext) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: pageContext.appDataRepository),
          RepositoryProvider.value(value: pageContext.tripRepository),
          RepositoryProvider.value(value: pageContext.apiServicesRepository),
        ],
        child: BlocProvider.value(
          value: BlocProvider.of<TripManagementBloc>(pageContext),
          child: child,
        ),
      ),
    );
  }
}
