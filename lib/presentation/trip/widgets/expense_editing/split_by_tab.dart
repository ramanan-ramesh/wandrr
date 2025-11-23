import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
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
    return ListView.builder(
        padding: const EdgeInsets.all(3.0),
        itemCount: contributors.length,
        itemBuilder: (context, index) {
          var contributor = contributors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: _buildSplitByContributorTile(
                contributor, currentUserName, context),
          );
        });
  }

  Widget _buildSplitByContributorTile(
      String contributor, String currentUserName, BuildContext context) {
    bool isSelected = widget.splitBy.contains(contributor);
    bool isCurrentUser = contributor == currentUserName;

    return ListTile(
      title: Text(
        isCurrentUser ? context.localizations.you : contributor,
        maxLines: 2,
        softWrap: true,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      leading: isSelected
          ? CircleAvatar(
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
