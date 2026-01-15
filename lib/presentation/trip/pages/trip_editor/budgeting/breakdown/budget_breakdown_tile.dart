import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/tab_bar.dart';

import 'breakdown_by_category.dart';
import 'breakdown_by_day.dart';

class BudgetBreakdownTile extends StatelessWidget {
  const BudgetBreakdownTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Card(
            child: PlatformTabBar(
              tabBarItems: <String, Widget>{
                context.localizations.dayByDay: const BreakdownByDayChart(),
                context.localizations.category:
                    const BreakdownByCategoryChart(),
              },
            ),
          ),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState.isTripEntityUpdated<ExpenseBearingTripEntity>();
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
