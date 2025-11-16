import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Tab content for managing sights (places) for a day's itinerary.
/// Allows adding, editing (location/time/description/expense), deleting sights.
class ItinerarySightsViewer extends StatelessWidget {
  final String tripId;
  final DateTime day;

  // Reused layout constants
  static const double _kPaddingAll = 16.0;
  static const double _kSpacingSmall = 8.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kSpacingLarge = 16.0;
  static const double _kEmptyIconSize = 48.0;

  const ItinerarySightsViewer({
    super.key,
    required this.tripId,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldRebuild,
      builder: (BuildContext context, TripManagementState state) {
        var sights = context.activeTrip.itineraryCollection
            .getItineraryForDay(day)
            .planData
            .sights;
        if (sights.isEmpty) {
          return _emptyState(context);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(_kPaddingAll),
          itemBuilder: (c, i) {
            final s = sights[i];
            final sightName =
                s.name.isEmpty ? (s.location?.context.name ?? 'Sight') : s.name;
            final locationName = s.location?.context.name;
            final hasExpense = s.expense.totalExpense.amount > 0;
            final isLightTheme = Theme.of(c).brightness == Brightness.light;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.white
                    : AppColors.darkSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.travelAccents[0].withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isLightTheme ? 0.06 : 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.addTripManagementEvent(
                    EditItineraryPlanData(
                      day: day,
                      planDataEditorConfig:
                          UpdateItineraryPlanDataComponentConfig(
                        planDataType: PlanDataType.sight,
                        index: i,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sightName,
                                style:
                                    Theme.of(c).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isLightTheme
                                              ? AppColors.neutral900
                                              : AppColors.neutral100,
                                        ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (s.visitTime != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandPrimary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: AppColors.brandPrimary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatTime(s.visitTime!),
                                            style: Theme.of(c)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.brandPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (locationName != null &&
                                      locationName != sightName)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLightTheme
                                            ? AppColors.neutral200
                                            : AppColors.neutral700,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 12,
                                            color: isLightTheme
                                                ? AppColors.neutral600
                                                : AppColors.neutral400,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              locationName,
                                              style: Theme.of(c)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: isLightTheme
                                                        ? AppColors.neutral600
                                                        : AppColors.neutral400,
                                                    fontSize: 11,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (hasExpense)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.payments_rounded,
                                            size: 12,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.expense.totalExpense.toString(),
                                            style: Theme.of(c)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.warning,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isLightTheme
                              ? AppColors.neutral400
                              : AppColors.neutral500,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: _kSpacingMedium),
          itemCount: sights.length,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldRebuild(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<ItineraryPlanData>()) {
      final tripEntityUpdatedState = currentState as UpdatedTripEntity;
      final dataState = tripEntityUpdatedState.dataState;
      final modifiedCollectionItem = tripEntityUpdatedState
          .tripEntityModificationData.modifiedCollectionItem;
      if (dataState == DataState.update) {
        final collectionItemChangeset = modifiedCollectionItem
            as CollectionItemChangeSet<ItineraryPlanData>;
        var itineraryPlanDataAfterUpdate = collectionItemChangeset.afterUpdate;
        var isItineraryPlanDataUpdated =
            collectionItemChangeset.beforeUpdate.day.isOnSameDayAs(day) ||
                itineraryPlanDataAfterUpdate.day.isOnSameDayAs(day);
        if (isItineraryPlanDataUpdated) {
          var sightsBeforeUpdate = collectionItemChangeset.beforeUpdate.sights;
          var sightsAfterUpdate = collectionItemChangeset.afterUpdate.sights;
          return !listEquals(sightsBeforeUpdate, sightsAfterUpdate);
        }
      }
    }
    return false;
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.place_outlined,
              size: _kEmptyIconSize, color: AppColors.neutral400),
          const SizedBox(height: _kSpacingMedium),
          Text('No sights added',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: _kSpacingSmall),
          const Text('Add places you plan to visit'),
          const SizedBox(height: _kSpacingLarge),
          FilledButton.icon(
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Add Sight'),
            onPressed: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: day,
                planDataEditorConfig: CreateNewItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.sight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
