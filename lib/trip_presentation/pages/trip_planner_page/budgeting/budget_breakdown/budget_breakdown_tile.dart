import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/models/budgeting_module.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
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
  late BudgetingModuleFacade _budgetingModule;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _budgetingModule = context.getActiveTrip().budgetingModuleFacade;
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
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _createTabBar(),
                const SizedBox(height: 16.0),
                Container(
                  constraints: BoxConstraints(maxHeight: 500),
                  child: Center(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BreakdownByCategoryChart(
                          budgetingModule: _budgetingModule,
                        ),
                        BreakdownByDayChart(
                          budgetingModule: _budgetingModule,
                        )
                      ],
                    ),
                  ),
                )
              ],
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

  TabBar _createTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Tab(text: context.withLocale().category),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Tab(text: context.withLocale().dayByDay),
        ),
      ],
    );
  }
}
