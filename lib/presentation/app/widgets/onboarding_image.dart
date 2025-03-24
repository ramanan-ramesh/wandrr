import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';

class OnBoardingImage extends StatelessWidget {
  static const _onBoardingImageAsset = 'assets/images/plan_itinerary.jpg';

  const OnBoardingImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: Image(
            image: AssetImage(_onBoardingImageAsset),
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
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 45,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            )),
          ),
        ),
      ],
    );
  }
}
