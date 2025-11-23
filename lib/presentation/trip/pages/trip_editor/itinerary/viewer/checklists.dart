import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class ItineraryChecklistTab extends StatefulWidget {
  final VoidCallback onChanged;
  final DateTime day;

  const ItineraryChecklistTab({
    super.key,
    required this.onChanged,
    required this.day,
  });

  @override
  State<ItineraryChecklistTab> createState() => _ItineraryChecklistTabState();
}

class _ItineraryChecklistTabState extends State<ItineraryChecklistTab> {
  // Layout constants
  static const double _kPaddingAll = 16.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kSpacingLarge = 16.0;
  static const double _kEmptyIconSize = 48.0;

  // Track expanded state for each checklist
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldRebuild,
      builder: (BuildContext context, TripManagementState state) {
        var checklists = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.day)
            .planData
            .checkLists;
        if (checklists.isEmpty) {
          return _emptyState(context);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(_kPaddingAll),
          itemBuilder: (c, i) {
            final cl = checklists[i];
            final title = cl.title?.trim().isEmpty ?? true
                ? context.localizations.untitledChecklist
                : cl.title!.trim();
            final completedCount =
                cl.items.where((item) => item.isChecked).length;
            final totalCount = cl.items.length;
            final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
            final isLightTheme = Theme.of(c).brightness == Brightness.light;
            final isExpanded = _expandedIndices.contains(i);

            return DecoratedBox(
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.white
                    : AppColors.darkSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
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
              child: Column(
                children: [
                  // Header (always visible)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIndices.remove(i);
                          } else {
                            _expandedIndices.add(i);
                          }
                        });
                      },
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
                                    title,
                                    style: Theme.of(c)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isLightTheme
                                              ? AppColors.neutral900
                                              : AppColors.neutral100,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: isLightTheme
                                                ? AppColors.neutral200
                                                : AppColors.neutral700,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              progress == 1.0
                                                  ? AppColors.success
                                                  : AppColors.info,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$completedCount/$totalCount',
                                        style: Theme.of(c)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isLightTheme
                                                  ? AppColors.neutral600
                                                  : AppColors.neutral400,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit button
                                InkWell(
                                  onTap: () => context.addTripManagementEvent(
                                    EditItineraryPlanData(
                                      day: widget.day,
                                      planDataEditorConfig:
                                          UpdateItineraryPlanDataComponentConfig(
                                        planDataType: PlanDataType.checklist,
                                        index: i,
                                      ),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: isLightTheme
                                          ? AppColors.neutral500
                                          : AppColors.neutral400,
                                      size: 25,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Expand/collapse indicator
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: isLightTheme
                                      ? AppColors.neutral400
                                      : AppColors.neutral500,
                                  size: 25,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Collapsible items list
                  if (isExpanded && cl.items.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isLightTheme
                            ? AppColors.neutral100.withValues(alpha: 0.5)
                            : AppColors.darkSurfaceVariant
                                .withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: isLightTheme
                                ? AppColors.neutral300
                                : AppColors.neutral700,
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: cl.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (ctx, itemIndex) {
                              final item = cl.items[itemIndex];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Non-editable checkbox
                                    Icon(
                                      item.isChecked
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 20,
                                      color: item.isChecked
                                          ? AppColors.success
                                          : (isLightTheme
                                              ? AppColors.neutral400
                                              : AppColors.neutral500),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.item,
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: isLightTheme
                                                  ? AppColors.neutral800
                                                  : AppColors.neutral200,
                                              decoration: item.isChecked
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              decorationColor: isLightTheme
                                                  ? AppColors.neutral500
                                                  : AppColors.neutral400,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: _kSpacingMedium),
          itemCount: checklists.length,
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
        var isItineraryPlanDataUpdated = collectionItemChangeset
                .beforeUpdate.day
                .isOnSameDayAs(widget.day) ||
            itineraryPlanDataAfterUpdate.day.isOnSameDayAs(widget.day);
        if (isItineraryPlanDataUpdated) {
          var checklistsBeforeUpdate =
              collectionItemChangeset.beforeUpdate.checkLists;
          var checklistsAfterUpdate =
              collectionItemChangeset.afterUpdate.checkLists;
          return !listEquals(checklistsBeforeUpdate, checklistsAfterUpdate);
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
          const Icon(Icons.checklist_outlined,
              size: _kEmptyIconSize, color: AppColors.neutral400),
          const SizedBox(height: _kSpacingMedium),
          Text(context.localizations.noChecklistsCreated,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(context.localizations.addChecklistsForThisDay),
          const SizedBox(height: _kSpacingLarge),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(context.localizations.addChecklist),
            onPressed: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: widget.day,
                planDataEditorConfig:
                    const CreateNewItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.checklist,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
