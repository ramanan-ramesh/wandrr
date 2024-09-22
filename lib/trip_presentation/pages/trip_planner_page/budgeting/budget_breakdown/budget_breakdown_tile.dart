import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/budgeting/budget_breakdown/breakdown_by_category.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/budgeting/budget_breakdown/breakdown_by_day.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';

class BudgetBreakdownTile extends StatefulWidget {
  const BudgetBreakdownTile({super.key});

  @override
  State<BudgetBreakdownTile> createState() => _BudgetBreakdownTileState();
}

class _BudgetBreakdownTileState extends State<BudgetBreakdownTile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return SliverToBoxAdapter(
          child: Container(
            constraints: BoxConstraints(maxHeight: 600),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white12,
              child: PlatformTabBar(
                tabBarItems: <String, Widget>{
                  context.withLocale().category: BreakdownByCategoryChart(),
                  context.withLocale().dayByDay: BreakdownByDayChart(),
                },
                // tabController: _tabController,
              ),
            ),
          ),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState.isTripEntity<ExpenseFacade>() ||
            currentState.isTripEntity<TransitFacade>() ||
            currentState.isTripEntity<LodgingFacade>();
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
