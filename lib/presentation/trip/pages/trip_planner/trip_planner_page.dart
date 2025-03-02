import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/expense_view_adapter.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/itinerary.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/lodging.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_overview/trip_overview_tile.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';

import 'budgeting/header_tile.dart';
import 'expense_view_type.dart';
import 'trip_entity_list_views/plan_data.dart';

class TripPlannerPage extends StatefulWidget {
  TripPlannerPage({Key? key}) : super(key: key);

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage>
    with SingleTickerProviderStateMixin {
  static const _breakOffLayoutWidth = 1000;
  static const _maximumPageWidth = 700.0;

  final _expenseViewTypeNotifier =
      ValueNotifier<ExpenseViewType>(ExpenseViewType.ExpenseList);

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var appLevelData = context.appDataModifier;
        if (constraints.maxWidth > _breakOffLayoutWidth) {
          appLevelData.isBigLayout = true;
          return _createForBigLayout(context);
        } else {
          appLevelData.isBigLayout = false;
          return Center(
            child: Container(
              constraints:
                  BoxConstraints(minWidth: 500, maxWidth: _maximumPageWidth),
              child: _buildLayout(context),
            ),
          );
        }
      },
    );
  }

  Widget _createForBigLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildConstrainedPageForLayout(_buildLayout(context)),
        ),
        Expanded(
          child: _buildConstrainedPageForLayout(
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: BudgetingHeaderTile(
                    expenseViewTypeNotifier: _expenseViewTypeNotifier,
                  ),
                ),
                ExpenseViewAdapter(
                  expenseViewTypeNotifier: _expenseViewTypeNotifier,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConstrainedPageForLayout(Widget layout) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
            maxWidth: _maximumPageWidth, minWidth: _breakOffLayoutWidth / 2),
        child: layout,
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    var isBigLayout = context.isBigLayout;
    return Stack(
      children: [
        Scaffold(
          appBar: _AppBar(),
          body: _createNestedScrollableView(isBigLayout),
        ),
      ],
    );
  }

  CustomScrollView _createNestedScrollableView(bool isBigLayout) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: TripOverviewTile(),
        ),
        SliverPadding(
          sliver: TransitListView(),
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        ),
        SliverToBoxAdapter(
          child: Divider(
            height: 25,
          ),
        ),
        SliverPadding(
          sliver: LodgingListView(),
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        ),
        SliverToBoxAdapter(
          child: Divider(
            height: 25,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          sliver: PlanDataListView(),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          sliver: ItineraryListView(),
        ),
        if (!isBigLayout)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: BudgetingHeaderTile(
                expenseViewTypeNotifier: _expenseViewTypeNotifier,
              ),
            ),
          ),
        if (!isBigLayout)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            sliver: ExpenseViewAdapter(
              expenseViewTypeNotifier: _expenseViewTypeNotifier,
            ),
          ),
      ],
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  static const String _appLogoAsset = 'assets/images/logo.jpg';

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const _AppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: () {
          context.addTripManagementEvent(GoToHome());
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Image.asset(
                  _appLogoAsset,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: const Text(
                'wandrr',
                style: TextStyle(fontSize: 20), //ThemingRequired
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showDeleteTripConfirmationDialog(context);
          },
          icon: Icon(Icons.delete_rounded),
        ),
      ],
    );
  }

  void _showDeleteTripConfirmationDialog(BuildContext pageContext) {
    var tripMetadataToDelete = pageContext.activeTrip.tripMetadata;
    PlatformDialogElements.showAlertDialog(pageContext, (context) {
      return DeleteTripDialog(
          widgetContext: pageContext, tripMetadataFacade: tripMetadataToDelete);
    });
  }
}
