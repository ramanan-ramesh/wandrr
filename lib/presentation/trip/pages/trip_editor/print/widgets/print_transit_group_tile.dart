import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/models/print_transit_group.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/utils/print_transit_label.dart';

class PrintTransitGroupTile extends StatelessWidget {
  final PrintTransitGroup group;
  final bool isMerged;
  final Set<String> selectedIds;
  final ValueChanged<bool> onMergeToggled;
  final void Function(String id, {required bool selected}) onLegToggled;

  const PrintTransitGroupTile({
    required this.group,
    required this.isMerged,
    required this.selectedIds,
    required this.onMergeToggled,
    required this.onLegToggled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (group.isJourney) {
      return _JourneyGroupTile(
        group: group,
        isMerged: isMerged,
        selectedIds: selectedIds,
        onMergeToggled: onMergeToggled,
        onLegToggled: onLegToggled,
      );
    }

    final t = group.legs.first;
    final isSelected = t.id != null && selectedIds.contains(t.id);
    return _StandaloneTransitTile(
      transit: t,
      isSelected: isSelected,
      onChanged: (v) {
        if (t.id == null) {
          return;
        }
        onLegToggled(t.id!, selected: v);
      },
    );
  }
}

class _StandaloneTransitTile extends StatelessWidget {
  final TransitFacade transit;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _StandaloneTransitTile({
    required this.transit,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final from = transit.departureLocation?.context.city ?? '?';
    final to = transit.arrivalLocation?.context.city ?? '?';
    final type = printTransitLabel(transit.transitOption);
    final date = transit.departureDateTime?.dayDateMonthFormat ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!isSelected),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$type: $from -> $to',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyGroupTile extends StatefulWidget {
  final PrintTransitGroup group;
  final bool isMerged;
  final Set<String> selectedIds;
  final ValueChanged<bool> onMergeToggled;
  final void Function(String id, {required bool selected}) onLegToggled;

  const _JourneyGroupTile({
    required this.group,
    required this.isMerged,
    required this.selectedIds,
    required this.onMergeToggled,
    required this.onLegToggled,
  });

  @override
  State<_JourneyGroupTile> createState() => _JourneyGroupTileState();
}

class _JourneyGroupTileState extends State<_JourneyGroupTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    if (!widget.isMerged) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _JourneyGroupTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMerged && !oldWidget.isMerged) {
      _controller.reverse();
    } else if (!widget.isMerged && oldWidget.isMerged) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.localizations;
    final legs = widget.group.legs;
    final first = legs.first;
    final last = legs.last;
    final from = first.departureLocation?.context.city ?? '?';
    final to = last.arrivalLocation?.context.city ?? '?';
    final type = printTransitLabel(first.transitOption);
    final date = first.departureDateTime?.dayDateMonthFormat ?? '';

    final allSelected =
        legs.every((l) => l.id != null && widget.selectedIds.contains(l.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Use the stronger 'outline' token in light mode so the card edge
            // is clearly visible against the off-white background.
            color: Theme.of(context).brightness == Brightness.light
                ? cs.outline
                : cs.outlineVariant,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => widget.onMergeToggled(!widget.isMerged),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        key: ValueKey(
                            'PrintJourneyGroupTile_SelectAll_${widget.group.journeyId}'),
                        value: allSelected,
                        onChanged: (v) {
                          final select = v ?? false;
                          for (final leg in legs) {
                            if (leg.id != null) {
                              widget.onLegToggled(leg.id!, selected: select);
                            }
                          }
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$type: $from -> $to',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Text(
                                l10n.nLegs(legs.length),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              if (date.isNotEmpty) ...[
                                Text(
                                  ' - ',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _MergeToggle(
                      key: ValueKey(
                          'PrintJourneyGroupTile_MergeToggle_${widget.group.journeyId}'),
                      isMerged: widget.isMerged,
                      onTap: () => widget.onMergeToggled(!widget.isMerged),
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(height: 1, color: cs.outlineVariant),
                  ...legs.map((leg) {
                    final legFrom = leg.departureLocation?.context.city ?? '?';
                    final legTo = leg.arrivalLocation?.context.city ?? '?';
                    final legSelected =
                        leg.id != null && widget.selectedIds.contains(leg.id);
                    final legTime =
                        leg.departureDateTime?.hourMinuteAmPmFormat ?? '';

                    return InkWell(
                      onTap: () {
                        if (leg.id != null) {
                          widget.onLegToggled(leg.id!, selected: !legSelected);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(36, 6, 8, 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                key: ValueKey(
                                    'PrintJourneyGroupTile_LegCheckbox_${leg.id}'),
                                value: legSelected,
                                onChanged: (v) {
                                  if (leg.id != null) {
                                    widget.onLegToggled(
                                      leg.id!,
                                      selected: v ?? false,
                                    );
                                  }
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.circle,
                                size: 6, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$legFrom -> $legTo${legTime.isNotEmpty ? ' ($legTime)' : ''}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeToggle extends StatelessWidget {
  final bool isMerged;
  final VoidCallback onTap;

  const _MergeToggle({
    required this.isMerged,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.localizations;
    return Tooltip(
      message: isMerged ? l10n.showLegs : l10n.mergeLegs,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isMerged ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMerged ? cs.primary : cs.outline,
              width: isMerged ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isMerged ? Icons.fork_right_rounded : Icons.merge_rounded,
                  key: ValueKey(isMerged),
                  size: 16,
                  color: isMerged ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  isMerged ? l10n.showLegs : l10n.mergeLegs,
                  key: ValueKey(isMerged),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isMerged
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight:
                            isMerged ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
