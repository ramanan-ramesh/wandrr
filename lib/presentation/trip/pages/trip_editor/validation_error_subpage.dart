import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class ValidationErrorSubpage<T extends TripEntity<Enum>>
    extends StatelessWidget {
  final VoidCallback onBackPressed;
  final Iterable<Enum> errors;

  const ValidationErrorSubpage({
    required this.onBackPressed,
    required this.errors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ValidationErrorHeader(
          isLightTheme: isLightTheme,
          onBackPressed: onBackPressed,
        ),
        const SizedBox(height: 12),
        _ValidationErrorStatusBar(
          isLightTheme: isLightTheme,
          errorCount: errors.length,
        ),
        const SizedBox(height: 16),
        if (errors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No validation errors.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isLightTheme
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: errors.length,
            itemBuilder: (context, index) {
              return _ValidationErrorItem(
                isLightTheme: isLightTheme,
                error: errors.elementAt(index),
              );
            },
          ),
      ],
    );
  }
}

class _ValidationErrorHeader extends StatelessWidget {
  final bool isLightTheme;
  final VoidCallback onBackPressed;

  const _ValidationErrorHeader({
    required this.isLightTheme,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBackPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLightTheme
                ? [
                    AppColors.error.withValues(alpha: 0.08),
                    AppColors.error.withValues(alpha: 0.1),
                  ]
                : [
                    AppColors.errorLight.withValues(alpha: 0.15),
                    AppColors.errorLight.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLightTheme
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.errorLight.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: isLightTheme ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Back to Editor',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isLightTheme ? AppColors.error : AppColors.errorLight,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationErrorStatusBar extends StatelessWidget {
  final bool isLightTheme;
  final int errorCount;

  const _ValidationErrorStatusBar({
    required this.isLightTheme,
    required this.errorCount,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isLightTheme ? AppColors.error : AppColors.errorLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorCount == 1 ? '1 error found' : '$errorCount errors found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationErrorItem extends StatelessWidget {
  final bool isLightTheme;
  final Enum error;

  const _ValidationErrorItem({
    required this.isLightTheme,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final title = _getErrorTitle(error);
    final description = _getErrorDescription(error);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.white : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cancel_rounded,
            color: isLightTheme ? AppColors.error : AppColors.errorLight,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme ? Colors.black87 : Colors.white,
                      ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorTitle(Enum error) {
    // Basic human-readable title extraction from enum name
    final name = error.name;
    final buffer = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      if (i == 0) {
        buffer.write(name[i].toUpperCase());
      } else {
        if (name[i] == name[i].toUpperCase()) {
          buffer.write(' ');
        }
        buffer.write(name[i]);
      }
    }
    return buffer.toString();
  }

  String _getErrorDescription(Enum error) {
    // Provide user-friendly descriptions for common validation errors
    if (error.name.toLowerCase().contains('time')) {
      return 'Please make sure the selected date and time are valid.';
    } else if (error.name.toLowerCase().contains('location')) {
      return 'Please select a valid location.';
    } else if (error.name.toLowerCase().contains('expense')) {
      return 'Please verify the expense details are fully provided.';
    }
    return 'Please fill out this required field correctly.';
  }
}
