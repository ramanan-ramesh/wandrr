import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/trip_contributors_section.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/money_edit_field.dart';
import 'package:wandrr/presentation/trip/widgets/unified_trip_dialog.dart';

class CopyTripDialog extends StatefulWidget {
  final TripMetadataFacade sourceTrip;

  const CopyTripDialog({required this.sourceTrip, Key? key}) : super(key: key);

  @override
  State<CopyTripDialog> createState() => _CopyTripDialogState();
}

class _CopyTripDialogState extends State<CopyTripDialog> {
  late final TextEditingController _nameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late DateTime _newStartDate;
  late DateTime _newEndDate;
  late String _thumbnailTag;
  late Money _budget;
  late List<String> _contributors;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: 'Copy of ${widget.sourceTrip.name}');

    // Default to today for the new start date, keep original duration
    final duration =
        widget.sourceTrip.endDate!.difference(widget.sourceTrip.startDate!);
    final now = DateTime.now();
    _newStartDate = DateTime(now.year, now.month, now.day);
    _newEndDate = _newStartDate.add(duration);

    _thumbnailTag = widget.sourceTrip.thumbnailTag;
    _budget = widget.sourceTrip.budget;
    _contributors = widget.sourceTrip.contributors.toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onStartDateSelected(DateTime selectedStart) {
    setState(() {
      final duration =
          widget.sourceTrip.endDate!.difference(widget.sourceTrip.startDate!);
      _newStartDate = selectedStart;
      _newEndDate = selectedStart.add(duration);
    });
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${start.day}-${end.day} ${DateFormat.MMMM().format(start)} ${start.year}';
      } else {
        return '${DateFormat.MMMM().format(start)} ${start.day} - ${DateFormat.MMMM().format(end)} ${end.day} ${start.year}';
      }
    } else {
      return '${DateFormat.yMd().format(start)} - ${DateFormat.yMd().format(end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedTripDialog(
      title: context.localizations.copyTripTitle,
      icon: const Icon(Icons.copy_all_rounded),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.localizations.tripName,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.localizations.titleCannotBeEmpty;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(context.localizations.chooseStartDate,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat.yMd().format(_newStartDate)),
              onPressed: () async {
                // Allow choosing any future date
                final minDate = DateTime.now();
                final maxDate = DateTime(minDate.year + 10);
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _newStartDate.isBefore(minDate) ? minDate : _newStartDate,
                  firstDate: minDate,
                  lastDate: maxDate,
                );
                if (picked != null) {
                  _onStartDateSelected(picked);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                context.localizations.tripDatesShifted(
                  _formatDateRange(
                    widget.sourceTrip.startDate!,
                    widget.sourceTrip.endDate!,
                  ),
                  _formatDateRange(_newStartDate, _newEndDate),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
            TripContributorsEditorSection(
              contributors: _contributors,
              onContributorsChanged: (contributors) {
                setState(() => _contributors = contributors.toList());
              },
            ),
            const SizedBox(height: 20),
            Text(context.localizations.budget,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final currencyInfo = context.supportedCurrencies.firstWhere(
                  (c) => c.code == _budget.currency,
                  orElse: () => context.supportedCurrencies.first);
              return PlatformMoneyEditField(
                allCurrencies: context.supportedCurrencies,
                selectedCurrency: currencyInfo,
                initialAmount: _budget.amount,
                isAmountEditable: true,
                onAmountUpdated: (updatedAmount) {
                  _budget =
                      Money(currency: _budget.currency, amount: updatedAmount);
                },
                onCurrencySelected: (selectedCurrency) {
                  _budget = Money(
                      currency: selectedCurrency.code, amount: _budget.amount);
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.addTripManagementEvent(
                CopyTrip(
                  sourceTripMetadata: widget.sourceTrip,
                  newName: _nameController.text.trim(),
                  newStartDate: _newStartDate,
                  contributors: _contributors,
                  budget: _budget,
                  thumbnailTag: _thumbnailTag,
                ),
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(context.localizations.copyTrip),
        ),
      ],
    );
  }
}
