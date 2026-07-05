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
      title: _createAppLogo(context),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8.0), // or 16.0 for more space
          child: Toolbar(),
        ),
      ],
    );
  }

  Widget _createAppLogo(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight - 16,
      child: FloatingActionButton.extended(
        heroTag: 'homeAppBarLogo',
        elevation: 0,
        onPressed: null,
        label: Text(
          'wandrr',
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
          ),
        ),
        icon: Image(
          image: Assets.images.logo.provider(),
          color: context.isLightTheme ? Colors.white : Colors.black,
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}
