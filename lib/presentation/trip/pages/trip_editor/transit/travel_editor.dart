import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_resolution_subpage.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

import 'journey_point_editor.dart';
import 'transit_operator_editor_section.dart';
import 'transit_option_picker.dart';

/// Enum to track which view is being shown
enum TravelEditorView { editor, conflictResolution }

class TravelEditor extends StatefulWidget {
  final TransitFacade transitFacade;
  final VoidCallback onTransitUpdated;

  /// Notifier to track if FAB should be enabled (conflicts acknowledged)
  final ValueNotifier<bool>? validityNotifier;

  const TravelEditor({
    required this.transitFacade,
    required this.onTransitUpdated,
    this.validityNotifier,
    super.key,
  });

  @override
  State<TravelEditor> createState() => _TravelEditorState();
}

class _TravelEditorState extends State<TravelEditor>
    with SingleTickerProviderStateMixin {
  TransitFacade get _transitFacade => widget.transitFacade;
  TripEntityUpdatePlan? _conflictPlan;
  TravelEditorView _currentView = TravelEditorView.editor;

  bool get _isNewEntity =>
      _transitFacade.id == null || _transitFacade.id!.isEmpty;

  bool get _hasUnacknowledgedConflicts =>
      _conflictPlan != null &&
      _conflictPlan!.hasConflicts &&
      !_conflictPlan!.isAcknowledged;

  @override
  void didUpdateWidget(covariant TravelEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitFacade != _transitFacade) {
      setState(() {});
    }
  }

  void _detectConflicts() {
    final detector = TimelineConflictDetector(tripData: context.activeTrip);
    final plan = detector.detectTransitConflicts(
      transit: _transitFacade,
      isNewEntity: _isNewEntity,
    );
    setState(() {
      _conflictPlan = plan;
      _updateValidity();
    });
  }

  void _updateValidity() {
    if (widget.validityNotifier != null) {
      // FAB should be disabled if there are unacknowledged conflicts
      final isValid = _transitFacade.validate() && !_hasUnacknowledgedConflicts;
      widget.validityNotifier!.value = isValid;
    }
  }

  void _switchToConflictResolution() {
    setState(() {
      _currentView = TravelEditorView.conflictResolution;
    });
  }

  void _switchToEditor() {
    setState(() {
      _currentView = TravelEditorView.editor;
    });
  }

  void _onConflictsResolved() {
    setState(() {
      _currentView = TravelEditorView.editor;
      _updateValidity();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == TravelEditorView.conflictResolution &&
        _conflictPlan != null) {
      return ConflictResolutionSubpage(
        conflictPlan: _conflictPlan!,
        onBackPressed: _switchToEditor,
        onConflictsResolved: _onConflictsResolved,
      );
    }

    return _buildEditorView(context);
  }

  Widget _buildEditorView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransitTypeBadge(),
        if (_hasUnacknowledgedConflicts) _buildConflictWarningBanner(context),
        if (_needsPriorBooking) _buildOperatorSection(),
        _JourneySection(
          transitFacade: _transitFacade,
          onLocationChanged: _updateLocation,
          onDateTimeChanged: _updateDateTimeAndDetectConflicts,
        ),
        if (_needsPriorBooking) _buildConfirmationIdSection(),
        _buildNotesSection(),
        _createPaymentDetailsSection(context),
      ],
    );
  }

  Widget _buildConflictWarningBanner(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLightTheme
              ? [
                  AppColors.warning.withValues(alpha: 0.15),
                  AppColors.error.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.warning.withValues(alpha: 0.3),
                  AppColors.errorLight.withValues(alpha: 0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.warningLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_conflictPlan!.totalConflicts} Conflict${_conflictPlan!.totalConflicts > 1 ? 's' : ''} Detected',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.warning
                            : AppColors.warningLight,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review and resolve before saving',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _switchToConflictResolution,
            style: FilledButton.styleFrom(
              backgroundColor: isLightTheme
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.warningLight.withValues(alpha: 0.2),
              foregroundColor:
                  isLightTheme ? AppColors.warning : AppColors.warningLight,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Widget _createPaymentDetailsSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Payment Details',
            iconColor: Theme.of(context).brightness == Brightness.light
                ? AppColors.warning
                : AppColors.warningLight,
          ),
          const SizedBox(height: 12),
          ExpenditureEditTile(
            expenseFacade: _transitFacade.expense,
            isEditable: true,
            callback: _handleExpenseUpdated,
          ),
        ],
      ),
    );
  }

  bool get _needsPriorBooking {
    final option = _transitFacade.transitOption;
    return option != TransitOption.walk &&
        option != TransitOption.vehicle &&
        option != TransitOption.rentedVehicle;
  }

  Widget _buildTransitTypeBadge() {
    return Container(
      decoration: _buildBadgeDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TransitOptionPicker(
        options: context.activeTrip.transitOptionMetadatas,
        initialTransitOption: _transitFacade.transitOption,
        onChanged: _handleTransitOptionChanged,
      ),
    );
  }

  BoxDecoration _buildBadgeDecoration() {
    var isLightTheme = context.isLightTheme;
    final isBigLayout = context.isBigLayout;
    final cardBorderRadius = EditorTheme.getCardBorderRadius(isBigLayout);
    return BoxDecoration(
      gradient: EditorTheme.createPrimaryGradient(isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [EditorTheme.createBadgeShadow(isLightTheme)],
    );
  }

  void _handleTransitOptionChanged(TransitOption newOption) {
    setState(() {
      _clearOperatorIfNotNeeded(newOption);
      _clearFlightDataIfSwitchingFromFlight(newOption);
      _transitFacade.transitOption = newOption;
    });
    widget.onTransitUpdated();
  }

  void _clearOperatorIfNotNeeded(TransitOption option) {
    final optionsWithoutOperator = [
      TransitOption.walk,
      TransitOption.rentedVehicle,
      TransitOption.vehicle,
    ];

    if (optionsWithoutOperator.contains(option)) {
      _transitFacade.operator = null;
    }
  }

  void _clearFlightDataIfSwitchingFromFlight(TransitOption newOption) {
    final isChangingToFlight = newOption == TransitOption.flight &&
        _transitFacade.transitOption != TransitOption.flight;
    final isChangingFromFlight =
        _transitFacade.transitOption == TransitOption.flight &&
            newOption != TransitOption.flight;

    if (isChangingToFlight || isChangingFromFlight) {
      _transitFacade.operator = null;
      _transitFacade.arrivalLocation = null;
      _transitFacade.departureLocation = null;
    }
  }

  Widget _buildOperatorSection() {
    return TransitOperatorEditorSection(
      transitOption: _transitFacade.transitOption,
      initialOperator: _transitFacade.operator,
      onOperatorChanged: _handleOperatorChanged,
    );
  }

  Widget _buildConfirmationIdSection() {
    return EditorTheme.createSection(
      context: context,
      child: _buildConfirmationField(context),
    );
  }

  Widget _buildConfirmationField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: '${context.localizations.confirmation} #',
        prefixIcon: const Icon(Icons.confirmation_number_rounded),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      initialValue: _transitFacade.confirmationId,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _transitFacade.confirmationId = value;
        widget.onTransitUpdated();
      },
    );
  }

  Widget _buildNotesSection() {
    var note = Note(_transitFacade.notes ?? '');
    return EditorTheme.createSection(
      context: context,
      child: NoteEditor(
          note: note,
          onChanged: () {
            _transitFacade.notes = note.text;
            widget.onTransitUpdated();
          }),
    );
  }

  void _handleExpenseUpdated(
    Map<String, double> paidBy,
    List<String> splitBy,
    Money totalExpense,
  ) {
    _transitFacade.expense.paidBy = Map.from(paidBy);
    _transitFacade.expense.splitBy = List.from(splitBy);
    _transitFacade.expense.currency = totalExpense.currency;
    widget.onTransitUpdated();
  }

  void _handleOperatorChanged(String? newOperator) {
    _transitFacade.operator = newOperator;
    widget.onTransitUpdated();
  }

  void _updateLocation(bool isArrival, LocationFacade? newLocation) {
    setState(() {
      if (isArrival) {
        _transitFacade.arrivalLocation = newLocation;
      } else {
        _transitFacade.departureLocation = newLocation;
      }
    });
    widget.onTransitUpdated();
  }

  void _updateDateTimeAndDetectConflicts(
      bool isArrival, DateTime updatedDateTime) {
    setState(() {
      if (isArrival) {
        _transitFacade.arrivalDateTime = updatedDateTime;
      } else {
        _transitFacade.departureDateTime = updatedDateTime;
      }
    });
    widget.onTransitUpdated();

    // Detect conflicts after both departure and arrival are set
    if (_transitFacade.departureDateTime != null &&
        _transitFacade.arrivalDateTime != null) {
      _detectConflicts();
    }
  }
}

