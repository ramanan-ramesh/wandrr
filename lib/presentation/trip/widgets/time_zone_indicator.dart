import 'package:flutter/material.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class TimezoneIndicator extends StatelessWidget {
  final LocationFacade location;
  static const Duration _scaleAnimationDuration = Duration(milliseconds: 500);
  static const Duration _containerAnimationDuration =
      Duration(milliseconds: 350);

  const TimezoneIndicator({
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.isLightTheme;
    final timezoneString =
        latLngToTimezoneString(location.latitude, location.longitude);

    return TweenAnimationBuilder<double>(
      duration: _scaleAnimationDuration,
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: _containerAnimationDuration,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: _buildDecoration(isLightTheme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(isLightTheme),
                const SizedBox(width: 10),
                _buildTimezoneText(context, isLightTheme, timezoneString),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildDecoration(bool isLightTheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.info.withValues(alpha: isLightTheme ? 0.12 : 0.25),
          AppColors.infoLight.withValues(alpha: isLightTheme ? 0.08 : 0.18),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.35)
            : AppColors.infoLight.withValues(alpha: 0.45),
        width: 1.3,
      ),
    );
  }

  Widget _buildIcon(bool isLightTheme) {
    return Icon(
      Icons.public_rounded,
      size: 20,
      color: isLightTheme ? AppColors.info : AppColors.infoLight,
    );
  }

  Widget _buildTimezoneText(
      BuildContext context, bool isLightTheme, String timezoneString) {
    return Text(
      timezoneString,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isLightTheme ? AppColors.info : AppColors.infoLight,
            letterSpacing: 0.2,
          ),
    );
  }
}
