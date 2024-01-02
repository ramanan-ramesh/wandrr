import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/itinerary/itinerary_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/lodging/lodging_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/plan_data_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_overview_tile.dart';

import 'modules/budgeting/expenses_listview.dart';
import 'modules/budgeting/header_tile.dart';
import 'sidebar_widget.dart';

class TripPlannerPage extends StatelessWidget {
  static const _breakOffPageWidth = 800;

  TripPlannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO: Bring valueListenableBuilder to top and then layout builder under
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > _breakOffPageWidth) {
          const double maxWidth = 1000;
          const double minWidth = 450;
          var sizeToApply = 0.6 * constraints.maxWidth;
          var minWidthToApply = minWidth < sizeToApply ? minWidth : sizeToApply;
          var constraintsToApply = BoxConstraints(
              maxWidth: maxWidth,
              minWidth: minWidthToApply,
              minHeight: constraints.minHeight,
              maxHeight: constraints.maxHeight);
          return Row(
            children: [
              Expanded(
                child: _buildFirstPage(context),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: 700, minWidth: _breakOffPageWidth / 2),
                    child: CustomScrollView(
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: BudgetingHeaderTile(),
                        ),
                        ExpensesListView(
                          isCollapsed: false,
                        )
                      ],
                    ),
                    // child: BudgetingFragment()
                  ),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.red,
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFirstPage(BuildContext context) {
    return Scaffold(
      appBar: _AppBar(),
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            child: Container(
              //TODO: not working. Can't apply constraints on a Viewport
              constraints: BoxConstraints(
                  maxWidth: 700, minWidth: _breakOffPageWidth / 2),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: TripOverviewTile(),
                  ),
                  SliverPadding(
                    sliver: TransitListView(),
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                  ),
                  SliverToBoxAdapter(
                    child: Divider(
                      height: 25,
                      color: Colors.grey,
                    ),
                  ),
                  SliverPadding(
                    sliver: LodgingListView(),
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                  ),
                  SliverToBoxAdapter(
                    child: Divider(
                      height: 25,
                      color: Colors.grey,
                    ),
                  ),
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                    sliver: PlanDataListView(),
                  ),
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                    sliver: ItineraryListView(),
                  )
                ],
              ),
            ),
          )
        ],
      ),
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
          var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
          tripManagementBloc.add(GoToHome());
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                _appLogoAsset, //
                color: Colors.white, // Replace with your app logo asset
                width: 40,
                height: 40,
              ),
            ),
            const Text(
              'wandrr', // Replace with your app name
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      actions: [
        FloatingActionButton.extended(
          onPressed: null,
          label: Text('Share'),
          icon: Icon(Icons.share),
        ),
        IconButton(onPressed: null, icon: Icon(Icons.translate)),
      ],
    );
  }
}
