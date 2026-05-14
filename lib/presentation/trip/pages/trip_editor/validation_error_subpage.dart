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
      TransitValidationError.missingDepartureLocation =>
        'Departure location missing',
      TransitValidationError.missingArrivalLocation =>
        'Arrival location missing',
      TransitValidationError.missingDepartureTime => 'Departure time not set',
      TransitValidationError.missingArrivalTime => 'Arrival time not set',
      TransitValidationError.invalidTimeSequence => 'Arrival before departure',
      TransitValidationError.invalidFlightOperator =>
        'Invalid carrier / operator',
      TransitValidationError.expenseInvalid => 'Expense details invalid',
      // Journey
      JourneyValidationError.legHasErrors => 'One or more legs have errors',
      JourneyValidationError.sequenceViolation => 'Legs overlap in time',
      // Lodging
      LodgingValidationError.missingLocation => 'Property location missing',
      LodgingValidationError.missingCheckinTime => 'Check-in date/time not set',
      LodgingValidationError.missingCheckoutTime =>
        'Check-out date/time not set',
      LodgingValidationError.invalidTimeSequence => 'Check-out before check-in',
      LodgingValidationError.expenseInvalid => 'Expense details invalid',
      // Itinerary plan data
      ItineraryPlanDataValidationError.sightInvalid => 'A place is incomplete',
      ItineraryPlanDataValidationError.sightsVisitTimesOverlap =>
        'Two places share the same visit time',
      ItineraryPlanDataValidationError.noteEmpty => 'A note is empty',
      ItineraryPlanDataValidationError.checkListTitleNotValid =>
        'Checklist title too short',
      ItineraryPlanDataValidationError.checkListItemEmpty =>
        'A checklist item is empty',
      // Sight
      SightValidationError.missingName => 'Place name missing',
      SightValidationError.missingLocation => 'Place location not set',
      SightValidationError.missingTime => 'Visit time not set',
      SightValidationError.expenseInvalid => 'Expense details invalid',
      // Checklist
      CheckListValidationError.missingTitle => 'Checklist title missing',
      CheckListValidationError.itemsEmpty => 'Checklist has no items',
      CheckListValidationError.itemEmpty => 'A checklist item is empty',
      // Trip metadata
      TripMetadataValidationError.missingTitle => 'Trip name missing',
      TripMetadataValidationError.missingStartDate => 'Start date not set',
      TripMetadataValidationError.missingEndDate => 'End date not set',
      TripMetadataValidationError.invalidDateRange =>
        'End date is before start date',
      // Expense
      ExpenseValidationError.invalidAmount => 'Expense amount is invalid',
      ExpenseValidationError.invalidCurrency => 'Currency not selected',
      ExpenseValidationError.invalidSplit => 'Expense split is incomplete',
      // Itinerary
      ItineraryValidationError.planDataInvalid => 'Day plan has errors',
      ItineraryValidationError.duplicateLodging =>
        'Duplicate stay on the same day',
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
      TransitValidationError.missingDepartureLocation =>
        'Select where this leg departs from.',
      TransitValidationError.missingArrivalLocation =>
        'Select where this leg arrives.',
      TransitValidationError.missingDepartureTime =>
        'Set the departure date and time.',
      TransitValidationError.missingArrivalTime =>
        'Set the arrival date and time.',
      TransitValidationError.invalidTimeSequence =>
        'The arrival time must be after the departure time.',
      TransitValidationError.invalidFlightOperator =>
        'Enter a valid airline or carrier name.',
      TransitValidationError.expenseInvalid =>
        'Check the amount, currency, and who paid.',
      // Journey
      JourneyValidationError.legHasErrors =>
        'Fix the highlighted legs before saving.',
      JourneyValidationError.sequenceViolation =>
        'A leg departs before the previous leg has arrived.',
      // Lodging
      LodgingValidationError.missingLocation =>
        'Search for and select the property location.',
      LodgingValidationError.missingCheckinTime =>
        'Set the check-in date and time.',
      LodgingValidationError.missingCheckoutTime =>
        'Set the check-out date and time.',
      LodgingValidationError.invalidTimeSequence =>
        'The check-out time must be after the check-in time.',
      LodgingValidationError.expenseInvalid =>
        'Check the amount, currency, and who paid.',
      // Itinerary plan data
      ItineraryPlanDataValidationError.sightInvalid =>
        'Fill in the name and location for every place.',
      ItineraryPlanDataValidationError.sightsVisitTimesOverlap =>
        'Each place must have a unique visit time — two places cannot start at the same time.',
      ItineraryPlanDataValidationError.noteEmpty =>
        'Remove or fill in the empty note.',
      ItineraryPlanDataValidationError.checkListTitleNotValid =>
        'The checklist title must be at least 3 characters.',
      ItineraryPlanDataValidationError.checkListItemEmpty =>
        'Remove or fill in every empty checklist item.',
      // Sight
      SightValidationError.missingName => 'Enter a name for this place.',
      SightValidationError.missingLocation =>
        'Search for and select a location for this place.',
      SightValidationError.missingTime => 'Set a visit time for this place.',
      SightValidationError.expenseInvalid =>
        'Check the amount, currency, and who paid.',
      // Checklist
      CheckListValidationError.missingTitle =>
        'Enter a title for this checklist (minimum 3 characters).',
      CheckListValidationError.itemsEmpty =>
        'Add at least one item to the checklist.',
      CheckListValidationError.itemEmpty =>
        'Remove or fill in every empty checklist item.',
      // Trip metadata
      TripMetadataValidationError.missingTitle => 'Enter a name for your trip.',
      TripMetadataValidationError.missingStartDate =>
        'Set the trip start date.',
      TripMetadataValidationError.missingEndDate => 'Set the trip end date.',
      TripMetadataValidationError.invalidDateRange =>
        'The end date must be on or after the start date.',
      // Expense
      ExpenseValidationError.invalidAmount => 'Enter a positive amount.',
      ExpenseValidationError.invalidCurrency =>
        'Choose a currency for this expense.',
      ExpenseValidationError.invalidSplit =>
        'Make sure the expense is assigned to at least one person.',
      // Itinerary
      ItineraryValidationError.planDataInvalid =>
        'Fix the errors in the day plan before saving.',
      ItineraryValidationError.duplicateLodging =>
        'Only one stay can be active on the same day.',
      // Valid and fallback — no description needed
      _ => '',
    };
  }
}
