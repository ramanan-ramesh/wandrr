import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/plan_data/plan_data.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class PlanDataListView extends StatelessWidget {
  final List<UiElement<PlanDataFacade>> _planDataUiElements = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        _updatePlanDataListOnBuild(context, state);
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == _planDataUiElements.length) {
              return _buildPlanDataCreatorButton(context);
            }
            return _PlanDataListItemViewer(
                initialPlanDataUiElement: _planDataUiElements.elementAt(index));
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_planDataUiElements.isNotEmpty) {
              return const Divider();
            } else {
              return const SizedBox.shrink();
            }
          },
          itemCount: _planDataUiElements.length + 1,
        );
      },
      buildWhen: _shouldBuildPlanDataList,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildPlanDataCreatorButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.addTripManagementEvent(
            UpdateTripEntity<PlanDataFacade>.createNewUiEntry());
      },
      label: Text(context.localizations.newPlanData),
      icon: const Icon(Icons.add_rounded),
    );
  }

  bool _shouldBuildPlanDataList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<PlanDataFacade>()) {
      var planDataUpdatedState = currentState as UpdatedTripEntity;
      if (planDataUpdatedState.dataState == DataState.delete ||
          planDataUpdatedState.dataState == DataState.create ||
          planDataUpdatedState.dataState == DataState.newUiEntry) {
        return true;
      }
    }
    return false;
  }

  void _updatePlanDataListOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.activeTrip;

    _planDataUiElements.removeWhere((x) => x.dataState != DataState.newUiEntry);

    if (state.isTripEntityUpdated<PlanDataFacade>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState
          .tripEntityModificationData.isFromExplicitAction) {
        switch (updatedTripEntityDataState) {
          case DataState.create:
            {
              _planDataUiElements.removeWhere(
                  (element) => element.dataState == DataState.newUiEntry);
              break;
            }
          case DataState.delete:
            {
              if (updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
                _planDataUiElements.removeWhere(
                    (element) => element.dataState == DataState.newUiEntry);
              }
              break;
            }
          case DataState.newUiEntry:
            {
              if (!_planDataUiElements.any(
                  (element) => element.dataState == DataState.newUiEntry)) {
                _planDataUiElements.add(UiElement(
                    element: updatedTripEntityState
                        .tripEntityModificationData.modifiedCollectionItem,
                    dataState: DataState.newUiEntry));
              }
              break;
            }
          default:
            {
              break;
            }
        }
      }
    }
    _planDataUiElements.addAll(activeTrip.planDataList.map((e) =>
        UiElement<PlanDataFacade>(element: e, dataState: DataState.none)));
  }
}

class _PlanDataListItemViewer extends StatefulWidget {
  final UiElement<PlanDataFacade> initialPlanDataUiElement;

  const _PlanDataListItemViewer({required this.initialPlanDataUiElement});

  @override
  State<_PlanDataListItemViewer> createState() =>
      _PlanDataListItemViewerState();
}

