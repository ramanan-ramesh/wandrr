import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
import 'package:wandrr/presentation/app/widgets/tab_bar.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/budgeting/breakdown/breakdown_by_category.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/budgeting/breakdown/breakdown_by_day.dart';

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
            constraints: const BoxConstraints(maxHeight: 600),
            child: PlatformCard(
              child: PlatformTabBar(
                tabBarItems: <String, Widget>{
                  context.localizations.category:
                      const BreakdownByCategoryChart(),
                  context.localizations.dayByDay: const BreakdownByDayChart(),
                },
              ),
            ),
          ),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState.isTripEntityUpdated<ExpenseFacade>() ||
            currentState.isTripEntityUpdated<TransitFacade>() ||
            currentState.isTripEntityUpdated<LodgingFacade>();
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
