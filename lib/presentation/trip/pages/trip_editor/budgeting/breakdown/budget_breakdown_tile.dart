import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

import 'breakdown_by_category.dart';
import 'breakdown_by_day.dart';

/// Breakdown page showing category chart and day-by-day in a single scrollable
/// view — no nested tabs (parent already has tabs).
class BudgetBreakdownTile extends StatelessWidget {
  const BudgetBreakdownTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        final isLight = context.isLightTheme;
        final sectionTitle = Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isLight ? AppColors.neutral800 : AppColors.neutral200,
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 16,
            bottom: TripEditorPageConstants.fabContentPaddingBig,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category breakdown section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.pie_chart_rounded,
                        size: 18,
                        color: isLight
                            ? AppColors.brandPrimary
                            : AppColors.brandPrimaryLight),
                    const SizedBox(width: 8),
                    Text(context.localizations.category, style: sectionTitle),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const BreakdownByCategoryChart(),
              const SizedBox(height: 24),
              // Day-by-day section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18,
                        color: isLight
                            ? AppColors.brandPrimary
                            : AppColors.brandPrimaryLight),
                    const SizedBox(width: 8),
                    Text(context.localizations.dayByDay, style: sectionTitle),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const BreakdownByDayChart(),
            ],
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
