import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';

import 'trip_contributors_editor.dart';

class TripDetailsEditor extends StatefulWidget {
  final TripMetadataFacade tripMetadataFacade;
  final VoidCallback onTripMetadataUpdated;

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
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.tripMetadataFacade.name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleSection(context),
        _buildDatesSection(context),
        _buildBudgetSection(context),
        TripContributorsEditor(
          contributors: widget.tripMetadataFacade.contributors,
          onContributorsChanged: (updatedContributors) {
            widget.tripMetadataFacade.contributors =
                List.from(updatedContributors);
            widget.onTripMetadataUpdated();
          },
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            decoration: EditorTheme.buildTextFieldDecoration(
              labelText: 'Enter trip title',
              hintText: 'e.g., Europe 2025, Caribbean Getaway Sep 2026',
              prefixIcon: Icons.title_rounded,
            ),
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              widget.tripMetadataFacade.name = value;
              widget.onTripMetadataUpdated();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.buildSectionHeader(
            context,
            icon: Icons.calendar_month_rounded,
            title: 'Trip Duration',
            iconColor: isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          const SizedBox(height: 12),
          PlatformDateRangePicker(
            startDate: widget.tripMetadataFacade.startDate,
            endDate: widget.tripMetadataFacade.endDate,
            callback: (newStartDate, newEndDate) {
              setState(() {
                widget.tripMetadataFacade.startDate = newStartDate;
                widget.tripMetadataFacade.endDate = newEndDate;
              });
              widget.onTripMetadataUpdated();
            },
          ),
          if (widget.tripMetadataFacade.startDate != null &&
              widget.tripMetadataFacade.endDate != null)
            _buildDurationIndicator(context),
        ],
      ),
    );
  }

  Widget _buildDurationIndicator(BuildContext context) {
    final startDate = widget.tripMetadataFacade.startDate!;
    final endDate = widget.tripMetadataFacade.endDate!;
    final days = endDate.difference(startDate).inDays + 1;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

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
      (c) => c.code == widget.tripMetadataFacade.budget.currency,
      orElse: () => allCurrencies.first,
    );

    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.buildSectionHeader(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: 'Budget',
            iconColor:
                isLightTheme ? AppColors.warning : AppColors.warningLight,
          ),
          const SizedBox(height: 12),
          PlatformMoneyEditField(
            selectedCurrencyData: selectedCurrency,
            allCurrencies: allCurrencies,
            onAmountUpdatedCallback: (updatedAmount) {
              widget.tripMetadataFacade.budget = Money(
                currency: widget.tripMetadataFacade.budget.currency,
                amount: updatedAmount,
              );
              widget.onTripMetadataUpdated();
            },
            isAmountEditable: true,
            currencySelectedCallback: (newCurrency) {
              widget.tripMetadataFacade.budget = Money(
                currency: newCurrency.code,
                amount: widget.tripMetadataFacade.budget.amount,
              );
              widget.onTripMetadataUpdated();
            },
            initialAmount: widget.tripMetadataFacade.budget.amount,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
