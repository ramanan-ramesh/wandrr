import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/animated_list_item.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

/// Combined viewer for Notes and Checklists for a given itinerary day.
/// Both sections appear in a single scrollable column.
class ItineraryNotesAndChecklistsViewer extends StatefulWidget {
  final DateTime day;

  const ItineraryNotesAndChecklistsViewer({
    required this.day,
    super.key,
  });

  @override
  State<ItineraryNotesAndChecklistsViewer> createState() =>
      _ItineraryNotesAndChecklistsViewerState();
}

class _ItineraryNotesAndChecklistsViewerState
    extends State<ItineraryNotesAndChecklistsViewer> {
  final Set<int> _expandedChecklists = {};

  static const double _kPadding = 16.0;
  static const double _kSectionSpacing = 20.0;

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<ItineraryPlanData>(
      shouldRebuild: (before, after) {
        final relevant = before.day.isOnSameDayAs(widget.day) ||
            after.day.isOnSameDayAs(widget.day);
        if (!relevant) return false;
        return !listEquals(before.notes, after.notes) ||
            !listEquals(before.checkLists, after.checkLists);
      },
      widgetBuilder: (context) {
        final planData = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.day)
            .planData;
        final notes = planData.notes;
        final checklists = planData.checkLists;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            _kPadding,
            _kPadding,
            _kPadding,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          children: [
            // ── Notes section ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.sticky_note_2_rounded,
              label: context.localizations.notes,
              onAdd: () => context.addTripManagementEvent(
                EditItineraryPlanData(
                  day: widget.day,
                  planDataEditorConfig:
                      CreateNewItineraryPlanDataComponentConfig(
                    planDataType: PlanDataType.note,
                    date: widget.day,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              _EmptyPlaceholder(text: context.localizations.noNotesCreated)
            else
              ...notes.asMap().entries.map((e) {
                final i = e.key;
                final note = e.value;
                final raw = note.trim();
                final title = raw.isEmpty ? 'Untitled' : raw.split('\n').first;
                final preview = raw.replaceAll('\n', ' ');
                return AnimatedListItem(
                  index: i,
                  child: _NoteCard(
                    title: title,
                    preview: preview,
                    onTap: () => context.addTripManagementEvent(
                      EditItineraryPlanData(
                        day: widget.day,
                        planDataEditorConfig:
                            UpdateItineraryPlanDataComponentConfig(
                          planDataType: PlanDataType.note,
                          index: i,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: _kSectionSpacing),

            // ── Checklists section ───────────────────────────────────────
            _SectionHeader(
              icon: Icons.checklist_rounded,
              label: context.localizations.checklists,
              onAdd: () => context.addTripManagementEvent(
                EditItineraryPlanData(
                  day: widget.day,
                  planDataEditorConfig:
                      CreateNewItineraryPlanDataComponentConfig(
                    planDataType: PlanDataType.checklist,
                    date: widget.day,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (checklists.isEmpty)
              _EmptyPlaceholder(text: context.localizations.noChecklistsCreated)
            else
              ...checklists.asMap().entries.map((e) {
                final i = e.key;
                final cl = e.value;
                final title = cl.title?.trim().isEmpty ?? true
                    ? context.localizations.untitledChecklist
                    : cl.title!.trim();
                final completed =
                    cl.items.where((item) => item.isChecked).length;
                final total = cl.items.length;
                final progress = total > 0 ? completed / total : 0.0;
                final isExpanded = _expandedChecklists.contains(i);

                return AnimatedListItem(
                  index: i,
                  child: _ChecklistCard(
                    title: title,
                    progress: progress,
                    completed: completed,
                    total: total,
                    isExpanded: isExpanded,
                    items: cl.items,
                    onToggleExpand: () => setState(() {
                      if (isExpanded) {
                        _expandedChecklists.remove(i);
                      } else {
                        _expandedChecklists.add(i);
                      }
                    }),
                    onEdit: () => context.addTripManagementEvent(
                      EditItineraryPlanData(
                        day: widget.day,
                        planDataEditorConfig:
                            UpdateItineraryPlanDataComponentConfig(
                          planDataType: PlanDataType.checklist,
                          index: i,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon,
            size: 18,
            color:
                isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isLight ? AppColors.neutral800 : AppColors.neutral200,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          iconSize: 22,
          color: isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight,
          onPressed: onAdd,
          tooltip: 'Add',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String text;

  const _EmptyPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.neutral400,
            ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title;
  final String preview;
  final VoidCallback onTap;

  const _NoteCard({
    required this.title,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.info.withValues(alpha: 0.12),
          highlightColor: AppColors.info.withValues(alpha: 0.06),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar — info blue for notes
                Container(width: 4, color: AppColors.info),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Untitled' : title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isLight
                                          ? AppColors.neutral900
                                          : AppColors.neutral100,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (preview.isNotEmpty && preview != title) ...[
                                const SizedBox(height: 4),
                                Text(
                                  preview,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isLight
                                            ? AppColors.neutral600
                                            : AppColors.neutral400,
                                        height: 1.4,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isLight
                              ? AppColors.neutral400
                              : AppColors.neutral500,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final String title;
  final double progress;
  final int completed;
  final int total;
  final bool isExpanded;
  final List<dynamic> items;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;

  const _ChecklistCard({
    required this.title,
    required this.progress,
    required this.completed,
    required this.total,
    required this.isExpanded,
    required this.items,
    required this.onToggleExpand,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Accent bar turns success green when checklist is fully complete
    final accentColor =
        progress == 1.0 ? AppColors.success : AppColors.brandPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar — green when complete, brandPrimary otherwise
            Container(width: 4, color: accentColor),
            // Card body
            Expanded(
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleExpand,
                      splashColor: accentColor.withValues(alpha: 0.10),
                      highlightColor: accentColor.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isLight
                                              ? AppColors.neutral900
                                              : AppColors.neutral100,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: isLight
                                                ? AppColors.neutral200
                                                : AppColors.neutral700,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              progress == 1.0
                                                  ? AppColors.success
                                                  : AppColors.info,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '$completed/$total',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isLight
                                                  ? AppColors.neutral600
                                                  : AppColors.neutral400,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: onEdit,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: isLight
                                          ? AppColors.neutral500
                                          : AppColors.neutral400,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: isLight
                                      ? AppColors.neutral400
                                      : AppColors.neutral500,
                                  size: 22,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isExpanded && items.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isLight
                            ? AppColors.neutral100.withValues(alpha: 0.5)
                            : AppColors.darkSurfaceVariant
                                .withValues(alpha: 0.3),
                      ),
                      child: Column(
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: isLight
                                ? AppColors.neutral300
                                : AppColors.neutral700,
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (ctx, itemIndex) {
                              final item = items[itemIndex];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      item.isChecked
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 20,
                                      color: item.isChecked
                                          ? AppColors.success
                                          : (isLight
                                              ? AppColors.neutral400
                                              : AppColors.neutral500),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.item,
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isLight
                                                  ? AppColors.neutral800
                                                  : AppColors.neutral200,
                                              decoration: item.isChecked
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              decorationColor: isLight
                                                  ? AppColors.neutral500
                                                  : AppColors.neutral400,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
