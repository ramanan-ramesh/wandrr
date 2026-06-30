import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
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
  late DateTime _currentDisplayedDate;
  int _currentPageIndex = 0;

  // Created once and shared by both layout branches so that each page retains
  // its state (e.g. ItineraryNavigator's current-day selection) across
  // tab switches and layout changes.
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
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TripEditorPanel(
                  accentColor: AppColors.brandPrimary,
                  child: _itineraryPage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TripEditorPanel(
                  accentColor: AppColors.info,
                  child: _budgetingPage,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _TripEditorPageInternal(
      getDisplayedDate: () => _currentDisplayedDate,
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _currentPageIndex != 0,
            child: AnimatedOpacity(
              opacity: _currentPageIndex == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _itineraryPage,
            ),
          ),
          IgnorePointer(
            ignoring: _currentPageIndex != 1,
            child: AnimatedOpacity(
              opacity: _currentPageIndex == 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _budgetingPage,
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
    return BlocListener<TripManagementBloc, TripManagementState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        appBar: const TripEditorAppBar(),
        extendBody: bottomNavigationBar == null,
        floatingActionButton: _createAddButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
                  bottom: MediaQuery.of(context).padding.bottom +
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
      _showTripEntityEditorBottomSheet<ExpenseBearingTripEntity>(
        tripEditorAction: TripEditorAction.expense,
        tripEntity: expenseBearingTripEntity,
        pageContext: context,
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
        return Padding(
          padding: EdgeInsets.only(bottom: isBigLayout ? 24.0 : 0.0),
          child: AnimatedOpacity(
            opacity: isLoaded ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: SizedBox(
              height: TripEditorPageConstants.fabSize,
              width: TripEditorPageConstants.fabSize,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: isBigLayout
                      ? 'tripEditorAddButtonWithNav'
                      : 'tripEditorAddButton',
                  onPressed:
                      isLoaded ? () => _onAddButtonPressed(pageContext) : null,
                  child: const Icon(Icons.add),
                ),
              ),
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

  void _showTripEntityEditorBottomSheet<T extends TripEntity<Enum>>({
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
          value: BlocProvider.of<TripManagementBloc>(pageContext),
          // When the user scrolls the bottom-sheet content while an autocomplete
          // options overlay is open, the overlay (rendered in the Overlay widget
          // tree) stays fixed while the field scrolls away.
          //
          // Strategy: listen to ScrollUpdateNotifications (which fire continuously
          // during a drag) and check whether the currently-focused widget is still
          // within the visible screen area using localToGlobal.  We unfocus only
          // when the field has scrolled *completely* out of view, so:
          //   • Scrolling slowly inside the sheet keeps the dropdown open as long
          //     as the field is still visible.
          //   • Scrolling within the autocomplete options list itself is unaffected
          //     because that list lives in a separate Overlay widget tree and its
          //     ScrollUpdateNotifications never reach this listener.
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              final primaryFocus = FocusManager.instance.primaryFocus;
              if (primaryFocus == null) {
                return false;
              }
              final focusedContext = primaryFocus.context;
              if (focusedContext == null) {
                return false;
              }
              final renderBox = focusedContext.findRenderObject();
              if (renderBox is! RenderBox ||
                  !renderBox.hasSize ||
                  !renderBox.attached) {
                return false;
              }

              // Convert the focused widget's top-left corner to screen coordinates.
              final topLeft = renderBox.localToGlobal(Offset.zero);
              final fieldHeight = renderBox.size.height;
              final screenHeight = MediaQuery.sizeOf(dialogContext).height;

              // Dismiss only when the field is fully outside the visible area.
              final scrolledAbove = topLeft.dy + fieldHeight < 0;
              final scrolledBelow = topLeft.dy > screenHeight;
              if (scrolledAbove || scrolledBelow) {
                primaryFocus.unfocus();
              }
              return false; // let the notification keep bubbling
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

/// Elegant panel container used on tablets to visually distinguish the
/// Itinerary and Budgeting sections.  Each panel has:
///   • White / dark-surface background for strong contrast against the scaffold
///   • A 4 px accent bar at the top, colour-coded per section
///   • Rounded corners + depth shadow
class _TripEditorPanel extends StatelessWidget {
  final Widget child;

  /// Accent colour — brandPrimary for Itinerary, info-blue for Budgeting.
  final Color accentColor;

  const _TripEditorPanel({
    required this.child,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? accentColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isLight
              ? accentColor.withValues(alpha: 0.18)
              : accentColor.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 4 px accent strip at the top — provides instant visual identity
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
