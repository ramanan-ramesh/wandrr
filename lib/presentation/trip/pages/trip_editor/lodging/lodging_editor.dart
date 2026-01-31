import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_resolution_subpage.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';
import 'package:wandrr/presentation/trip/widgets/stay_date_time_range_editor.dart';

import 'stay_details.dart';

/// Enum to track which view is being shown
enum LodgingEditorView { editor, conflictResolution }

class LodgingEditor extends StatefulWidget {
  final LodgingFacade lodging;
  final void Function() onLodgingUpdated;

  /// Notifier to track if FAB should be enabled (conflicts acknowledged)
  final ValueNotifier<bool>? validityNotifier;

  const LodgingEditor({
    required this.lodging,
    required this.onLodgingUpdated,
    this.validityNotifier,
    super.key,
  });

  @override
  State<LodgingEditor> createState() => _LodgingEditorState();
}

class _LodgingEditorState extends State<LodgingEditor>
    with SingleTickerProviderStateMixin {
  LodgingFacade get _lodging => widget.lodging;
  TripEntityUpdatePlan? _conflictPlan;
  LodgingEditorView _currentView = LodgingEditorView.editor;

  bool get _isNewEntity => _lodging.id == null || _lodging.id!.isEmpty;

  bool get _hasUnacknowledgedConflicts =>
      _conflictPlan != null &&
      _conflictPlan!.hasConflicts &&
      !_conflictPlan!.isAcknowledged;

  void _detectConflicts() {
    final detector = TimelineConflictDetector(tripData: context.activeTrip);
    final plan = detector.detectStayConflicts(
      stay: _lodging,
      isNewEntity: _isNewEntity,
    );
    setState(() {
      _conflictPlan = plan;
      _updateValidity();
    });
  }

  void _updateValidity() {
    if (widget.validityNotifier != null) {
      final isValid = _lodging.validate() && !_hasUnacknowledgedConflicts;
      widget.validityNotifier!.value = isValid;
    }
  }

  void _switchToConflictResolution() {
    setState(() {
      _currentView = LodgingEditorView.conflictResolution;
    });
  }

  void _switchToEditor() {
    setState(() {
      _currentView = LodgingEditorView.editor;
    });
  }

  void _onConflictsResolved() {
    setState(() {
      _currentView = LodgingEditorView.editor;
      _updateValidity();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == LodgingEditorView.conflictResolution &&
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
    final tripMetadata = context.activeTrip.tripMetadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StayDetails(
          lodging: _lodging,
          onLocationUpdated: widget.onLodgingUpdated,
        ),
        if (_hasUnacknowledgedConflicts) _buildConflictWarningBanner(context),
        _buildDatesSection(context, tripMetadata),
        _buildConfirmationSection(context),
        _buildNotesSection(context),
        _buildPaymentDetailsSection(context),
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

  Widget _buildDatesSection(BuildContext context, dynamic tripMetadata) {
    return EditorTheme.createSection(
      context: context,
      child: StayDateTimeRangeEditor(
        checkinDateTime: _lodging.checkinDateTime,
        checkoutDateTime: _lodging.checkoutDateTime,
        tripStartDate: tripMetadata.startDate!,
        tripEndDate: tripMetadata.endDate!,
        location: _lodging.location,
        onCheckinChanged: (newDateTime) {
          setState(() {
            _lodging.checkinDateTime = newDateTime;
          });
          widget.onLodgingUpdated();
          _detectConflictsIfBothDatesSet();
        },
        onCheckoutChanged: (newDateTime) {
          setState(() {
            _lodging.checkoutDateTime = newDateTime;
          });
          widget.onLodgingUpdated();
          _detectConflictsIfBothDatesSet();
        },
      ),
    );
  }

  void _detectConflictsIfBothDatesSet() {
    if (_lodging.checkinDateTime != null && _lodging.checkoutDateTime != null) {
      _detectConflicts();
    }
  }

  Widget _buildConfirmationSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: TextFormField(
        decoration: EditorTheme.createTextFieldDecoration(
          labelText: '${context.localizations.confirmation} ID',
          prefixIcon: Icons.tag,
        ),
        initialValue: _lodging.confirmationId,
        textInputAction: TextInputAction.next,
        onChanged: (confirmationId) {
          _lodging.confirmationId = confirmationId;
          widget.onLodgingUpdated();
        },
      ),
    );
  }

  Widget _buildPaymentDetailsSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.account_balance_wallet,
            title: context.localizations.expenses,
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
          const SizedBox(height: 12),
          ExpenditureEditTile(
            expenseFacade: _lodging.expense,
            isEditable: true,
            callback: (paidBy, splitBy, totalExpense) {
              _lodging.expense.paidBy = Map.from(paidBy);
              _lodging.expense.splitBy = List.from(splitBy);
              _lodging.expense.currency = totalExpense.currency;
              widget.onLodgingUpdated();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: _buildNotesField(context),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    var note = Note(_lodging.notes ?? '');
    return NoteEditor(
        note: note,
        onChanged: () {
          _lodging.notes = note.text;
          widget.onLodgingUpdated();
        });
  }
}
