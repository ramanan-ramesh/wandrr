import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_view_adapter.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/itinerary/itinerary_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/lodging/lodging_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/plan_data_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/transit/transit_listview.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_overview_tile.dart';

import 'modules/budgeting/header_tile.dart';

class TripPlannerPage extends StatelessWidget {
  static const _breakOffPageWidth = 800;

  TripPlannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO: Bring valueListenableBuilder to top and then layout builder under
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > _breakOffPageWidth) {
          return Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                      constraints: BoxConstraints(
                          maxWidth: 700, minWidth: _breakOffPageWidth / 2),
                      child: _buildFirstPage(context, true)),
                ),
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
                        ExpenseViewAdapter(),
                      ],
                    ),
                    // child: BudgetingFragment()
                  ),
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: Container(
              constraints: BoxConstraints(minWidth: 500, maxWidth: 700),
              child: _buildFirstPage(context, false),
            ),
          );
        }
      },
    );
  }

  Widget _buildFirstPage(BuildContext context, bool isBigLayout) {
    return Scaffold(
      appBar: _AppBar(),
      drawer: Drawer(),
      body: CustomScrollView(
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
              color: Colors.grey,
            ),
          ),
          SliverPadding(
            sliver: LodgingListView(),
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 25,
              color: Colors.grey,
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
              child: BudgetingHeaderTile(),
            ),
          if (!isBigLayout) ExpenseViewAdapter(),
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
