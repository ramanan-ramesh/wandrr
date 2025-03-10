import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/expense_view_adapter.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/itinerary.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/lodging.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_overview/trip_overview_tile.dart';

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
    if (context.isBigLayout) {
      return _createForBigLayout(context);
    } else {
      return _createForSmallLayout(true);
    }
  }

  Widget _createForBigLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomScrollView(
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
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
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
      ],
    );
  }

  CustomScrollView _createForSmallLayout(bool isBigLayout) {
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
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            child: BudgetingHeaderTile(
              expenseViewTypeNotifier: _expenseViewTypeNotifier,
            ),
          ),
        ),
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
