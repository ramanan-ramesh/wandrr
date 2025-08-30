import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/widgets/onboarding_image.dart';

import 'language_switcher.dart';

class OnBoardingPage extends StatelessWidget {
  final VoidCallback? onNavigateToNextPage;

  const OnBoardingPage({super.key, this.onNavigateToNextPage});

  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: OnBoardingImage(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const LanguageSwitcher(),
                if (!isBigLayout)
                  FloatingActionButton.large(
                    onPressed: onNavigateToNextPage,
                    shape: const CircleBorder(),
                    child: const Icon(
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
