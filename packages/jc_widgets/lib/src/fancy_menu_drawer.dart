import 'package:flutter/material.dart';
import 'package:jc_widgets/src/expanded_header.dart';

class FancyMenuDrawer extends StatefulWidget {
  final FancyDrawerSettings drawerSettings;
  const FancyMenuDrawer({super.key, required this.drawerSettings});

  @override
  State<StatefulWidget> createState() => _FancyMenuDrawerState();
}

class _FancyMenuDrawerState extends State<FancyMenuDrawer> {
  Map<int, FancyMenuItem> currentExpandedMenu = {};
  @override
  void initState() {
    if (widget.drawerSettings.hierarchyDecoration?.isNotEmpty == true) {
      Set<int> allConfigureLevels =
          (widget.drawerSettings.hierarchyDecoration?.keys ?? []).toSet();
      debugPrint(
          "configure level: $allConfigureLevels, ${containsAllNumbers(getMaxLevels(widget.drawerSettings.menuItemList), allConfigureLevels)}");
      assert(
          containsAllNumbers(getMaxLevels(widget.drawerSettings.menuItemList),
              allConfigureLevels),
          "Your hierarchy settings doesn't contains all the levels of menu");
    }
    super.initState();
  }

  bool containsAllNumbers(int n, Set<int> numbers) {
    Set<int> requiredNumbers = {for (var i = 1; i <= n; i++) i};
    return requiredNumbers.difference(numbers).isEmpty;
  }

  int getMaxLevels(List<FancyMenuItem> menuItems) {
    int maxLevel = 0;

    for (var item in menuItems) {
      int level = _getMenuDepth(item, 1);
      if (level > maxLevel) {
        maxLevel = level;
      }
    }

    return maxLevel;
  }

  int _getMenuDepth(FancyMenuItem item, int currentLevel) {
    if (item.subMenus == null || item.subMenus!.isEmpty) {
      return currentLevel;
    }

    int maxDepth = currentLevel;
    for (var subMenu in item.subMenus!) {
      int depth = _getMenuDepth(subMenu, currentLevel + 1);
      if (depth > maxDepth) {
        maxDepth = depth;
      }
    }

    return maxDepth;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Drawer(
      width: widget.drawerSettings.width,
      backgroundColor: widget.drawerSettings.backgroundColor,
      elevation: widget.drawerSettings.elevation,
      shadowColor: widget.drawerSettings.shadowColor,
      surfaceTintColor: widget.drawerSettings.surfaceTintColor,
      shape: widget.drawerSettings.shape,
      clipBehavior: widget.drawerSettings.clipBehavior,
      child: Stack(
        children: [
          if (widget.drawerSettings.drawerBackgroundBuilder != null) ...[
            Positioned.fill(
                child: widget.drawerSettings.drawerBackgroundBuilder?.call() ??
                    const SizedBox()),
            Positioned.fill(
                child: Container(
              color: Colors.white.withOpacity(.8),
            )),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.drawerSettings.menuHeaderBuilder != null)
                widget.drawerSettings.menuHeaderBuilder!.call(),
              if (widget.drawerSettings.menuItemList.isNotEmpty == true)
                Flexible(
                  child: SingleChildScrollView(
                    child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (_, __) => buildExpandedMenu(
                            widget.drawerSettings.menuItemList[__], 1),
                        separatorBuilder: (_, __) => const SizedBox(),
                        itemCount: widget.drawerSettings.menuItemList.length),
                  ),
                )
            ],
          ),
        ],
      ),
    ));
  }

  Widget buildExpandedMenu(FancyMenuItem item, int noOfLevel) {
    bool? expand = getExpandValueByDrawerStyle(item, noOfLevel);
    return ExpandedHeader(
        initialExpand: expand,
        prioritizeInitExpand:
            widget.drawerSettings.drawerStyle == DrawerStyle.SINGLE_EXPAND
                ? true
                : false,
        headerBuilder: (isExpand, expand) {
          Widget defaultSelectedMenuItem = Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(.2),
            ),
            child: Text(
              item.menuName,
              style: const TextStyle(color: Colors.black, fontSize: 24)
                  .merge(item.textStyle),
            ),
          );

          Widget defaultUnselectedMenuItem = Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Text(
              item.menuName,
              style: const TextStyle(color: Colors.black, fontSize: 24)
                  .merge(item.unselectedTextStyle),
            ),
          );
          return InkWell(
              onTap: () {
                if (item.onEnterMenu != null) {
                  item.onEnterMenu?.call();
                }

                if (widget.drawerSettings.drawerStyle != DrawerStyle.FIXED) {
                  if (widget.drawerSettings.drawerStyle ==
                      DrawerStyle.SINGLE_EXPAND) {
                    setState(() {
                      !isExpand
                          ? currentExpandedMenu[noOfLevel] = item
                          : currentExpandedMenu.remove(noOfLevel);
                    });
                  }
                  expand.call(value: !isExpand);
                }
              },
              child: Row(
                children: [
                  SizedBox(
                    width: ((Theme.of(context).drawerTheme.width ?? 304) *
                            (noOfLevel - 1)) *
                        widget.drawerSettings.menuOffset,
                  ),
                  Expanded(
                      child: isExpand &&
                              (item.subMenus?.isNotEmpty == true ||
                                  item.subMenus != null)
                          ? (widget
                                      .drawerSettings
                                      .hierarchyDecoration?[noOfLevel]
                                      ?.selectedMenuBuilder)
                                  ?.call(item) ??
                              defaultSelectedMenuItem
                          : (widget
                                      .drawerSettings
                                      .hierarchyDecoration?[noOfLevel]
                                      ?.unSelectedMenuBuilder)
                                  ?.call(item) ??
                              defaultUnselectedMenuItem)
                ],
              ));
        },
        expandedBuilder: (context) {
          if (item.subMenus?.isEmpty == true || item.subMenus == null)
            return const SizedBox();

          return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, __) =>
                  buildExpandedMenu(item.subMenus![__], noOfLevel + 1),
              separatorBuilder: (_, __) => const SizedBox(),
              itemCount: item.subMenus!.length);
        });
  }

  bool? getExpandValueByDrawerStyle(FancyMenuItem item, int noOfLevel) {
    switch (widget.drawerSettings.drawerStyle) {
      case DrawerStyle.FIXED:
        return true;
      case DrawerStyle.EXPAND_INDIVIDUALLY:
        return null;
      case DrawerStyle.SINGLE_EXPAND:
        return currentExpandedMenu[noOfLevel] == item ? true : false;
    }
  }
}

