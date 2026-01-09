import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

class StayDetails extends StatefulWidget {
  final LodgingFacade lodging;
  final void Function()? onLocationUpdated;

  const StayDetails({
    required this.lodging,
    this.onLocationUpdated,
    super.key,
  });

  @override
  State<StayDetails> createState() => _StayDetailsState();
}

class _StayDetailsState extends State<StayDetails> {
  String? _cityName;

  @override
  void initState() {
    super.initState();
    _updateCityName();
  }

  @override
  void didUpdateWidget(covariant StayDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lodging.location != oldWidget.lodging.location) {
      setState(_updateCityName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStayAtHeader(context, isLightTheme),
          const SizedBox(height: 12),
          _buildLocationField(context),
        ],
      ),
    );
  }

  void _updateCityName() {
    setState(() {
      _cityName = widget.lodging.location?.context.city;
    });
  }

  Widget _buildStayAtHeader(BuildContext context, bool isLightTheme) {
    return Row(
      children: [
        Icon(
          Icons.hotel_rounded,
          color: isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight,
          size: EditorTheme.iconSize,
        ),
        const SizedBox(width: 8),
        Text(
          'Stay At',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: (_cityName != null && _cityName!.isNotEmpty)
              ? Text(
                  _cityName!,
                  key: ValueKey<String>(_cityName!),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.brandPrimary
                            : AppColors.brandPrimaryLight,
                      ),
                )
              : const SizedBox.shrink(
                  key: ValueKey<String>('empty'),
                ),
        ),
      ],
    );
  }

  Widget _buildLocationField(BuildContext context) {
    return PlatformGeoLocationAutoComplete(
      selectedLocation: widget.lodging.location,
      onLocationSelected: (newLocation) {
        widget.lodging.location = newLocation;
        _updateCityName();
        if (widget.onLocationUpdated != null) widget.onLocationUpdated!();
      },
    );
  }
}
