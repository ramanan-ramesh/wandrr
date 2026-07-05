import 'package:flutter/material.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_common_controls.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';

class PrintFormContent extends StatelessWidget {
  final bool isLargeScreen;
  final bool transitsReady;
  final bool controlsEnabled;
  final TextEditingController titleController;
  final bool includeChecklist;
  final bool includeExpenses;
  final bool includeSights;
  final bool includeNotes;
  final bool checklistEnabled;
  final bool expensesEnabled;
  final bool sightsEnabled;
  final bool notesEnabled;
  final bool includeInterCityTransit;
  final bool includeIntraCityTransit;
  final ValueChanged<bool> onIncludeChecklistChanged;
  final ValueChanged<bool> onIncludeExpensesChanged;
  final ValueChanged<bool> onIncludeSightsChanged;
  final ValueChanged<bool> onIncludeNotesChanged;
  final ValueChanged<bool> onIncludeInterCityTransitChanged;
  final ValueChanged<bool> onIncludeIntraCityTransitChanged;
  final Widget transitContent;
  final Widget transitLoadingContent;

  const PrintFormContent({
    required this.isLargeScreen,
    required this.transitsReady,
    required this.controlsEnabled,
    required this.titleController,
    required this.includeChecklist,
    required this.includeExpenses,
    required this.includeSights,
    required this.includeNotes,
    required this.checklistEnabled,
    required this.expensesEnabled,
    required this.sightsEnabled,
    required this.notesEnabled,
    required this.includeInterCityTransit,
    required this.includeIntraCityTransit,
    required this.onIncludeChecklistChanged,
    required this.onIncludeExpensesChanged,
    required this.onIncludeSightsChanged,
    required this.onIncludeNotesChanged,
    required this.onIncludeInterCityTransitChanged,
    required this.onIncludeIntraCityTransitChanged,
    required this.transitContent,
    required this.transitLoadingContent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: PrintStaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              enabled: controlsEnabled,
              controller: titleController,
              scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
              decoration: InputDecoration(labelText: l10n.documentTitle),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.sectionsToInclude,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PrintSectionChip(
                  icon: Icons.checklist_rounded,
                  label: l10n.checklists,
                  selected: includeChecklist,
                  enabled: controlsEnabled && checklistEnabled,
                  onSelected: onIncludeChecklistChanged,
                ),
                PrintSectionChip(
                  icon: Icons.payments_rounded,
                  label: l10n.expenses,
                  selected: includeExpenses,
                  enabled: controlsEnabled && expensesEnabled,
                  onSelected: onIncludeExpensesChanged,
                ),
                PrintSectionChip(
                  icon: Icons.place_rounded,
                  label: l10n.sightsPlaces,
                  selected: includeSights,
                  enabled: controlsEnabled && sightsEnabled,
                  onSelected: onIncludeSightsChanged,
                ),
                PrintSectionChip(
                  icon: Icons.note_rounded,
                  label: l10n.notes,
                  selected: includeNotes,
                  enabled: controlsEnabled && notesEnabled,
                  onSelected: onIncludeNotesChanged,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.transitOptions,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PrintCompactSwitch(
                    icon: Icons.connecting_airports_rounded,
                    label: l10n.includeInterCityTransit,
                    value: includeInterCityTransit,
                    enabled: controlsEnabled,
                    onChanged: onIncludeInterCityTransitChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrintCompactSwitch(
                    icon: Icons.directions_bus_rounded,
                    label: l10n.includeIntraCityTransit,
                    value: includeIntraCityTransit,
                    enabled: controlsEnabled,
                    onChanged: onIncludeIntraCityTransitChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: DefaultTextStyle.merge(
                key: ValueKey(transitsReady),
                style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant) ??
                    const TextStyle(),
                child: transitsReady ? transitContent : transitLoadingContent,
              ),
            ),
            if (isLargeScreen) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class PrintTransitLoadingList extends StatelessWidget {
  final bool isLargeScreen;

  const PrintTransitLoadingList({
    required this.isLargeScreen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget shimmer(double height, {double? width}) => ShimmerPlaceholder(
          width: width ?? double.infinity,
          height: height,
          borderRadius: BorderRadius.circular(12),
        );

    if (isLargeScreen) {
      return SizedBox(
        key: const ValueKey('printTransitLoadingLarge'),
        height: 320,
        child: Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        shimmer(56),
                        const SizedBox(height: 8),
                        shimmer(56),
                        const SizedBox(height: 8),
                        shimmer(56),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        shimmer(56),
                        const SizedBox(height: 8),
                        shimmer(56),
                        const SizedBox(height: 8),
                        shimmer(56),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('printTransitLoadingSmall'),
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        shimmer(64),
        const SizedBox(height: 8),
        shimmer(64),
      ],
    );
  }
}
