import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class TripEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _kAvatarRadius = 14;
  static const double _kAvatarOffset = 18.0;
  final VoidCallback onTitleClicked;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const TripEditorAppBar({Key? key, required this.onTitleClicked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _createHomeButton(context),
      centerTitle: false,
      title: GestureDetector(
        onTap: onTitleClicked,
        child: _createTripDetails(context),
      ),
      actions: !context.isBigLayout
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: _createCollaboratorsManager(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: _createShareTripButton(),
              ),
            ]
          : [],
    );
  }

  Widget _createTripDetails(BuildContext context) {
    var tripDateRange =
        '${context.activeTrip.tripMetadata.startDate!.dateMonthFormat} - ${context.activeTrip.tripMetadata.endDate!.dateMonthFormat}';
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.activeTrip.tripMetadata.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              tripDateRange,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        if (context.isBigLayout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: _createCollaboratorsManager(context),
          ),
        if (context.isBigLayout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: _createShareTripButton(),
          ),
      ],
    );
  }

  Widget _createCollaboratorsManager(BuildContext context) {
    var numberOfContributors =
        context.activeTrip.tripMetadata.contributors.length;
    var maximumNumberOfAvatarsToShow = 3;
    var visibleCollaborators =
        numberOfContributors > maximumNumberOfAvatarsToShow
            ? maximumNumberOfAvatarsToShow
            : numberOfContributors;

    var avatarPhotos = <Positioned>[];
    var overlap = _kAvatarRadius;
    avatarPhotos.add(Positioned(
      left: 0,
      child: CircleAvatar(
        radius: _kAvatarRadius,
        child: context.activeUser!.photoUrl != null
            ? ClipOval(
                child: Image(
                  image: NetworkImage(context.activeUser!.photoUrl!),
                  width: _kAvatarRadius * 2,
                  height: _kAvatarRadius * 2,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.person, size: _kAvatarOffset),
      ),
    ));

    avatarPhotos.addAll(List.generate(
      visibleCollaborators - 1,
      (index) => Positioned(
        left: (index + 1) * overlap,
        child: const CircleAvatar(
          radius: _kAvatarRadius,
          child: Icon(Icons.person, size: _kAvatarOffset),
        ),
      ),
    ).reversed.toList()
      ..add(Positioned(
        left: visibleCollaborators * overlap,
        child: _createClickableRoundedButton(
            Icon(
              Icons.add_rounded,
              color: Colors.black,
            ),
            () {}),
      )));

    return SizedBox(
      width: (overlap * visibleCollaborators) + (_kAvatarRadius * 2),
      height: _kAvatarRadius * 2,
      child: Stack(
        children: avatarPhotos,
      ),
    );
  }

  Widget _createShareTripButton() {
    return _createClickableRoundedButton(
        Icon(
          Icons.ios_share_rounded,
          color: Colors.black,
        ),
        () {});
  }

  Widget _createClickableRoundedButton(Widget child, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kAvatarRadius),
        splashColor: Colors.grey.shade300,
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          width: _kAvatarRadius * 2,
          height: _kAvatarRadius * 2,
          child: child,
        ),
      ),
    );
  }

  Widget _createHomeButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.addTripManagementEvent(GoToHome());
      },
      icon: const Icon(Icons.home_rounded),
      style: context.isLightTheme
          ? ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
            )
          : null,
    );
  }
}
