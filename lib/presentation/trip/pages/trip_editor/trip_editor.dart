import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
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
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_bottom_sheet.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model_factory.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'itinerary/itinerary_navigator.dart';

/// Main entry point for the trip editor page.
class TripEditorPage extends StatelessWidget {
  const TripEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return _TripEditorPageInternal(
        body: Row(
          children: const [
            Expanded(child: ItineraryNavigator()),
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
  late final List<Widget> _pages = [
    const ItineraryNavigator(),
    const BudgetingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return _TripEditorPageInternal(
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

  const _TripEditorPageInternal({
    required this.body,
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
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  void _onBlocStateChanged(BuildContext context, TripManagementState state) {
    if (state is SelectedExpenseLinkedTripEntity) {
      final expenseLinkedTripEntity =
          state.tripEntityModificationData.modifiedCollectionItem;
      _showTripEntityEditorBottomSheet<ExpenseLinkedTripEntity>(
        tripEditorAction: TripEditorAction.expense,
        tripEntity: expenseLinkedTripEntity,
        pageContext: context,
      );
    } else if (state is UpdatedTripEntity &&
        state.dataState == DataState.update) {
      // Check if this is a TripMetadataFacade update with date or contributor changes
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
    // Check if we have affected entities that need user attention
    final affectedEntitiesModel = AffectedEntitiesModelFactory.create(
      oldMetadata: oldMetadata,
      newMetadata: newMetadata,
      tripData: context.activeTrip,
    );

    if (affectedEntitiesModel != null &&
        affectedEntitiesModel.hasAffectedEntities) {
      // Show the affected entities bottom sheet
      _showModalBottomSheet(
        AffectedEntitiesBottomSheet(
          affectedEntitiesModel: affectedEntitiesModel,
        ),
        context,
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
    _showModalBottomSheet(
      TripEntityCreatorBottomSheet(supportedActions: [
        TripEditorAction.expense,
        TripEditorAction.travel,
        TripEditorAction.stay,
      ]),
      pageContext,
    );
  }

  void _showTripEntityEditorBottomSheet<T extends TripEntity>({
    required T tripEntity,
    required TripEditorAction tripEditorAction,
    required BuildContext pageContext,
    ItineraryPlanDataEditorConfig? planDataEditorConfig,
  }) {
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
          value: pageContext.read<TripManagementBloc>(),
          child: child,
        ),
      ),
    );
  }
}
