import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/section_header.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

import 'collapsible_section.dart';

// Approximate total height of one section tile when fully collapsed.
// = container vertical margin (4×2 = 8) + header vertical padding (10×2 = 20)
//   + icon+padding row height (24 + 10×2 = 44) = 72 px.
// Used by LayoutBuilder to compute the remaining height for expanded content.
const double _kCollapsedSectionHeight = 72.0;

const double _kContainerHorizontalMargin = 8.0;
const double _kContainerVerticalMargin = 4.0;
const double _kContainerBorderRadius = 16.0;
const Duration _kExpandDuration = Duration(milliseconds: 380);

class CollapsibleSectionsPage extends StatefulWidget {
  final List<CollapsibleSection> sections;
  final int? initiallyExpandedIndex;

  const CollapsibleSectionsPage({
    required this.sections,
    super.key,
    this.initiallyExpandedIndex,
  });

  @override
  State<CollapsibleSectionsPage> createState() =>
      _CollapsibleSectionsPageState();
}

class _CollapsibleSectionsPageState extends State<CollapsibleSectionsPage>
    with TickerProviderStateMixin {
  int? _expandedSectionIndex;

  /// Per-section AnimationController: 0.0 = fully collapsed, 1.0 = fully expanded.
  late final List<AnimationController> _controllers;

  /// Whether the content widget for each section should be mounted in the tree.
  /// Set to true immediately when expansion begins; set back to false only after
  /// the collapse animation reaches AnimationStatus.dismissed, so the content
  /// stays visible (and animates out) during the closing transition.
  late final List<bool> _showContent;

  @override
  void initState() {
    super.initState();
    final n = widget.sections.length;
    _expandedSectionIndex = widget.initiallyExpandedIndex;
    _showContent = List.generate(n, (i) => i == _expandedSectionIndex);
    _controllers = List.generate(n, (i) {
      final ctrl = AnimationController(
        duration: _kExpandDuration,
        vsync: this,
        value: i == _expandedSectionIndex ? 1.0 : 0.0,
      );
      ctrl.addStatusListener((status) {
        if (status == AnimationStatus.dismissed && mounted) {
          setState(() => _showContent[i] = false);
        }
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSectionTap(int index) {
    final wasExpanded = _expandedSectionIndex == index;
    final previous = _expandedSectionIndex;

    setState(() {
      _expandedSectionIndex = wasExpanded ? null : index;
      if (!wasExpanded) {
        // Mount content before the expand animation starts.
        _showContent[index] = true;
      }
      // On collapse: keep showContent true until the AnimationStatus.dismissed
      // listener fires (content stays visible during the closing animation).
    });

    if (wasExpanded) {
      _controllers[index].animateBack(0.0, curve: Curves.easeInOut);
    } else {
      _controllers[index].animateTo(1.0, curve: Curves.easeInOut);
      if (previous != null && previous != index) {
        _controllers[previous].animateBack(0.0, curve: Curves.easeInOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = widget.sections.length;
        // Height available to the expanded section after reserving space for
        // all collapsed headers and the FAB clearance at the bottom.
        final expandedContentHeight = math.max(
          0.0,
          constraints.maxHeight -
              n * _kCollapsedSectionHeight -
              TripEditorPageConstants.fabContentPaddingBig,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++)
              _SectionTile(
                section: widget.sections[i],
                index: i,
                isExpanded: _expandedSectionIndex == i,
                showContent: _showContent[i],
                controller: _controllers[i],
                expandedContentHeight: expandedContentHeight,
                onTap: () => _handleSectionTap(i),
              ),
            // Always reserve FAB clearance; also ensures the Column fills the
            // available height when no section is expanded.
            const SizedBox(
                height: TripEditorPageConstants.fabContentPaddingBig),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private tile widget
// ---------------------------------------------------------------------------

class _SectionTile extends StatelessWidget {
  final CollapsibleSection section;
  final int index;
  final bool isExpanded;

  /// Whether the content widget is currently mounted (true during expand and
  /// during the collapse animation; false once fully collapsed).
  final bool showContent;
  final AnimationController controller;
  final double expandedContentHeight;
  final VoidCallback onTap;

  const _SectionTile({
    required this.section,
    required this.index,
    required this.isExpanded,
    required this.showContent,
    required this.controller,
    required this.expandedContentHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const expandedColor = AppColors.brandPrimary;
    final collapsedColor = theme.colorScheme.surfaceContainerHighest;
    final sectionColor = isExpanded ? expandedColor : collapsedColor;

    return AnimatedContainer(
      duration: _kExpandDuration,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(
        horizontal: _kContainerHorizontalMargin,
        vertical: _kContainerVerticalMargin,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sectionColor.withAlpha(25),
            sectionColor.withAlpha(51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isExpanded
              ? expandedColor
              : theme.colorScheme.outline.withAlpha(102),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(_kContainerBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            index: index,
            title: section.title,
            icon: section.icon,
            isExpanded: isExpanded,
            rotationController: controller,
            onTap: onTap,
          ),
          // SizeTransition animates the height from 0 → expandedContentHeight.
          // axisAlignment: -1 keeps the top edge pinned (slides down from top).
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            ),
            axisAlignment: -1.0,
            child: showContent
                ? FadeTransition(
                    // Fade in starts at 20 % of the animation so the content
                    // appears after the section has begun to open; mirrors on
                    // collapse for a natural fade-out.
                    opacity: CurvedAnimation(
                      parent: controller,
                      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
                    ),
                    child: SizedBox(
                      height: expandedContentHeight,
                      child: section.child,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
