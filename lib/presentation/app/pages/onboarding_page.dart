import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';

class OnBoardingPage extends StatelessWidget {
  VoidCallback? onNavigateToNextPage;

  OnBoardingPage({super.key, this.onNavigateToNextPage});

  static const _onBoardingImageAsset = 'assets/images/plan_itinerary.jpg';

  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout;
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
                fit: BoxFit.contain,
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
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.only(right: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                LanguageSwitcher(),
                if (!isBigLayout)
                  FloatingActionButton.large(
                    onPressed: onNavigateToNextPage,
                    shape: CircleBorder(),
                    child: Icon(
                      Icons.navigate_next_rounded,
                      size: 75,
                    ),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
