import 'package:flutter/material.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/plan_data_list.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/collapsible_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/collapsible_sections_page.dart';

class DefaultPage extends StatelessWidget {
  const DefaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CollapsibleSectionsPage(
      sections: [
        CollapsibleSection(
          title: 'Trip Data',
          icon: Icons.data_usage_rounded,
          child: const PlanDataList(),
        ),
        CollapsibleSection(
          title: 'Itinerary',
          icon: Icons.map_rounded,
          child: const ItineraryViewer(),
        ),
      ],
      initiallyExpandedIndex: 1,
      isHeightConstrained: true,
    );
  }
}
