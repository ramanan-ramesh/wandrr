import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/bloc.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/states.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/models/budgeting_module.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/budgeting/budget_breakdown/breakdown_by_category.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/budgeting/budget_breakdown/breakdown_by_day.dart';

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
        var shouldDisplayTotalExpensePerCategory = _tabController.index == 0;
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
                if (shouldDisplayTotalExpensePerCategory)
                  BreakdownByCategoryChart(
                    budgetingModule: _budgetingModule,
                  )
                else
                  BreakdownByDayChart(
                    budgetingModule: _budgetingModule,
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
      labelStyle: const TextStyle(fontSize: 22),
      onTap: (selectedTabIndex) {
        setState(() {
          _tabController.index = selectedTabIndex;
        });
      },
      labelColor: Colors.white,
      unselectedLabelColor: Colors.black,
      tabs: [
        Tab(text: context.withLocale().category),
        Tab(text: context.withLocale().dayByDay),
      ],
    );
  }
}
