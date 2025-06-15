import 'package:flutter/material.dart';

import 'card.dart';

class PlatformTabBar extends StatefulWidget {
  final Map<String, Widget> tabBarItems;
  final TabController? tabController;
  final double? maxTabViewHeight;

  const PlatformTabBar(
      {super.key,
      required this.tabBarItems,
      this.tabController,
      this.maxTabViewHeight});

  @override
  State<PlatformTabBar> createState() => _PlatformTabBarState();
}

class _PlatformTabBarState extends State<PlatformTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = widget.tabController ??
        TabController(length: widget.tabBarItems.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _createTabBar(),
          const SizedBox(height: 16.0),
          Flexible(
            child: Container(
              constraints: widget.maxTabViewHeight == null
                  ? null
                  : BoxConstraints(maxHeight: widget.maxTabViewHeight!),
              child: Center(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.tabBarItems.values.toList(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _createTabBar() {
    return TabBar(
      tabs: widget.tabBarItems.keys.map((tabTitle) {
        return Tab(
          icon: FittedBox(
            child: Text(tabTitle),
          ),
        );
      }).toList(),
      controller: _tabController,
    );
  }
}
