import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/asset_manager/extension.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/routing/app_routes.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';
import 'package:wandrr/presentation/trip/widgets/unified_trip_dialog.dart';

import 'thumbnail_selector.dart';

class TripCreatorDialog extends StatefulWidget {
  const TripCreatorDialog({super.key});

  @override
  State<TripCreatorDialog> createState() => _TripCreatorDialogState();
}

class _TripCreatorDialogState extends State<TripCreatorDialog>
    with SingleTickerProviderStateMixin {
  static const String _defaultCurrency = 'INR';

  late final TripMetadataFacade _currentTripMetadata;
  late final ValueNotifier<bool> _tripCreationMetadataValidityNotifier;
  late final TextEditingController _tripNameEditingController;
  late final AnimationController _staggerController;
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  final SizedBox _formElementsSpacer = const SizedBox(height: 12.0);

  @override
  void initState() {
    super.initState();
    _currentTripMetadata = TripMetadataFacade.newUiEntry(
      defaultCurrency: _defaultCurrency,
      thumbnailTag: Assets.images.tripThumbnails.roadTrip.fileName,
    );
    _tripCreationMetadataValidityNotifier = ValueNotifier(false);
    _tripNameEditingController = TextEditingController();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _tripCreationMetadataValidityNotifier.dispose();
    _tripNameEditingController.dispose();
    _staggerController.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currencyInfo = context.supportedCurrencies.firstWhere((element) {
      return element.code == _currentTripMetadata.budget.currency;
    });

    return BlocListener<TripManagementBloc, TripManagementState>(
      listenWhen: (previous, current) =>
          current is UpdatedTripEntity<TripMetadataFacade> &&
          current.dataState == DataState.create,
      listener: _handleTripCreationResult,
      child: UnifiedTripDialog(
        title: context.localizations.planTrip,
        icon: const Icon(Icons.auto_awesome_rounded),
        content: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            children: [
              _buildAnimatedItem(0, _createThumbnailPicker(context)),
              _formElementsSpacer,
              _buildAnimatedItem(
                  1,
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: _createDatePicker(),
                  )),
              _formElementsSpacer,
              _buildAnimatedItem(
                  2,
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: _createTripNameField(context),
                  )),
              _formElementsSpacer,
              _buildAnimatedItem(3, _createBudgetEditor(context, currencyInfo)),
            ],
          ),
        ),
        actions: [
          _buildCreateTripButton(context),
        ],
      ),
    );
  }

  Future<void> _handleTripCreationResult(
      BuildContext context, TripManagementState state) async {
    final createdState = state as UpdatedTripEntity<TripMetadataFacade>;
    if (!createdState.isOperationSuccess) {
      _isSubmitting.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.localizations.tripCreationFailed)),
      );
      return;
    }

    final createdTripMetadata =
        createdState.tripEntityModificationData.collectionItemChange;
    _isSubmitting.value = false;

    // Close the dialog first and let its transition fully finish playing
    // before loading/activating the trip — popping a route completes
    // immediately, well before its reverse animation actually finishes, so
    // we explicitly wait for it to avoid the two transitions overlapping.
    Navigator.of(context).pop();
    await Future.delayed(
        PlatformDialogElements.generalDialogTransitionDuration);
    if (!context.mounted) {
      return;
    }

    context.addTripManagementEvent(
      LoadTrip(tripMetadata: createdTripMetadata, isTripActivated: true),
    );
    context.go(AppRoutes.tripEditorPath(createdTripMetadata.id!));
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    const stagger = 0.16;
    const itemDuration = 0.4;
    final start = index * stagger;
    final end = start + itemDuration;

    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.6),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _createBudgetEditor(BuildContext context, CurrencyData currencyInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            context.localizations.edit_budget,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        const SizedBox(height: 4.0),
        FocusTraversalOrder(
          order: const NumericFocusOrder(3),
          child: _createBudgetEditingField(context, currencyInfo),
        ),
      ],
    );
  }

  Widget _createThumbnailPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            context.localizations.chooseTripThumbnail,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8.0),
        TripThumbnailCarouselSelector(
          selectedThumbnailTag: _currentTripMetadata.thumbnailTag,
          onChanged: (thumbnailTag) {
            _currentTripMetadata.thumbnailTag = thumbnailTag;
          },
        ),
      ],
    );
  }

  TextField _createTripNameField(BuildContext context) {
    return TextField(
      key: const Key('TripCreatorDialog_TripNameField'),
      onChanged: _updateTripName,
      textInputAction: TextInputAction.next,
      scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
      decoration: InputDecoration(
        labelText: context.localizations.tripName,
        prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      controller: _tripNameEditingController,
    );
  }

  PlatformDateRangePicker _createDatePicker() {
    return PlatformDateRangePicker(
      firstDate: DateTime.now(),
      callback: (startDate, endDate) {
        _currentTripMetadata.startDate = startDate;
        _currentTripMetadata.endDate = endDate;
        _tripCreationMetadataValidityNotifier.value =
            _currentTripMetadata.getValidationErrors().isEmpty;
      },
    );
  }

  Widget _createBudgetEditingField(
      BuildContext context, CurrencyData currencyInfo) {
    return PlatformMoneyEditField(
      textInputAction: TextInputAction.done,
      allCurrencies: context.supportedCurrencies,
      selectedCurrency: currencyInfo,
      onAmountUpdated: (updatedAmount) {
        _currentTripMetadata.budget = Money(
            currency: _currentTripMetadata.budget.currency,
            amount: updatedAmount);
      },
      onCurrencySelected: (selectedCurrency) {
        _currentTripMetadata.budget = Money(
            currency: selectedCurrency.code,
            amount: _currentTripMetadata.budget.amount);
        _tripCreationMetadataValidityNotifier.value =
            _currentTripMetadata.getValidationErrors().isEmpty;
      },
      isAmountEditable: true,
    );
  }

  void _updateTripName(String newTripName) {
    _currentTripMetadata.name = newTripName;
    _tripCreationMetadataValidityNotifier.value =
        _currentTripMetadata.getValidationErrors().isEmpty;
  }

  Widget _buildCreateTripButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSubmitting,
      builder: (context, isSubmitting, _) {
        return PlatformSubmitterFAB.conditionallyEnabled(
          key: const Key('TripCreatorDialog_SubmitButton'),
          valueNotifier: _tripCreationMetadataValidityNotifier,
          isSubmitted: isSubmitting,
          callback: () => _submitTripCreationEvent(context),
          child: const Icon(Icons.done_rounded, color: Colors.white),
        );
      },
    );
  }

  void _submitTripCreationEvent(BuildContext context) {
    _isSubmitting.value = true;
    var userName = context.activeUser!.userName;
    var tripMetadata = _currentTripMetadata.clone();
    tripMetadata.contributors = [userName];
    context.addTripManagementEvent(
      UpdateTripEntity<TripMetadataFacade>.create(tripEntity: tripMetadata),
    );
  }
}