class _JourneySection extends StatelessWidget {
  final TransitFacade transitFacade;
  final void Function(bool isArrival, LocationFacade? newLocation)
      onLocationChanged;
  final void Function(bool isArrival, DateTime updatedDateTime)
      onDateTimeChanged;

  const _JourneySection({
    Key? key,
    required this.transitFacade,
    required this.onLocationChanged,
    required this.onDateTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (context.isBigLayout) {
      return Row(
        children: [
          Expanded(child: _buildDeparturePoint(context)),
          _buildJourneyConnector(context),
          Expanded(child: _buildArrivalPoint(context)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeparturePoint(context),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildJourneyConnector(context),
          ),
        ),
        _buildArrivalPoint(context),
      ],
    );
  }

  Widget _buildDeparturePoint(BuildContext context) {
    return _buildJourneyPoint(
      context,
      isDeparture: true,
    );
  }

  Widget _buildArrivalPoint(BuildContext context) {
    return _buildJourneyPoint(
      context,
      isDeparture: false,
    );
  }

  Widget _buildJourneyPoint(
    BuildContext context, {
    required bool isDeparture,
  }) {
    return JourneyPointEditor(
      transitFacade: transitFacade,
      isDeparture: isDeparture,
      onLocationChanged: (newLocation) {
        onLocationChanged(!isDeparture, newLocation);
      },
      onDateTimeChanged: (updatedDateTime) =>
          onDateTimeChanged(!isDeparture, updatedDateTime),
    );
  }

  Widget _buildJourneyConnector(BuildContext context) {
    final connectorColor = context.isLightTheme
        ? AppColors.brandPrimary
        : AppColors.brandPrimaryLight;
    return Icon(
        context.isBigLayout ? Icons.arrow_forward : Icons.arrow_downward,
        color: connectorColor,
        size: 32);
  }
}
