import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/routing/app_router.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/copy_trip_dialog.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

import 'thumbnail_selector.dart';

class TripListView extends StatefulWidget {
  TripListView({
    super.key,
  });

  @override
  State<TripListView> createState() => _TripListViewState();
}

class _TripListViewState extends State<TripListView> {
  int? _selectedUpcomingYear;
  int? _selectedPastYear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      child: BlocConsumer<TripManagementBloc, TripManagementState>(
        buildWhen: _shouldBuildListView,
        listener: (context, state) {},
        builder: (context, state) {
          return StreamBuilder<bool>(
            stream: context.tripRepository.tripMetadataCollection.onLoaded,
            initialData: context.tripRepository.tripMetadataCollection.isLoaded,
            builder: (context, snapshot) {
              final isLoaded = snapshot.data ?? false;
              var tripMetadatas = context
                  .tripRepository.tripMetadataCollection.collectionItems
                  .toList(growable: false)
                ..sort((tripMetadata1, tripMetadata2) =>
                    tripMetadata1.startDate!.compareTo(tripMetadata2.startDate!));

              if (!isLoaded && tripMetadatas.isEmpty) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return ShimmerPlaceholder(borderRadius: BorderRadius.circular(10));
                  },
                );
              }

              if (tripMetadatas.isNotEmpty) {
                return _buildTripsSections(context, tripMetadatas, isLoaded);
              } else {
                return Align(
                  alignment: Alignment.center,
                  child: PlatformTextElements.createSubHeader(
                    context: context,
                    text: context.localizations.noTripsCreated,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTripsSections(
      BuildContext context, List<TripMetadataFacade> trips, bool isLoaded) {
    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);

    var upcomingTripsRaw =
        trips.where((t) => !t.endDate!.isBefore(today)).toList();
    var pastTripsRaw = trips.where((t) => t.endDate!.isBefore(today)).toList();

    // Extract Years
    var upcomingYears = upcomingTripsRaw
        .map((t) => t.startDate!.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var pastYears = pastTripsRaw.map((t) => t.startDate!.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    // Initialize/Sync Selection
    if (upcomingYears.isNotEmpty &&
        (_selectedUpcomingYear == null ||
            !upcomingYears.contains(_selectedUpcomingYear))) {
      _selectedUpcomingYear = upcomingYears.first;
    }
    if (pastYears.isNotEmpty &&
        (_selectedPastYear == null || !pastYears.contains(_selectedPastYear))) {
      _selectedPastYear = pastYears.first;
    }

    List<Widget> slivers = [];

    // Upcoming Section
    if (upcomingTripsRaw.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(context.localizations.upcomingTrips,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: _buildYearChips(upcomingYears, _selectedUpcomingYear, (year) {
            setState(() => _selectedUpcomingYear = year);
          }),
        ),
      );
      var filteredUpcoming = upcomingTripsRaw
          .where((t) => t.startDate!.year == _selectedUpcomingYear)
          .toList();
      slivers.add(_buildTripGrid(filteredUpcoming, isLoaded));
    }

    // Past Section
    if (pastTripsRaw.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(context.localizations.pastTrips,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: _buildYearChips(pastYears, _selectedPastYear, (year) {
            setState(() => _selectedPastYear = year);
          }),
        ),
      );
      var filteredPast = pastTripsRaw
          .where((t) => t.startDate!.year == _selectedPastYear)
          .toList()
        ..sort((a, b) => b.startDate!.compareTo(a.startDate!));
      slivers.add(_buildTripGrid(filteredPast, isLoaded));
    }

    return CustomScrollView(
      slivers: slivers,
    );
  }

  Widget _buildYearChips(
      List<int> years, int? selectedYear, Function(int) onSelected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: years.map((year) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(year.toString()),
              selected: selectedYear == year,
              onSelected: (selected) {
                if (selected) onSelected(year);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripGrid(List<TripMetadataFacade> trips, bool isLoaded) {
    // If not fully loaded, add padding up to 3 minimum items, or just 1 extra trailing shimmer
    final itemCount =
        isLoaded ? trips.length : (trips.length < 3 ? 3 : trips.length + 1);
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < trips.length) {
            return _TripMetadataGridItem(tripId: trips[index].id!);
          } else {
            return ShimmerPlaceholder(borderRadius: BorderRadius.circular(10));
          }
        },
        childCount: itemCount,
      ),
    );
  }

  bool _shouldBuildListView(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
      var tripMetadataUpdatedState = currentState as UpdatedTripEntity;
      if (tripMetadataUpdatedState.dataState == DataState.delete ||
          tripMetadataUpdatedState.dataState == DataState.create) {
        return true;
      }
    }
    return false;
  }
}

class _TripMetadataGridItem extends StatelessWidget {
  final String tripId;

