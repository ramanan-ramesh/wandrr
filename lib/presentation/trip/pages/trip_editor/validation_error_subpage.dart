import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class ValidationErrorSubpage<T extends TripEntity<Enum>>
    extends StatelessWidget {
  final VoidCallback onBackPressed;
  final Iterable<Enum> errors;

  const ValidationErrorSubpage({
    required this.onBackPressed,
    required this.errors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ValidationErrorHeader(
          isLightTheme: isLightTheme,
          onBackPressed: onBackPressed,
        ),
        const SizedBox(height: 12),
        _ValidationErrorStatusBar(
          isLightTheme: isLightTheme,
          errorCount: errors.length,
        ),
        const SizedBox(height: 16),
        if (errors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No validation errors.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isLightTheme
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: errors.length,
            itemBuilder: (context, index) {
              return _ValidationErrorItem(
                isLightTheme: isLightTheme,
                error: errors.elementAt(index),
              );
            },
          ),
      ],
    );
  }
}

class _ValidationErrorHeader extends StatelessWidget {
  final bool isLightTheme;
  final VoidCallback onBackPressed;

  const _ValidationErrorHeader({
    required this.isLightTheme,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBackPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLightTheme
                ? [
                    AppColors.error.withValues(alpha: 0.08),
                    AppColors.error.withValues(alpha: 0.1),
                  ]
                : [
                    AppColors.errorLight.withValues(alpha: 0.15),
                    AppColors.errorLight.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLightTheme
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.errorLight.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: isLightTheme ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Back to Editor',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isLightTheme ? AppColors.error : AppColors.errorLight,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationErrorStatusBar extends StatelessWidget {
  final bool isLightTheme;
  final int errorCount;

  const _ValidationErrorStatusBar({
    required this.isLightTheme,
    required this.errorCount,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isLightTheme ? AppColors.error : AppColors.errorLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorCount == 1 ? '1 error found' : '$errorCount errors found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationErrorItem extends StatelessWidget {
  final bool isLightTheme;
  final Enum error;

  const _ValidationErrorItem({
    required this.isLightTheme,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final title = _getErrorTitle(error);
    final description = _getErrorDescription(error);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.white : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cancel_rounded,
            color: isLightTheme ? AppColors.error : AppColors.errorLight,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme ? Colors.black87 : Colors.white,
                      ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorTitle(Enum error) {
    return switch (error) {
      // Transit
      TransitValidationResult.missingDepartureLocation =>
        'Departure location missing',
      TransitValidationResult.missingArrivalLocation =>
        'Arrival location missing',
      TransitValidationResult.missingDepartureTime => 'Departure time not set',
      TransitValidationResult.missingArrivalTime => 'Arrival time not set',
      TransitValidationResult.invalidTimeSequence => 'Arrival before departure',
      TransitValidationResult.invalidFlightOperator =>
        'Invalid carrier / operator',
      TransitValidationResult.expenseInvalid => 'Expense details invalid',
      TransitValidationResult.valid => 'Valid',
      // Journey
      JourneyValidationResult.legHasErrors => 'One or more legs have errors',
      JourneyValidationResult.sequenceViolation => 'Legs overlap in time',
      // Lodging
      LodgingValidationResult.missingLocation => 'Property location missing',
      LodgingValidationResult.missingCheckinTime =>
        'Check-in date/time not set',
      LodgingValidationResult.missingCheckoutTime =>
        'Check-out date/time not set',
      LodgingValidationResult.invalidTimeSequence =>
        'Check-out before check-in',
      LodgingValidationResult.expenseInvalid => 'Expense details invalid',
      LodgingValidationResult.valid => 'Valid',
      // Itinerary plan data
      ItineraryPlanDataValidationResult.sightInvalid => 'A place is incomplete',
      ItineraryPlanDataValidationResult.noteEmpty => 'A note is empty',
      ItineraryPlanDataValidationResult.checkListTitleNotValid =>
        'Checklist title too short',
      ItineraryPlanDataValidationResult.checkListItemEmpty =>
        'A checklist item is empty',
      ItineraryPlanDataValidationResult.valid => 'Valid',
      // Sight
      SightValidationResult.missingName => 'Place name missing',
      SightValidationResult.missingLocation => 'Place location not set',
      SightValidationResult.missingTime => 'Visit time not set',
      SightValidationResult.expenseInvalid => 'Expense details invalid',
      SightValidationResult.valid => 'Valid',
      // Checklist
      CheckListValidationResult.missingTitle => 'Checklist title missing',
      CheckListValidationResult.itemsEmpty => 'Checklist has no items',
      CheckListValidationResult.itemEmpty => 'A checklist item is empty',
      CheckListValidationResult.valid => 'Valid',
      // Trip metadata
      TripMetadataValidationResult.missingTitle => 'Trip name missing',
      TripMetadataValidationResult.missingStartDate => 'Start date not set',
      TripMetadataValidationResult.missingEndDate => 'End date not set',
      TripMetadataValidationResult.invalidDateRange =>
        'End date is before start date',
      TripMetadataValidationResult.valid => 'Valid',
      // Expense
      ExpenseValidationResult.invalidAmount => 'Expense amount is invalid',
      ExpenseValidationResult.invalidCurrency => 'Currency not selected',
      ExpenseValidationResult.invalidSplit => 'Expense split is incomplete',
      ExpenseValidationResult.valid => 'Valid',
      // Itinerary
      ItineraryValidationResult.planDataInvalid => 'Day plan has errors',
      ItineraryValidationResult.duplicateLodging =>
        'Duplicate stay on the same day',
      ItineraryValidationResult.valid => 'Valid',
      // Fallback for any future enum values
      _ => error.name
          .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m[1]}')
          .trimLeft()
          .replaceFirst(error.name[0], error.name[0].toUpperCase()),
    };
  }

  String _getErrorDescription(Enum error) {
    return switch (error) {
      // Transit
      TransitValidationResult.missingDepartureLocation =>
        'Select where this leg departs from.',
      TransitValidationResult.missingArrivalLocation =>
        'Select where this leg arrives.',
      TransitValidationResult.missingDepartureTime =>
        'Set the departure date and time.',
      TransitValidationResult.missingArrivalTime =>
        'Set the arrival date and time.',
      TransitValidationResult.invalidTimeSequence =>
        'The arrival time must be after the departure time.',
      TransitValidationResult.invalidFlightOperator =>
        'Enter a valid airline or carrier name.',
      TransitValidationResult.expenseInvalid =>
        'Check the amount, currency, and who paid.',
      // Journey
      JourneyValidationResult.legHasErrors =>
        'Fix the highlighted legs before saving.',
      JourneyValidationResult.sequenceViolation =>
        'A leg departs before the previous leg has arrived.',
      // Lodging
      LodgingValidationResult.missingLocation =>
        'Search for and select the property location.',
      LodgingValidationResult.missingCheckinTime =>
        'Set the check-in date and time.',
      LodgingValidationResult.missingCheckoutTime =>
        'Set the check-out date and time.',
      LodgingValidationResult.invalidTimeSequence =>
        'The check-out time must be after the check-in time.',
      LodgingValidationResult.expenseInvalid =>
        'Check the amount, currency, and who paid.',
      // Itinerary plan data
      ItineraryPlanDataValidationResult.sightInvalid =>
        'Fill in the name and location for every place.',
      ItineraryPlanDataValidationResult.noteEmpty =>
        'Remove or fill in the empty note.',
      ItineraryPlanDataValidationResult.checkListTitleNotValid =>
        'The checklist title must be at least 3 characters.',
      ItineraryPlanDataValidationResult.checkListItemEmpty =>
        'Remove or fill in every empty checklist item.',
      // Sight
      SightValidationResult.missingName => 'Enter a name for this place.',
      SightValidationResult.missingLocation =>
        'Search for and select a location for this place.',
      SightValidationResult.missingTime => 'Set a visit time for this place.',
      SightValidationResult.expenseInvalid =>
        'Check the amount, currency, and who paid.',
      // Checklist
      CheckListValidationResult.missingTitle =>
        'Enter a title for this checklist (minimum 3 characters).',
      CheckListValidationResult.itemsEmpty =>
        'Add at least one item to the checklist.',
      CheckListValidationResult.itemEmpty =>
        'Remove or fill in every empty checklist item.',
      // Trip metadata
      TripMetadataValidationResult.missingTitle =>
        'Enter a name for your trip.',
      TripMetadataValidationResult.missingStartDate =>
        'Set the trip start date.',
      TripMetadataValidationResult.missingEndDate => 'Set the trip end date.',
      TripMetadataValidationResult.invalidDateRange =>
        'The end date must be on or after the start date.',
      // Expense
      ExpenseValidationResult.invalidAmount => 'Enter a positive amount.',
      ExpenseValidationResult.invalidCurrency =>
        'Choose a currency for this expense.',
      ExpenseValidationResult.invalidSplit =>
        'Make sure the expense is assigned to at least one person.',
      // Itinerary
      ItineraryValidationResult.planDataInvalid =>
        'Fix the errors in the day plan before saving.',
      ItineraryValidationResult.duplicateLodging =>
        'Only one stay can be active on the same day.',
      // Valid and fallback — no description needed
      _ => '',
    };
  }
}
