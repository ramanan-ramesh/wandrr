import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/tab_bar.dart';

import 'breakdown_by_category.dart';
import 'breakdown_by_day.dart';

class BudgetBreakdownTile extends StatefulWidget {
  const BudgetBreakdownTile({super.key});

  @override
  State<BudgetBreakdownTile> createState() => _BudgetBreakdownTileState();
}

class _BudgetBreakdownTileState extends State<BudgetBreakdownTile> {
  // Incremented on every expense update — propagated as ValueKey to charts
  // so their State is recreated and data is re-fetched.
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripManagementBloc, TripManagementState>(
      listenWhen: (previous, current) =>
          current.isTripEntityUpdated<ExpenseBearingTripEntity>(),
      listener: (context, state) {
        setState(() => _refreshKey++);
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Card(
          child: PlatformTabBar(
            tabBarItems: {
              context.localizations.category: BreakdownByCategoryChart(
                key: ValueKey('category_$_refreshKey'),
              ),
              context.localizations.dayByDay: BreakdownByDayChart(
                key: ValueKey('day_$_refreshKey'),
              ),
            },
          ),
        ),
      ),
    );
  }
}
