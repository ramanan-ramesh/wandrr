import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/section_header.dart';

import 'collapsible_section.dart';
import 'horizontal_sections.dart';

const double _kContainerHorizontalMargin = 8;
const double _kContainerVerticalMargin = 4;
const double _kContainerBorderRadius = 16;

class CollapsibleSectionsPage extends StatefulWidget {
  final List<CollapsibleSection> sections;
  final int? initiallyExpandedIndex;

  const CollapsibleSectionsPage({
    super.key,
    required this.sections,
    this.initiallyExpandedIndex,
  });

  @override
  State<CollapsibleSectionsPage> createState() =>
      _CollapsibleSectionsPageState();
}

class _CollapsibleSectionsPageState extends State<CollapsibleSectionsPage>
    with TickerProviderStateMixin {
  int? _expandedSectionIndex;
  late final List<AnimationController> _rotationControllers;

  @override
  void initState() {
    super.initState();
    _expandedSectionIndex = widget.initiallyExpandedIndex;
    _rotationControllers = List.generate(
      widget.sections.length,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
        value: i == _expandedSectionIndex ? 0.5 : 0.0,
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _rotationControllers) {
      controller.dispose();
    }
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

  void _handleSectionTap(int index, bool isCurrentlyExpanded) {
    setState(() {
      final previousExpandedIndex = _expandedSectionIndex;
      _expandedSectionIndex = isCurrentlyExpanded ? null : index;
      if (isCurrentlyExpanded) {
        _rotationControllers[index].animateTo(0.0, curve: Curves.easeInOut);
      } else {
        _rotationControllers[index].animateTo(0.5, curve: Curves.easeInOut);
        if (previousExpandedIndex != null && previousExpandedIndex != index) {
          _rotationControllers[previousExpandedIndex]
              .animateTo(0.0, curve: Curves.easeInOut);
        }
      }
    });
  }

  Widget _buildAllCollapsedView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            widget.sections.length,
            _buildSection,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView(int expandedIndex) {
    final sectionsAbove = widget.sections.sublist(0, expandedIndex);
    final sectionsBelow = widget.sections.sublist(expandedIndex + 1);
    final children = <Widget>[
      if (sectionsAbove.length > 1)
        HorizontalSectionsList(
          sections: sectionsAbove,
          onSectionTap: (index) => _handleSectionTap(index, false),
        )
      else if (sectionsAbove.length == 1)
        _buildSection(expandedIndex - 1),
      _buildSection(expandedIndex),
      if (sectionsBelow.length > 1)
        HorizontalSectionsList(
          sections: sectionsBelow,
          onSectionTap: (index) =>
              _handleSectionTap(expandedIndex + 1 + index, false),
        )
      else if (sectionsBelow.length == 1)
        _buildSection(expandedIndex + 1),
    ];
    return Column(children: children);
  }

  Widget _buildSection(int index) {
    final section = widget.sections[index];
    final isExpanded = _expandedSectionIndex == index;
    return _CollapsibleSectionContainer(
      index: index,
      section: section,
      isExpanded: isExpanded,
      rotationController: _rotationControllers[index],
      onTap: () => _handleSectionTap(index, isExpanded),
    );
  }
}

class _CollapsibleSectionContainer extends StatelessWidget {
  final int index;
  final CollapsibleSection section;
  final bool isExpanded;
  final AnimationController rotationController;
  final VoidCallback onTap;

  const _CollapsibleSectionContainer({
    required this.index,
    required this.section,
    required this.isExpanded,
    required this.rotationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expandedColor = AppColors.brandPrimary;
    final unexpandedColor = theme.colorScheme.surfaceContainerHighest;
    final sectionColor = isExpanded ? expandedColor : unexpandedColor;
    final container = Container(
      margin: const EdgeInsets.symmetric(
          horizontal: _kContainerHorizontalMargin,
          vertical: _kContainerVerticalMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sectionColor.withAlpha(25), sectionColor.withAlpha(51)],
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
        children: [
          SectionHeader(
            index: index,
            title: section.title,
            icon: section.icon,
            isExpanded: isExpanded,
            rotationController: rotationController,
            onTap: onTap,
          ),
          if (isExpanded) Expanded(child: section.child)
        ],
      ),
    );
    if (isExpanded) {
      return Expanded(child: container);
    }
    return container;
  }
}
