import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/print_options.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/services/trip_print_service.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Modal dialog that lets the user choose which sections to include in the
/// printed PDF, then generates and shows a print preview.
///
/// All form content is shown immediately. If trip data is not yet fully loaded,
/// the transit list shows a progress indicator that resolves after loading
/// completes (with a minimum 1-second visual delay).
class PrintTripDialog extends StatefulWidget {
  final TripDataFacade tripData;

  const PrintTripDialog({required this.tripData, super.key});

  @override
  State<PrintTripDialog> createState() => _PrintTripDialogState();
}

class _PrintTripDialogState extends State<PrintTripDialog> {
  late final TextEditingController _titleController;
  bool _includeChecklist = true;
  bool _includeExpenses = true;
  bool _includeSights = true;
  bool _includeNotes = true;
  bool _includeInterCityTransit = true;
  bool _includeIntraCityTransit = true;
  bool _isGenerating = false;

  /// Whether trip data is fully loaded AND the minimum display delay passed.
  bool _transitsReady = false;

  late List<TransitFacade> _allTransits;
  late Set<String> _selectedTransitIds;

  /// Journey IDs whose legs are merged (first departure → last arrival).
  final Set<String> _mergedJourneyIds = {};

  StreamSubscription<bool>? _loadSub;
  Timer? _minDelayTimer;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.tripData.tripMetadata.name);
    _allTransits = [];
    _selectedTransitIds = {};

    if (widget.tripData.isFullyLoadedValue) {
      _initTransits();
      _transitsReady = true;
    } else {
      final openTime = DateTime.now();
      _loadSub = widget.tripData.isFullyLoaded.listen((loaded) {
        if (loaded && mounted) {
          _loadSub?.cancel();
          _initTransits();
          // Ensure at least 1 second of progress indicator is visible
          final elapsed = DateTime.now().difference(openTime);
          final remaining = const Duration(seconds: 1) - elapsed;
          if (remaining > Duration.zero) {
            _minDelayTimer = Timer(remaining, () {
              if (mounted) setState(() => _transitsReady = true);
            });
          } else {
            setState(() => _transitsReady = true);
          }
        }
      });
    }
  }

  void _initTransits() {
    _allTransits = widget.tripData.transitCollection.collectionItems.toList()
      ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
          .compareTo(b.departureDateTime ?? DateTime(0)));
    _selectedTransitIds =
        _allTransits.where((t) => t.id != null).map((t) => t.id!).toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _loadSub?.cancel();
    _minDelayTimer?.cancel();
    super.dispose();
  }

  // ── Transit helpers ─────────────────────────────────────────────────

  bool _isInterCity(TransitFacade t) {
    final dep = t.departureLocation?.context.city;
    final arr = t.arrivalLocation?.context.city;
    if (dep == null || arr == null) return true;
    return dep.toLowerCase() != arr.toLowerCase();
  }

  List<TransitFacade> get _visibleTransits {
    if (!_transitsReady) return [];
    return _allTransits.where((t) {
      final isInter = _isInterCity(t);
      if (isInter && !_includeInterCityTransit) return false;
      if (!isInter && !_includeIntraCityTransit) return false;
      return true;
    }).toList();
  }

  /// Groups visible transits into standalone legs and multi-leg journeys.
  List<_TransitGroup> get _transitGroups {
    final visible = _visibleTransits;
    final journeyMap = <String, List<TransitFacade>>{};
    final standalone = <TransitFacade>[];

    for (final t in visible) {
      if (t.journeyId != null && t.journeyId!.isNotEmpty) {
        journeyMap.putIfAbsent(t.journeyId!, () => []).add(t);
      } else {
        standalone.add(t);
      }
    }

    final groups = <_TransitGroup>[];
    for (final entry in journeyMap.entries) {
      groups.add(_TransitGroup(journeyId: entry.key, legs: entry.value));
    }
    for (final t in standalone) {
      groups.add(_TransitGroup(journeyId: null, legs: [t]));
    }
    groups.sort((a, b) {
      final aTime = a.legs.first.departureDateTime ?? DateTime(0);
      final bTime = b.legs.first.departureDateTime ?? DateTime(0);
      return aTime.compareTo(bTime);
    });
    return groups;
  }

  // ── Build options ───────────────────────────────────────────────────

  PrintOptions _buildOptions() {
    final visibleIds =
        _visibleTransits.where((t) => t.id != null).map((t) => t.id!).toSet();
    final effectiveIds = _selectedTransitIds.intersection(visibleIds);

    return PrintOptions(
      title: _titleController.text.trim().isEmpty
          ? widget.tripData.tripMetadata.name
          : _titleController.text.trim(),
      includeChecklist: _includeChecklist,
      includeExpenses: _includeExpenses,
      includeSights: _includeSights,
      includeNotes: _includeNotes,
      includeInterCityTransit: _includeInterCityTransit,
      includeIntraCityTransit: _includeIntraCityTransit,
      selectedTransitIds: effectiveIds,
      mergedJourneyIds: Set.from(_mergedJourneyIds),
    );
  }

  Future<void> _onGenerate() async {
    setState(() => _isGenerating = true);
    try {
      final options = _buildOptions();
      final pdfBytes =
          await TripPrintService().generatePdf(widget.tripData, options);

      if (!mounted) return;
      Navigator.of(context).pop();

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: options.title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${context.localizations.pdfGenerationFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBig = MediaQuery.of(context).size.width > 600;
    final maxW = isBig ? 600.0 : 500.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxW,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        margin: const EdgeInsets.all(24),
        child: Material(
          elevation: 24,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Flexible(child: _buildScrollBody(context, cs)),
              _buildFooter(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final l10n = context.localizations;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.black, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.printTrip,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context, ColorScheme cs) {
    final l10n = context.localizations;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: (!_transitsReady || _isGenerating) ? null : _onGenerate,
            icon: _isGenerating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.print_rounded),
            label: Text(_isGenerating ? l10n.generatingPdf : l10n.generatePdf),
          ),
        ],
      ),
    );
  }

  // ── Scroll body ───────────────────────────────────────────────────────

  Widget _buildScrollBody(BuildContext context, ColorScheme cs) {
    final l10n = context.localizations;
    final groups = _transitGroups;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      children: [
        // ── Title field ─────────────────────────────────────────
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(labelText: l10n.documentTitle),
        ),
        const SizedBox(height: 24),

        // ── Section chips ───────────────────────────────────────
        Text(l10n.sectionsToInclude,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SectionChip(
              icon: Icons.checklist_rounded,
              label: l10n.checklists,
              selected: _includeChecklist,
              onSelected: (v) => setState(() => _includeChecklist = v),
            ),
            _SectionChip(
              icon: Icons.payments_rounded,
              label: l10n.expenses,
              selected: _includeExpenses,
              onSelected: (v) => setState(() => _includeExpenses = v),
            ),
            _SectionChip(
              icon: Icons.place_rounded,
              label: l10n.sightsPlaces,
              selected: _includeSights,
              onSelected: (v) => setState(() => _includeSights = v),
            ),
            _SectionChip(
              icon: Icons.note_rounded,
              label: l10n.notes,
              selected: _includeNotes,
              onSelected: (v) => setState(() => _includeNotes = v),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Transit section ─────────────────────────────────────
        Text(l10n.transitOptions,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CompactSwitch(
                icon: Icons.connecting_airports_rounded,
                label: l10n.includeInterCityTransit,
                value: _includeInterCityTransit,
                onChanged: (v) => setState(() => _includeInterCityTransit = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactSwitch(
                icon: Icons.directions_bus_rounded,
                label: l10n.includeIntraCityTransit,
                value: _includeIntraCityTransit,
                onChanged: (v) => setState(() => _includeIntraCityTransit = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Transit list (loading or populated) ─────────────────
        if (!_transitsReady)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: LinearProgressIndicator()),
          )
        else if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noTransitsAvailable,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
          )
        else
          ...groups.map((g) => _buildTransitGroupTile(context, g, cs)),
      ],
    );
  }

  // ── Transit group tile ────────────────────────────────────────────────

  Widget _buildTransitGroupTile(
      BuildContext context, _TransitGroup group, ColorScheme cs) {
    if (group.isJourney) {
      return _JourneyGroupTile(
        group: group,
        isMerged: _mergedJourneyIds.contains(group.journeyId),
        selectedIds: _selectedTransitIds,
        onMergeToggled: (merged) {
          setState(() {
            if (merged) {
              _mergedJourneyIds.add(group.journeyId!);
              for (final leg in group.legs) {
                if (leg.id != null) _selectedTransitIds.add(leg.id!);
              }
            } else {
              _mergedJourneyIds.remove(group.journeyId!);
            }
          });
        },
        onLegToggled: (String id, bool selected) {
          setState(() {
            if (selected) {
              _selectedTransitIds.add(id);
            } else {
              _selectedTransitIds.remove(id);
            }
          });
        },
      );
    }

    final t = group.legs.first;
    final isSelected = t.id != null && _selectedTransitIds.contains(t.id);
    return _StandaloneTransitTile(
      transit: t,
      isSelected: isSelected,
      onChanged: (v) {
        if (t.id == null) return;
        setState(() {
          if (v) {
            _selectedTransitIds.add(t.id!);
          } else {
            _selectedTransitIds.remove(t.id!);
          }
        });
      },
    );
  }

  // ── Summary helpers ───────────────────────────────────────────────────

  static String transitLabel(TransitOption option) {
    const labels = {
      TransitOption.flight: 'Flight',
      TransitOption.train: 'Train',
      TransitOption.bus: 'Bus',
      TransitOption.ferry: 'Ferry',
      TransitOption.cruise: 'Cruise',
      TransitOption.taxi: 'Taxi',
      TransitOption.walk: 'Walk',
      TransitOption.rentedVehicle: 'Car Rental',
      TransitOption.vehicle: 'Vehicle',
      TransitOption.publicTransport: 'Public Transit',
    };
    return labels[option] ?? option.name;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Supporting widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Compact switch used inside the transit section.
class _CompactSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: Switch.adaptive(value: value, onChanged: onChanged),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A standalone (single-leg) transit tile with a checkbox.
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
    final type = _PrintTripDialogState.transitLabel(transit.transitOption);
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
                    Text('$type: $from \u2192 $to',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    if (date.isNotEmpty)
                      Text(date,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
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

/// Multi-leg journey group with animated merge/expand toggle.
class _JourneyGroupTile extends StatefulWidget {
  final _TransitGroup group;
  final bool isMerged;
  final Set<String> selectedIds;
  final ValueChanged<bool> onMergeToggled;
  final void Function(String id, bool selected) onLegToggled;

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
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

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
    final type = _PrintTripDialogState.transitLabel(first.transitOption);
    final date = first.departureDateTime?.dayDateMonthFormat ?? '';

    final allSelected =
        legs.every((l) => l.id != null && widget.selectedIds.contains(l.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Journey header ────────────────────────────────────
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
                        value: allSelected,
                        onChanged: (v) {
                          final select = v ?? false;
                          for (final leg in legs) {
                            if (leg.id != null) {
                              widget.onLegToggled(leg.id!, select);
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
                          Text('$type: $from \u2192 $to',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              Text(l10n.nLegs(legs.length),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                              if (date.isNotEmpty) ...[
                                Text(' \u2022 ',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 10)),
                                Text(date,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Merge/expand toggle
                    _MergeToggle(
                      isMerged: widget.isMerged,
                      onTap: () => widget.onMergeToggled(!widget.isMerged),
                    ),
                  ],
                ),
              ),
            ),
            // ── Expanded legs ─────────────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
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
                          widget.onLegToggled(leg.id!, !legSelected);
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
                                value: legSelected,
                                onChanged: (v) {
                                  if (leg.id != null) {
                                    widget.onLegToggled(leg.id!, v ?? false);
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
                                  '$legFrom \u2192 $legTo${legTime.isNotEmpty ? ' ($legTime)' : ''}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
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

/// Animated merge/expand toggle button.
class _MergeToggle extends StatelessWidget {
  final bool isMerged;
  final VoidCallback onTap;

  const _MergeToggle({
    required this.isMerged,
    required this.onTap,
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
                  isMerged ? Icons.merge_rounded : Icons.fork_right_rounded,
                  key: ValueKey(isMerged),
                  size: 16,
                  color: isMerged ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  isMerged ? l10n.mergeLegs : l10n.showLegs,
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

/// A filter-chip style toggle for section inclusion.
class _SectionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _SectionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: cs.primaryContainer,
      backgroundColor: cs.surfaceContainerHighest,
      side: BorderSide(
        color: selected ? cs.primary : cs.outline,
        width: selected ? 1.5 : 1.0,
      ),
      labelStyle: TextStyle(
        color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// Groups transits — standalone (single leg) or journey (multi-leg).
class _TransitGroup {
  final String? journeyId;
  final List<TransitFacade> legs;

  const _TransitGroup({required this.journeyId, required this.legs});

  bool get isJourney => journeyId != null && legs.length > 1;
}