class _PlanDataListItemViewerState extends State<_PlanDataListItemViewer>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleEditingController;
  final ValueNotifier<bool> _canUpdatePlanDataNotifier = ValueNotifier(false);
  bool _isCollapsed = false;
  late UiElement<PlanDataFacade> _planDataUiElement;

  String? _errorMessage;
  bool _showErrorMessage = false;

  late AnimationController _errorAnimationController;
  late Animation<Offset> _errorAnimation;

  @override
  void initState() {
    super.initState();
    _errorAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _createErrorAnimation();
  }

  @override
  void dispose() {
    _errorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initializePlanData();
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return Column(
          children: [
            _buildPlanDataHeaderTile(),
            if (_showErrorMessage && _errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: Visibility(
                  visible: _showErrorMessage,
                  child: SlideTransition(
                    position: _errorAnimation,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            if (!_isCollapsed)
              PlanDataListItem(
                  initialPlanDataUiElement: _planDataUiElement,
                  planDataUpdated: _tryUpdatePlanData)
          ],
        );
      },
      buildWhen: _shouldBuildPlanDataListItem,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _createErrorAnimation() {
    _errorAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.1, 0), end: const Offset(-0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.1, 0), end: const Offset(0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.1, 0), end: const Offset(-0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.1, 0), end: Offset.zero),
          weight: 1),
    ]).animate(CurvedAnimation(
        parent: _errorAnimationController, curve: Curves.easeInOutCirc));
  }

  void _initializePlanData() {
    _planDataUiElement = widget.initialPlanDataUiElement.clone();
    _planDataUiElement.element =
        widget.initialPlanDataUiElement.element.clone();
    _titleEditingController =
        TextEditingController(text: _planDataUiElement.element.title);
    _canUpdatePlanDataNotifier.value = false;
  }

  ListTile _buildPlanDataHeaderTile() {
    return ListTile(
      selected: true,
      leading:
          Icon(_isCollapsed ? Icons.menu_open_rounded : Icons.list_rounded),
      title: TextField(
        controller: _titleEditingController,
        decoration: InputDecoration(
          hintText: context.localizations.addATitle,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
        ),
        onChanged: (newTitle) {
          _planDataUiElement.element.title = newTitle;
          _tryUpdatePlanData(_planDataUiElement.element);
        },
        textInputAction: TextInputAction.done,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: PlatformSubmitterFAB.conditionallyEnabled(
              icon: Icons.check_rounded,
              isEnabledInitially: false,
              callback: () {
                if (_planDataUiElement.dataState == DataState.newUiEntry) {
                  context.addTripManagementEvent(
                      UpdateTripEntity<PlanDataFacade>.create(
                          tripEntity: _planDataUiElement.element));
                } else {
                  context.addTripManagementEvent(
                      UpdateTripEntity<PlanDataFacade>.update(
                          tripEntity: _planDataUiElement.element));
                }
              },
              valueNotifier: _canUpdatePlanDataNotifier,
              callbackOnClickWhileDisabled: _tryShowError,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: PlatformSubmitterFAB(
              icon: Icons.delete_rounded,
              isEnabledInitially: true,
              callback: () {
                context.addTripManagementEvent(
                    UpdateTripEntity<PlanDataFacade>.delete(
                        tripEntity: _planDataUiElement.element));
              },
            ),
          )
        ],
      ),
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
    );
  }

  void _tryShowError() {
    var planDataValidationResult =
        _planDataUiElement.element.validate(isTitleRequired: true);
    switch (planDataValidationResult) {
      case PlanDataValidationResult.checkListItemEmpty:
        {
          _showError(context.localizations.checkListItemCannotBeEmpty);
          _canUpdatePlanDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.checkListTitleNotValid:
        {
          _showError(
              context.localizations.checkListTitleMustBeAtleast3Characters);
          _canUpdatePlanDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.noNotesOrCheckListsOrPlaces:
        {
          _showError(context.localizations.noNotesOrCheckListsOrPlaces);
          _canUpdatePlanDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.noteEmpty:
        {
          _showError(context.localizations.noteCannotBeEmpty);
          _canUpdatePlanDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.titleEmpty:
        {
          _showError(context.localizations.titleCannotBeEmpty);
          _canUpdatePlanDataNotifier.value = false;
          break;
        }
      default:
        _canUpdatePlanDataNotifier.value = true;
    }
  }

  void _showError(String message) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_errorAnimationController.isAnimating && mounted) {
        _errorAnimationController.stop();
      }
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showErrorMessage = false;
        });
      }
    });
    setState(() {
      _errorMessage = message;
      _showErrorMessage = true;
    });
    unawaited(_errorAnimationController.repeat(reverse: true));
  }

  void _tryUpdatePlanData(PlanDataFacade newPlanData) {
    var title = _planDataUiElement.element.title;
    _planDataUiElement.element = newPlanData;
    _planDataUiElement.element.title = title;

    var planValidationResult =
        _planDataUiElement.element.validate(isTitleRequired: true);
    if (planValidationResult == PlanDataValidationResult.valid) {
      _canUpdatePlanDataNotifier.value = true;
    } else {
      _canUpdatePlanDataNotifier.value = false;
    }
  }

  bool _shouldBuildPlanDataListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<PlanDataFacade>()) {
      var planDataUpdatedState = currentState as UpdatedTripEntity;
      if (planDataUpdatedState.dataState == DataState.update &&
          _planDataUiElement.element.id ==
              planDataUpdatedState
                  .tripEntityModificationData.modifiedCollectionItem.id) {
        _planDataUiElement.element = planDataUpdatedState
            .tripEntityModificationData.modifiedCollectionItem;
        _planDataUiElement.dataState = DataState.none;
        return true;
      }
    }
    return false;
  }
}
