import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

class CollaboratorList extends StatelessWidget {
  static const double _kAvatarRadius = 14;
  static const double _kAvatarOffset = 18.0;
  static const int _maximumNumberOfAvatarsToShow = 3;

  const CollaboratorList({super.key});

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<TripMetadataFacade>(
      shouldRebuild: (beforeUpdate, afterUpdate) {
        return !listEquals(beforeUpdate.contributors, afterUpdate.contributors);
      },
      widgetBuilder: _createCollaboratorsManager,
    );
  }

  Widget _createCollaboratorsManager(BuildContext context) {
    var numberOfContributors =
        context.activeTrip.tripMetadata.contributors.length;
    var numberOfAvatars =
        min(_maximumNumberOfAvatarsToShow, numberOfContributors);

    var avatarPhotos = <Positioned>[];
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
      numberOfAvatars - 1,
      (index) => Positioned(
        left: (index + 1) * _kAvatarRadius,
        child: const CircleAvatar(
          radius: _kAvatarRadius,
          child: Icon(Icons.person, size: _kAvatarOffset),
        ),
      ),
    ).reversed.toList()
      ..add(Positioned(
        left: numberOfAvatars * _kAvatarRadius,
        child: _createClickableRoundedButton(
            Icon(
              Icons.add_rounded,
              color: Colors.black,
            ),
            () => _selectTripMetadata(context)),
      )));

    return SizedBox(
      width: (_kAvatarRadius * numberOfAvatars) + (_kAvatarRadius * 2),
      height: _kAvatarRadius * 2,
      child: Stack(
        children: avatarPhotos,
      ),
    );
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

  void _selectTripMetadata(BuildContext context) {
    context.addTripManagementEvent(UpdateTripEntity<TripMetadataFacade>.select(
        tripEntity: context.activeTrip.tripMetadata));
  }
}
