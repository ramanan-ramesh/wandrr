import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class SplitByTab extends StatefulWidget {
  final void Function(List<String>) callback;
  final List<String> splitBy;

  const SplitByTab({required this.callback, required this.splitBy, super.key});

  @override
  State<SplitByTab> createState() => _SplitByTabState();
}

class _SplitByTabState extends State<SplitByTab> {
  @override
  Widget build(BuildContext context) {
    var currentUserName = context.activeUser!.userName;
    var contributors = context.activeTrip.tripMetadata.contributors;

    // Get all unique people from splitBy (may include removed tripmates)
    final allPeopleInSplit = <String>{...contributors, ...widget.splitBy};
    final sortedPeople = allPeopleInSplit.toList()..sort();

    return ListView.builder(
        padding: const EdgeInsets.all(3.0),
        itemCount: sortedPeople.length,
        itemBuilder: (context, index) {
          var contributor = sortedPeople[index];
          final isNoLongerTripmate = !contributors.contains(contributor);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: _buildSplitByContributorTile(
                contributor, currentUserName, isNoLongerTripmate, context),
          );
        });
  }

  Widget _buildSplitByContributorTile(String contributor,
      String currentUserName, bool isNoLongerTripmate, BuildContext context) {
    bool isSelected = widget.splitBy.contains(contributor);
    bool isCurrentUser = contributor == currentUserName;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    final displayName = isCurrentUser
        ? context.localizations.you
        : contributor.split('@').first;

    return ListTile(
      title: Row(
        children: [
          if (isNoLongerTripmate) ...[
            Tooltip(
              message: 'No longer a tripmate',
              child: Icon(
                Icons.person_off,
                size: 16,
                color:
                    isLightTheme ? AppColors.warning : AppColors.warningLight,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              displayName,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                color: isNoLongerTripmate
                    ? (isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight)
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontStyle:
                    isNoLongerTripmate ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      selected: isSelected,
      leading: isSelected
          ? CircleAvatar(
              backgroundColor: isNoLongerTripmate
                  ? (isLightTheme ? AppColors.warning : AppColors.warningLight)
                  : null,
              child: Icon(
                Icons.check,
                size: 12,
              ),
            )
          : null,
      onTap: () {
        setState(() {
          if (!widget.splitBy.contains(contributor)) {
            widget.splitBy.add(contributor);
          } else {
            widget.splitBy.remove(contributor);
          }
          widget.callback(widget.splitBy);
        });
      },
    );
  }
}
