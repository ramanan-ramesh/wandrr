import 'package:flutter/material.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/app_bar/toolbar.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const HomeAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const _AppLogo(),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Toolbar(),
        ),
      ],
    );
  }
}

class _AppLogo extends StatefulWidget {
  const _AppLogo();

  @override
  State<_AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<_AppLogo> with TickerProviderStateMixin {
  late final AnimationController _shineController;
  late final AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight - 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shineController, _wobbleController]),
        builder: (context, child) {
          final shimmerPosition = (_shineController.value * 2) - 1;

          final rotationAnimation = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.0, end: -0.45),
              weight: 25,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: -0.45, end: 0.45),
              weight: 50,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.45, end: 0.0),
              weight: 25,
            ),
          ]).evaluate(_wobbleController);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(rotationAnimation),
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(shimmerPosition - 0.6, -1),
                  end: Alignment(shimmerPosition + 0.6, 1),
                  colors: const [
                    Colors.transparent,
                    Color(0x66FFFFFF),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 0.5, 0.65],
                ).createShader(bounds);
              },
              child: child,
            ),
          );
        },
        child: FloatingActionButton.extended(
          heroTag: 'homeAppBarLogo',
          elevation: 0,
          onPressed: null,
          label: Text(
            'wandrr',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          icon: Image(
            image: Assets.images.logo.provider(),
            color: context.isLightTheme ? Colors.white : Colors.black,
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }
}
