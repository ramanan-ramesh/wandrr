import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

import 'trip_contributors_section.dart';

const _kSectionHeaderSpacing = SizedBox(height: 12.0);

class TripDetailsEditor extends StatefulWidget {
  final TripMetadata tripMetadataFacade;
  final void Function(TripMetadata updated) onTripMetadataUpdated;

  const TripDetailsEditor({
    super.key,
    required this.tripMetadataFacade,
    required this.onTripMetadataUpdated,
  });

  @override
  State<TripDetailsEditor> createState() => _TripDetailsEditorState();
}

class _TripDetailsEditorState extends State<TripDetailsEditor>
    with TickerProviderStateMixin {
  late final TextEditingController _titleController;
  late TripMetadata _tripMetadata;

  @override
  void initState() {
    super.initState();
    _tripMetadata = widget.tripMetadataFacade;
    _titleController = TextEditingController(text: _tripMetadata.name);
  }

  @override
  void didUpdateWidget(TripDetailsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripMetadataFacade != widget.tripMetadataFacade) {
      _tripMetadata = widget.tripMetadataFacade;
      _titleController.text = _tripMetadata.name;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateMetadata(TripMetadata updated) {
    setState(() {
      _tripMetadata = updated;
    });
    widget.onTripMetadataUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleSection(context),
        _buildDatesSection(context),
        _buildBudgetSection(context),
        TripContributorsEditorSection(
          contributors: List.of(_tripMetadata.contributors),
          onContributorsChanged: (updatedContributors) {
            _updateMetadata(_tripMetadata.copyWith(
              contributors: List.of(updatedContributors),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            decoration: EditorTheme.createTextFieldDecoration(
              labelText: 'Enter trip title',
            ),
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              _updateMetadata(_tripMetadata.copyWith(name: value.trim()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.calendar_month_rounded,
            title: 'Trip Duration',
            iconColor:
                context.isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          _kSectionHeaderSpacing,
          PlatformDateRangePicker(
            startDate: _tripMetadata.startDate,
            endDate: _tripMetadata.endDate,
            callback: (newStartDate, newEndDate) {
              // Only update if we have valid dates
              if (newStartDate != null && newEndDate != null) {
                _updateMetadata(_tripMetadata.copyWith(
                  startDate: newStartDate,
                  endDate: newEndDate,
                ));
              } else {
                // Handle partial date selection by creating draft
                _updateMetadata(TripMetadata.draft(
                  id: _tripMetadata.id,
                  name: _tripMetadata.name,
                  thumbnailTag: _tripMetadata.thumbnailTag,
                  contributors: _tripMetadata.contributors,
                  budget: _tripMetadata.budget,
                  startDate: newStartDate,
                  endDate: newEndDate,
                ));
              }
            },
          ),
          if (_tripMetadata.startDate != null && _tripMetadata.endDate != null)
            _buildDurationIndicator(context),
        ],
      ),
    );
  }

  Widget _buildDurationIndicator(BuildContext context) {
    final startDate = _tripMetadata.startDate!;
    final endDate = _tripMetadata.endDate!;
    final days = endDate.difference(startDate).inDays + 1;
    final isLightTheme = context.isLightTheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.info.withValues(alpha: 0.2),
              AppColors.infoLight.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLightTheme
                ? AppColors.info.withValues(alpha: 0.3)
                : AppColors.infoLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 18,
              color: isLightTheme ? AppColors.info : AppColors.infoLight,
            ),
            const SizedBox(width: 8),
            Text(
              '$days ${days == 1 ? 'day' : 'days'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLightTheme ? AppColors.info : AppColors.infoLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final allCurrencies = context.supportedCurrencies.toList();
    final selectedCurrency = allCurrencies.firstWhere(
      (currency) => currency.code == _tripMetadata.budget.currency,
      orElse: () => allCurrencies.first,
    );
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: 'Budget',
            iconColor:
                isLightTheme ? AppColors.warning : AppColors.warningLight,
          ),
          _kSectionHeaderSpacing,
          PlatformMoneyEditField(
            selectedCurrency: selectedCurrency,
            allCurrencies: allCurrencies,
            onAmountUpdated: (updatedAmount) {
              _updateMetadata(_tripMetadata.copyWith(
                budget: Money(
                  currency: _tripMetadata.budget.currency,
                  amount: updatedAmount,
                ),
              ));
            },
            isAmountEditable: true,
            onCurrencySelected: (newCurrency) {
              _updateMetadata(_tripMetadata.copyWith(
                budget: Money(
                  currency: newCurrency.code,
                  amount: _tripMetadata.budget.amount,
                ),
              ));
            },
            initialAmount: _tripMetadata.budget.amount,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
