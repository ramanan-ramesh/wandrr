import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/expense_view_adapter.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/trip_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/itinerary.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/lodging.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_overview/trip_overview_tile.dart';

import 'budgeting/header_tile.dart';
import 'expense_view_type.dart';
import 'navigation/jump_to_list.dart';
import 'navigation/nav_bar.dart';
import 'trip_entity_list_views/plan_data.dart';

class TripPlannerPage extends StatelessWidget {
  final _expenseViewTypeNotifier =
      ValueNotifier<ExpenseViewType>(ExpenseViewType.expenseList);
  final ScrollController _scrollController = ScrollController();

  TripPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<TripNavigator>(
      create: (context) => TripNavigator(scrollController: _scrollController),
      child: context.isBigLayout
          ? _createForBigLayout()
          : Stack(
              children: [
                _createForSmallLayout(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: FloatingJumpToListNavigator(),
                ),
              ],
            ),
    );
  }

  Widget _createForBigLayout() {
    return Row(
      children: [
        const JumpToListNavigationBar(),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: const [
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

  Widget _createForSmallLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(
          child: TripOverviewTile(),
        ),
        const SliverPadding(
          sliver: TransitListView(),
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        ),
        const SliverToBoxAdapter(
          child: Divider(
            height: 25,
          ),
        ),
        const SliverPadding(
          sliver: LodgingListView(),
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        ),
        const SliverToBoxAdapter(
          child: Divider(
            height: 25,
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          sliver: PlanDataListView(),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          sliver: ItineraryListView(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            child: BudgetingHeaderTile(
              expenseViewTypeNotifier: _expenseViewTypeNotifier,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          sliver: ExpenseViewAdapter(
            expenseViewTypeNotifier: _expenseViewTypeNotifier,
          ),
        ),
      ],
    );
  }
}
