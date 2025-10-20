import 'package:flutter/material.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/app_bar/toolbar.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double? contentWidth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const HomeAppBar({Key? key, this.contentWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: contentWidth != null,
      flexibleSpace: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _createHomeButton(context),
                Toolbar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createHomeButton(BuildContext context) {
    return FloatingActionButton.extended(
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
    );
  }
}
