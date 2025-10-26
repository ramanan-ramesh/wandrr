import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/section_header.dart';

import 'collapsible_section.dart';
import 'horizontal_sections.dart';

class CollapsibleSectionsPage extends StatefulWidget {
  final List<CollapsibleSection> sections;
  final int? initiallyExpandedIndex;
  final bool isHeightConstrained;

  const CollapsibleSectionsPage({
    super.key,
    required this.sections,
    this.initiallyExpandedIndex,
    this.isHeightConstrained = false,
  });

  @override
  State<CollapsibleSectionsPage> createState() =>
      _CollapsibleSectionsPageState();
}

class _CollapsibleSectionsPageState extends State<CollapsibleSectionsPage>
    with TickerProviderStateMixin {
  int? _expandedSectionIndex;
  final Map<int, AnimationController> _rotationControllers = {};

  @override
  void initState() {
    super.initState();
    _expandedSectionIndex = widget.initiallyExpandedIndex;
    _initializeRotationControllers();
  }

  @override
  void dispose() {
    _disposeRotationControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expandedIndex = _expandedSectionIndex;

    if (expandedIndex == null) {
      return _buildAllCollapsedView();
    }

    return _buildExpandedView(expandedIndex);
  }

  void _initializeRotationControllers() {
    for (int i = 0; i < widget.sections.length; i++) {
      _rotationControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
        value: i == _expandedSectionIndex ? 0.5 : 0.0,
      );
    }
  }

  void _disposeRotationControllers() {
    for (var controller in _rotationControllers.values) {
      controller.dispose();
    }
  }

  void _handleSectionTap(int index, bool isCurrentlyExpanded) {
    setState(() {
      final previousExpandedIndex = _expandedSectionIndex;
      _expandedSectionIndex = isCurrentlyExpanded ? null : index;

      if (isCurrentlyExpanded) {
        _animateRotationTo(index, 0.0);
      } else {
        _animateRotationTo(index, 0.5);
        if (previousExpandedIndex != null && previousExpandedIndex != index) {
          _animateRotationTo(previousExpandedIndex, 0.0);
        }
      }
    });
  }

  void _animateRotationTo(int index, double value) {
    _rotationControllers[index]?.animateTo(value, curve: Curves.easeInOut);
  }

  Widget _buildAllCollapsedView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (int i = 0; i < widget.sections.length; i++) _buildSection(i),
        ],
      ),
    );
  }

  Widget _buildExpandedView(int expandedIndex) {
    final sectionsAbove = [for (int i = 0; i < expandedIndex; i++) i];
    final sectionsBelow = [
      for (int i = expandedIndex + 1; i < widget.sections.length; i++) i
    ];

    final children = [
      if (sectionsAbove.length > 1)
        HorizontalSectionsList(
          sectionIndices: sectionsAbove,
          sections: widget.sections,
          onSectionTap: (index) => _handleSectionTap(index, false),
          rotationControllers: _rotationControllers,
        )
      else if (sectionsAbove.length == 1)
        _buildSection(sectionsAbove[0]),
      _buildSection(expandedIndex),
      if (sectionsBelow.length > 1)
        HorizontalSectionsList(
          sectionIndices: sectionsBelow,
          sections: widget.sections,
          onSectionTap: (index) => _handleSectionTap(index, false),
          rotationControllers: _rotationControllers,
        )
      else if (sectionsBelow.length == 1)
        _buildSection(sectionsBelow[0]),
    ];

    return widget.isHeightConstrained
        ? Column(children: children)
        : SingleChildScrollView(child: Column(children: children));
  }

  Widget _buildSection(int index) {
    final section = widget.sections[index];
    final isExpanded = _expandedSectionIndex == index;

    return _CollapsibleSectionContainer(
      index: index,
      section: section,
      isExpanded: isExpanded,
      isHeightConstrained: widget.isHeightConstrained,
      rotationController: _rotationControllers[index]!,
      onTap: () => _handleSectionTap(index, isExpanded),
    );
  }
}

class _CollapsibleSectionContainer extends StatelessWidget {
  final int index;
  final CollapsibleSection section;
  final bool isExpanded;
  final bool isHeightConstrained;
  final AnimationController rotationController;
  final VoidCallback onTap;

  const _CollapsibleSectionContainer({
    required this.index,
    required this.section,
    required this.isExpanded,
    required this.isHeightConstrained,
    required this.rotationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = _buildSectionContainer(context);

    if (isHeightConstrained && isExpanded) {
      return Expanded(child: container);
    }
    return container;
  }

  Widget _buildSectionContainer(BuildContext context) {
    final colors = _SectionContainerColors.fromTheme(context, isExpanded);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: colors.backgroundGradient,
        border: Border.all(
          color: colors.borderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            index: index,
            title: section.title,
            icon: section.icon,
            isExpanded: isExpanded,
            rotationController: rotationController,
            onTap: onTap,
          ),
          if (isExpanded && isHeightConstrained)
            Expanded(child: section.child)
          else if (isExpanded)
            section.child,
        ],
      ),
    );
  }
}

class _SectionContainerColors {
  final LinearGradient backgroundGradient;
  final Color borderColor;
  final Color shadowColor;

  _SectionContainerColors._({
    required this.backgroundGradient,
    required this.borderColor,
    required this.shadowColor,
  });

  factory _SectionContainerColors.fromTheme(
      BuildContext context, bool isExpanded) {
    final theme = Theme.of(context);
    final expandedColor = AppColors.brandPrimary;
    final unexpandedColor = theme.colorScheme.surfaceContainerHighest;
    final sectionColor = isExpanded ? expandedColor : unexpandedColor;

    return _SectionContainerColors._(
      backgroundGradient: LinearGradient(
        colors: [sectionColor.withAlpha(25), sectionColor.withAlpha(51)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor:
          isExpanded ? expandedColor : theme.colorScheme.outline.withAlpha(102),
      shadowColor: isExpanded
          ? expandedColor.withAlpha(50)
          : theme.colorScheme.shadow.withAlpha(25),
    );
  }
}
