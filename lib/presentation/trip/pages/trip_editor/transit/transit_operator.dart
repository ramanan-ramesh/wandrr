import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'airline_data.dart';

class TransitOperatorEditor extends StatelessWidget {
  final TransitOption transitOption;
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const TransitOperatorEditor(
      {required this.transitOption,
      required this.onOperatorChanged,
      super.key,
      this.initialOperator});

  @override
  Widget build(BuildContext context) {
    if (transitOption == TransitOption.flight) {
      return _FlightDetailsEditor(
          initialOperator: initialOperator,
          onOperatorChanged: onOperatorChanged);
    } else {
      return _createTransitOperatorEditingField(context);
    }
  }

  Widget _createTransitOperatorEditingField(BuildContext context) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final borderColor =
        isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
    final iconColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    var transitOperatorEditingController =
        TextEditingController(text: initialOperator ?? '');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        minLines: 1,
        maxLines: 1,
        style: theme.textTheme.labelLarge?.copyWith(
          color: textColor,
        ),
        controller: transitOperatorEditingController,
        decoration: InputDecoration(
          labelText: context.localizations.carrierName,
          labelStyle: TextStyle(color: textColor),
          prefixIcon: Icon(Icons.directions_bus, color: iconColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: onOperatorChanged,
      ),
    );
  }
}

class _FlightDetailsEditor extends StatefulWidget {
  final String? initialOperator;
  final Function(String?) onOperatorChanged;

  const _FlightDetailsEditor(
      {required this.initialOperator, required this.onOperatorChanged});

  @override
  State<_FlightDetailsEditor> createState() => _FlightDetailsEditorState();
}

class _FlightDetailsEditorState extends State<_FlightDetailsEditor>
    with SingleTickerProviderStateMixin {
  late final AirlineData airlineData;
  late final TextEditingController flightNumberEditingController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _initializeFromOperator();
    _updateAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    flightNumberEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FlightDetailsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOperator != widget.initialOperator) {
      _initializeFromOperator();
      _updateAnimation();
      setState(() {});
    }
  }

  void _updateAnimation() {
    if (_isAirlineValid()) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  bool _isAirlineValid() {
    return airlineData.airLineName != null &&
        airlineData.airLineName!.isNotEmpty &&
        airlineData.airLineCode != null &&
        airlineData.airLineCode!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final containerColor1 = isLightTheme
        ? AppColors.lightSurface.withValues(alpha: 0.95)
        : AppColors.darkSurfaceVariant.withValues(alpha: 0.6);
    final containerColor2 = isLightTheme
        ? AppColors.neutral200.withValues(alpha: 0.8)
        : AppColors.darkSurface.withValues(alpha: 0.4);
    final borderColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.3)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.3);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [containerColor1, containerColor2],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _createAirlineEditor(context),
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: _isAirlineValid()
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildFlightNumberSection(context, isLightTheme),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _initializeFromOperator() {
    if (widget.initialOperator != null && widget.initialOperator!.isNotEmpty) {
      airlineData = AirlineData(widget.initialOperator!);
    } else {
      airlineData = AirlineData.empty();
    }
    flightNumberEditingController =
        TextEditingController(text: airlineData.airLineNumber ?? '');
  }

  Widget _createAirlineEditor(BuildContext context) {
    final autoComplete =
        PlatformAutoComplete<(String airLineName, String airLineCode)>(
      labelText: context.localizations.flightCarrierName,
      selectedItem:
          (airlineData.airLineName != null && airlineData.airLineCode != null)
              ? (airlineData.airLineName!, airlineData.airLineCode!)
              : null,
      displayTextCreator: (airlineData) => airlineData.$1,
      optionsBuilder:
          context.apiServicesRepository.airlinesDataService.queryData,
      onSelected: (selectedAirlineData) {
        airlineData.airLineName = selectedAirlineData.$1;
        airlineData.airLineCode = selectedAirlineData.$2;
        _updateAnimation();
        if (airlineData.airLineNumber != null &&
            airlineData.airLineName != null &&
            airlineData.airLineCode != null) {
          widget.onOperatorChanged(airlineData.toString());
        }
        setState(() {});
      },
      listItem: (airlineData) {
        return ListTile(
          selected: this.airlineData.airLineName == airlineData.$1,
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              airlineData.$2,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            airlineData.$1,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      },
    );
    return SizedBox(width: double.infinity, child: autoComplete);
  }

  Widget _buildFlightNumberSection(BuildContext context, bool isLightTheme) {
    final sectionBgColor1 = isLightTheme
        ? AppColors.neutral200.withValues(alpha: 0.9)
        : AppColors.darkSurface.withValues(alpha: 0.7);
    final sectionBgColor2 = isLightTheme
        ? AppColors.lightSurface.withValues(alpha: 0.7)
        : AppColors.darkSurfaceVariant.withValues(alpha: 0.5);
    final sectionBorderColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.4)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.4);
    final codeContainerBg =
        isLightTheme ? AppColors.neutral300 : AppColors.darkSurfaceVariant;
    final codeBorderColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.5);
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final labelColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;
    final separatorColor =
        isLightTheme ? AppColors.neutral500 : AppColors.neutral500;
    final checkColor =
        isLightTheme ? AppColors.success : AppColors.successLight;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [sectionBgColor1, sectionBgColor2],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sectionBorderColor,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: codeContainerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: codeBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      airlineData.airLineCode ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-',
                    style: TextStyle(
                      color: separatorColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: codeContainerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: codeBorderColor,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        maxLines: 1,
                        minLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                          letterSpacing: 1.2,
                        ),
                        decoration: InputDecoration(
                          labelText: context.localizations.flightNumber,
                          labelStyle: TextStyle(color: labelColor),
                          hintText: '0000',
                          hintStyle: TextStyle(
                            color: labelColor,
                            letterSpacing: 1.2,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        controller: flightNumberEditingController,
                        onChanged: (newFlightNumber) {
                          airlineData.airLineNumber = newFlightNumber;
                          if (airlineData.airLineNumber != null &&
                              airlineData.airLineNumber!.isNotEmpty &&
                              airlineData.airLineName != null &&
                              airlineData.airLineCode != null) {
                            widget.onOperatorChanged(airlineData.toString());
                          } else {
                            widget.onOperatorChanged(null);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (airlineData.airLineNumber != null &&
                  airlineData.airLineNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: checkColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${airlineData.airLineCode}-${airlineData.airLineNumber}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
