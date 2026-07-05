import 'package:wandrr/data/trip/models/transit.dart';

/// Groups transits into either a standalone leg or a multi-leg journey.
class PrintTransitGroup {
  final String? journeyId;
  final List<TransitFacade> legs;

  const PrintTransitGroup({required this.journeyId, required this.legs});

  bool get isJourney => journeyId != null && legs.length > 1;
}
