import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/app_bar/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'action_handling/creator_bottom_sheet.dart';
import 'action_handling/editor_bottom_sheet.dart';
import 'budgeting/budgeting_page.dart';
import 'itinerary/itinerary_navigator.dart';

class TripEditorPage extends StatefulWidget {
  const TripEditorPage({super.key});

  @override
  State<TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends State<TripEditorPage> {
  late DateTime _currentDisplayedDate;
  static const _padding = 8.0;
  static const _topPaneRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );

  late final Widget _itineraryPage = ItineraryNavigator(
    onNavigatedToDate: (date) => _currentDisplayedDate = date,
  );
  late final Widget _budgetingPage = const BudgetingPage();

  @override
  void initState() {
    super.initState();
    _currentDisplayedDate = context.activeTrip.tripMetadata.startDate!;
  }

  @override
  Widget build(BuildContext context) {
    final isBigLayout = context.isBigLayout;

    if (isBigLayout) {
      return _TripEditorPageInternal(
        getDisplayedDate: () => _currentDisplayedDate,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(_padding, _padding, _padding, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: _topPaneRadius,
                  child: _itineraryPage,
                ),
              ),
              SizedBox(width: _padding),
              Expanded(
                child: ClipRRect(
                  borderRadius: _topPaneRadius,
                  child: _budgetingPage,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _TripEditorSmallLayout(
      getDisplayedDate: () => _currentDisplayedDate,
      itineraryPage: _itineraryPage,
      budgetingPage: _budgetingPage,
    );
  }
}

class _TripEditorSmallLayout extends StatefulWidget {
  final Widget itineraryPage;
  final Widget budgetingPage;
  final DateTime Function() getDisplayedDate;

  _TripEditorSmallLayout({
    required this.itineraryPage,
    required this.budgetingPage,
    required this.getDisplayedDate,
  });

  @override
  State<_TripEditorSmallLayout> createState() => _TripEditorSmallLayoutState();
}

class _TripEditorSmallLayoutState extends State<_TripEditorSmallLayout> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return _TripEditorPageInternal(
      getDisplayedDate: widget.getDisplayedDate,
      body: Stack(
        children: [
          ExcludeSemantics(
            excluding: _currentPageIndex != 0,
            child: IgnorePointer(
              ignoring: _currentPageIndex != 0,
              child: AnimatedOpacity(
                opacity: _currentPageIndex == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: widget.itineraryPage,
              ),
            ),
          ),
          ExcludeSemantics(
            excluding: _currentPageIndex != 1,
            child: IgnorePointer(
              ignoring: _currentPageIndex != 1,
              child: AnimatedOpacity(
                opacity: _currentPageIndex == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: widget.budgetingPage,
              ),
            ),
          ),
        ],
      ),
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
  final DateTime Function() getDisplayedDate;

  const _TripEditorPageInternal({
    required this.body,
    required this.getDisplayedDate,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return BlocListener<TripManagementBloc, TripManagementState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        appBar: const TripEditorAppBar(),
        extendBody: bottomNavigationBar == null,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
              bottom: context.isBigLayout
                  ? TripEditorPageConstants.fabBottomPadding
                  : 0.0),
          child: _createAddButton(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: MediaQuery(
          data: mediaQuery.copyWith(
            padding: mediaQuery.padding.copyWith(
              bottom: mediaQuery.padding.bottom +
                  (bottomNavigationBar == null
                      ? TripEditorPageConstants.fabContentPaddingBig
                      : TripEditorPageConstants.fabContentPaddingSmall),
            ),
          ),
          child: body,
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  void _onBlocStateChanged(BuildContext context, TripManagementState state) {
    if (state is SelectedExpenseBearingTripEntity) {
      final expenseBearingTripEntity =
          state.tripEntityModificationData.collectionItemChange;
      _showModalBottomSheet(
        TripEntityEditorBottomSheet<ExpenseBearingTripEntity>(
          tripEditorAction: TripEditorAction.expense,
          tripEntity: expenseBearingTripEntity,
          showAsExpenseEditor: true,
        ),
        context,
      );
    } else if (state is UpdatedTripEntity &&
        state.dataState == DataState.update) {
      final modifiedItem =
          state.tripEntityModificationData.collectionItemChange;
      if (modifiedItem is Changeset<TripMetadataFacade>) {
        _handleTripMetadataUpdate(
          context: context,
          oldMetadata: modifiedItem.beforeUpdate,
          newMetadata: modifiedItem.afterUpdate,
        );
      }
    } else if (state is UpdatedTripEntity &&
        state.dataState == DataState.select) {
      final tripEntity = state.tripEntityModificationData.collectionItemChange;
      if (tripEntity is TransitFacade) {
        _showModalBottomSheet(
          TripEntityEditorBottomSheet<TransitFacade>(
            tripEditorAction: TripEditorAction.travel,
            tripEntity: tripEntity,
          ),
          context,
        );
      } else if (tripEntity is LodgingFacade) {
        _showModalBottomSheet(
          TripEntityEditorBottomSheet<LodgingFacade>(
            tripEditorAction: TripEditorAction.stay,
            tripEntity: tripEntity,
          ),
          context,
        );
      } else if (tripEntity is TripMetadataFacade) {
        _showModalBottomSheet(
          TripEntityEditorBottomSheet<TripMetadataFacade>(
            tripEditorAction: TripEditorAction.tripDetails,
            tripEntity: tripEntity,
          ),
          context,
        );
      }
    } else if (state is SelectedItineraryPlanData) {
      _showModalBottomSheet(
        TripEntityEditorBottomSheet<ItineraryPlanData>(
          tripEditorAction: TripEditorAction.itineraryData,
          tripEntity: state.planData,
          planDataEditorConfig: state.planDataEditorConfig,
        ),
        context,
      );
    }
  }

  //TODO: This should be shown while trying to add/edit a tripmate, not after the fact. We can move this logic to the TripContributorsEditorSection which is used for editing tripmates, but we still want to show the snackbar when tripmates are removed from the trip since that action doesn't have a conflict resolution step but still has the same outcome of preserving past expenses for historical accuracy.
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
    final isBigLayout = pageContext.isBigLayout;
    return StreamBuilder<bool>(
      stream: pageContext.tripRepository.activeTrip!.isFullyLoaded,
      initialData: pageContext.tripRepository.activeTrip!.isFullyLoadedValue,
      builder: (context, snapshot) {
        final isLoaded = snapshot.data ?? false;
        return AnimatedOpacity(
          opacity: isLoaded ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: SizedBox(
            height: TripEditorPageConstants.fabSize,
            width: TripEditorPageConstants.fabSize,
            child: FloatingActionButton(
              heroTag: isBigLayout
                  ? 'tripEditorAddButtonWithNav'
                  : 'tripEditorAddButton',
              onPressed:
                  isLoaded ? () => _onAddButtonPressed(pageContext) : null,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  void _onAddButtonPressed(BuildContext pageContext) {
    _showModalBottomSheet(
      TripEntityCreatorBottomSheet(
        supportedActions: const [
          TripEditorAction.expense,
          TripEditorAction.travel,
          TripEditorAction.stay,
        ],
        currentlyDisplayedItineraryDate: getDisplayedDate(),
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
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              FocusManager.instance.primaryFocus?.unfocus();
              return false;
            },
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
