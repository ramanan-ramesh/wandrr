import 'package:flutter/material.dart';

class SplitByTab extends StatefulWidget {
  final void Function(List<String>) callback;
  final Map<String, Color> contributorsVsColors;
  final List<String> splitBy;

  const SplitByTab(
      {super.key,
      required this.callback,
      required this.splitBy,
      required this.contributorsVsColors});

  @override
  State<SplitByTab> createState() => _SplitByTabState();
}

class _SplitByTabState extends State<SplitByTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.contributorsVsColors.entries
          .map(
            (contributorVsColor) => _buildSplitByContributorTile(
                contributorVsColor.key, contributorVsColor.value),
          )
          .toList(),
    );
  }

  Widget _buildSplitByContributorTile(
      String contributor, Color contributorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: SizedBox(
        height: 45,
        child: ListTile(
          selected: widget.splitBy.contains(contributor),
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
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              contributor,
              style: TextStyle(color: contributorColor),
            ),
          ),
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: contributorColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
