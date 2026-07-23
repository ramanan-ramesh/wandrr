import 'package:flutter/material.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/l10n/extension.dart';

class OnBoardingImage extends StatelessWidget {
  const OnBoardingImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Image(
            image: Assets.images.planItinerary.provider(),
            fit: BoxFit.fitHeight,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
                child: Text(
              context.localizations.plan_itinerary,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.black,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            )),
          ),
        ),
      ],
    );
  }
}
