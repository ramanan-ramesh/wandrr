import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/services/budgeting_service.dart';
import 'package:wandrr/presentation/app/routing/app_routes.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class TripEditorRoutePage extends StatefulWidget {
  final String tripId;

  const TripEditorRoutePage({required this.tripId, super.key});

  @override
  State<TripEditorRoutePage> createState() => _TripEditorRoutePageState();
}

class _TripEditorRoutePageState extends State<TripEditorRoutePage> {
  bool _hasTriedLoadingTrip = false;
  ApiServicesRepositoryFacade? _apiServicesRepository;
  BudgetingServiceFacade? _budgetingService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryLoadTrip();
  }

  @override
  void didUpdateWidget(covariant TripEditorRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId == widget.tripId) {
      return;
    }
    _hasTriedLoadingTrip = false;
    _apiServicesRepository = null;
    _budgetingService = null;
    _tryLoadTrip();
  }

  void _tryLoadTrip() {
    if (_hasTriedLoadingTrip) {
      return;
    }

    final state = context.tripManagementState;
    if (state is LoadedRepository ||
        state is NavigateToHome ||
        state is UpdatedTripEntity) {
      _loadTripById();
      return;
    }

    if (state is ActivatedTrip) {
      final activeTripId = context.tripRepository.activeTrip?.tripMetadata.id;
      if (activeTripId == widget.tripId) {
        _hasTriedLoadingTrip = true;
        _setActivatedTripDependencies(state);
      } else {
        _loadTripById();
      }
      return;
    }

    if (state is! LoadingTripManagement && state is! LoadingTrip) {
      _loadTripById();
    }
  }

  void _setActivatedTripDependencies(ActivatedTrip state) {
    final activeTripId = context.tripRepository.activeTrip?.tripMetadata.id;
    if (activeTripId != widget.tripId) {
      return;
    }
    _apiServicesRepository = state.apiServicesRepository;
    _budgetingService = state.budgetingService;
  }

  void _loadTripById() {
    _hasTriedLoadingTrip = true;
    final metadata = context.tripRepository.tripMetadataCollection.items
        .where((trip) => trip.id == widget.tripId)
        .firstOrNull;
    if (metadata == null) {
      context.go(AppRoutes.trips);
      return;
    }

    context.addTripManagementEvent(
      LoadTrip(tripMetadata: metadata, isTripActivated: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      listenWhen: (_, current) =>
          current is LoadedRepository ||
          current is NavigateToHome ||
          current is ActivatedTrip ||
          current is LoadingTrip,
      listener: (context, state) {
        if ((state is LoadedRepository || state is NavigateToHome) &&
            !_hasTriedLoadingTrip) {
          _tryLoadTrip();
          return;
        }

        if (state is ActivatedTrip) {
          setState(() => _setActivatedTripDependencies(state));
        }
      },
      builder: (context, state) {
        if (state is NavigateToHome || state is LoadedRepository) {
          _apiServicesRepository = null;
          _budgetingService = null;
          return const SizedBox.shrink();
        }

        final repos = _apiServicesRepository;
        final service = _budgetingService;
        if (repos == null || service == null) {
          return const SizedBox.shrink();
        }

        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ApiServicesRepositoryFacade>.value(value: repos),
            RepositoryProvider<BudgetingServiceFacade>.value(value: service),
          ],
          child: const TripEditorPage(),
        );
      },
    );
  }
}