class FancyDrawerSettings {
  Color? backgroundColor;
  double? elevation;
  Color? shadowColor;
  Color? surfaceTintColor;
  ShapeBorder? shape;
  Clip? clipBehavior;
  Widget? Function()? drawerBackgroundBuilder;
  List<FancyMenuItem> menuItemList;
  BoxDecoration? themeDecoration;
  Widget Function()? menuHeaderBuilder;
  double menuOffset;
  Map<int, FancyMenuSettings>? hierarchyDecoration;
  DrawerStyle drawerStyle;
  double? width;

  FancyDrawerSettings({
    required this.menuItemList,
    this.themeDecoration,
    this.hierarchyDecoration,
    this.menuHeaderBuilder,
    this.backgroundColor,
    this.clipBehavior,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.drawerBackgroundBuilder,
    this.surfaceTintColor,
    this.menuOffset = .05,
    this.drawerStyle = DrawerStyle.FIXED,
    this.width,
  });
}

enum DrawerStyle {
  /// All menus, including sub-menus, are expanded initially.
  FIXED,

  /// Each menu can expand individually
  EXPAND_INDIVIDUALLY,

  /// Only one menu will be expanded at a time; others will collapse.
  SINGLE_EXPAND;
}

class FancyMenuSettings {
  Widget? Function(FancyMenuItem)? selectedMenuBuilder;
  Widget? Function(FancyMenuItem)? unSelectedMenuBuilder;

  FancyMenuSettings({this.selectedMenuBuilder, this.unSelectedMenuBuilder});
}

class FancyMenuItem {
  String? menuIcon;
  String menuName;
  List<FancyMenuItem>? subMenus;
  Function()? onEnterMenu;
  final TextStyle? textStyle;
  final TextStyle? unselectedTextStyle;

  FancyMenuItem({
    required this.menuName,
    this.menuIcon,
    this.subMenus,
    this.onEnterMenu,
    this.textStyle,
    this.unselectedTextStyle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FancyMenuItem &&
          runtimeType == other.runtimeType &&
          menuName == other.menuName;

  @override
  int get hashCode => menuName.hashCode;
}