  _TripMetadataGridItem({required this.tripId});

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<TripMetadataFacade>(
      widgetBuilder: (context) {
        var tripMetaDataFacade = context
            .tripRepository.tripMetadataCollection.collectionItems
            .firstWhere((element) => element.id == tripId);
        var subTitle =
            '${tripMetaDataFacade.startDate!.dayDateMonthFormat} to ${tripMetaDataFacade.endDate!.dayDateMonthFormat}';
        var currentThumbnail = Assets.images.tripThumbnails.values.firstWhere(
            (element) =>
                element.keyName.split('/').last.split('.').first ==
                tripMetaDataFacade.thumbnailTag);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              context.go(AppRoutes.tripEditorPath(tripMetaDataFacade.id!));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    currentThumbnail.image(fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: ThumbnailPicker(
                          tripMetaDataFacade: tripMetaDataFacade,
                          widgetContext: context),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                        ),
                        child: FittedBox(
                          child: Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .fontSize,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  shape: const StadiumBorder(),
                  shadowColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tripMetaDataFacade.name,
                            style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .fontSize,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: MenuAnchor(
                            alignmentOffset: const Offset(0, 4),
                            style: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                !context.isLightTheme
                                    ? AppColors.darkSurface
                                    : null,
                              ),
                              padding: const WidgetStatePropertyAll<
                                      EdgeInsetsGeometry>(
                                  EdgeInsets.symmetric(vertical: 6)),
                              shape:
                                  const WidgetStatePropertyAll<OutlinedBorder>(
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(15))),
                              ),
                            ),
                            builder: (context, controller, child) {
                              return IconButton(
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              );
                            },
                            menuChildren: [
                              MenuItemButton(
                                leadingIcon: const Icon(Icons.copy_rounded),
                                onPressed: () {
                                  _showCopyTripDialog(
                                      context, tripMetaDataFacade);
                                },
                                child: Text(context.localizations.copyTrip),
                              ),
                              MenuItemButton(
                                leadingIcon:
                                    const Icon(Icons.delete_outline_rounded),
                                onPressed: () {
                                  _showDeleteTripConfirmationDialog(
                                      context, tripMetaDataFacade);
                                },
                                child: Text(context.localizations.deleteTrip),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
      shouldRebuild:
          (TripMetadataFacade beforeUpdate, TripMetadataFacade afterUpdate) {
        return afterUpdate.id == tripId &&
                beforeUpdate.name != afterUpdate.name ||
            !beforeUpdate.startDate!.isOnSameDayAs(afterUpdate.startDate!) ||
            !beforeUpdate.endDate!.isOnSameDayAs(afterUpdate.endDate!) ||
            beforeUpdate.thumbnailTag != afterUpdate.thumbnailTag;
      },
    );
  }

  void _showDeleteTripConfirmationDialog(
      BuildContext pageContext, TripMetadataFacade tripMetaDataFacade) {
    PlatformDialogElements.showAlertDialog(pageContext, (context) {
      return DeleteTripDialog(
          widgetContext: pageContext, tripMetadataFacade: tripMetaDataFacade);
    });
  }

  void _showCopyTripDialog(
      BuildContext pageContext, TripMetadataFacade tripMetaDataFacade) {
    PlatformDialogElements.showGeneralDialog(pageContext, (context) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: pageContext.appDataRepository),
          RepositoryProvider.value(value: pageContext.tripRepository),
        ],
        child: BlocProvider.value(
          value: BlocProvider.of<TripManagementBloc>(pageContext),
          child: CopyTripDialog(sourceTrip: tripMetaDataFacade),
        ),
      );
    });
  }
}
