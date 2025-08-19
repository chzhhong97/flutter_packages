import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:jc_widgets/src/custom_pull_to_refresh/custom_pull_to_refresh.dart';
import 'package:jc_widgets/src/sliver_pinned_overlap_injector.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:collection/collection.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

export 'package:scrollview_observer/scrollview_observer.dart';

typedef WrapperBuilder = Widget Function(BuildContext context, Widget child);
typedef GroupHeaderBuilder<T> = Widget Function(
    BuildContext context, int index, T item, SliverStickyHeaderState state);
typedef GroupItemBuilder<T> = Widget Function(
    BuildContext context, int index, T item, bool isSelected, bool isEmpty);
typedef GroupTabBarBuilder<T> = TabBar Function(BuildContext context,
    TabController tabController, List<T>, void Function(int index) onTap);
typedef ModelItemBuilder<T, C> = Widget Function(
  BuildContext context,
  int index,
  C group,
  T item,
);
typedef GridItemBuilder<T, C> = Widget? Function(
    BuildContext context, int index, C group, T item, double width);
typedef GroupBy<T, C> = C? Function(T element);
typedef SortGroupBy<T> = int Function(T a, T b);
typedef SortGroupItemBy<T, C> = int Function(C group, T a, T b);
typedef ItemSeparatorBuilder = Widget Function(BuildContext context, int index);
typedef ItemListBuilder<T, C> = Widget Function(
    BuildContext context,
    int index,
    C group,
    List<T> itemList,
    void Function(BuildContext context) onContextCreated);
typedef GridViewBuilder<T, C> = Widget Function(
    BuildContext context,
    int index,
    C group,
    List<T> itemList,
    BoxConstraints constraints,
    void Function(BuildContext context) onContextCreated);
typedef OnScroll = void Function(double offset);

class GroupListPlus<T, C> extends StatefulWidget {
  final List<T> itemList;
  final GroupBy<T, C> groupBy;
  //Can provide group list display group item that not include in item list
  final List<C> groupList;
  final SortGroupBy<C>? sortGroupBy;
  final SortGroupItemBy<T, C>? sortGroupItemBy;

  /// Header Builder for grouped item list
  final GroupHeaderBuilder<C>? groupHeaderBuilder;

  /// Item Builder for item list
  final ModelItemBuilder<T, C>? itemBuilder;

  /// Builder for whole item list
  final ItemListBuilder<T, C>? itemListBuilder;
  /// Separator Between Item in Item List
  final ItemSeparatorBuilder? itemSeparatorBuilder;

  /// Can provide container to wrap the item list
  final WrapperBuilder? itemListContainer;

  /// Can provide container to wrap the group list
  final WrapperBuilder? groupListContainer;

  /// Item Builder for group list, will use TabBar if one of the item is tabbar
  ///
  /// [isEmpty] will be true if this group item list is empty
  final GroupItemBuilder<C>? groupItemBuilder;

  /// Separator Between Item in Group List
  final ItemSeparatorBuilder? groupListSeparatorBuilder;

  /// Separator Between Each Group in Item List
  final ItemSeparatorBuilder? groupSeparatorBuilder;

  /// Separator Between Group List and Item List
  final Widget Function(BuildContext context)? listSeparatorBuilder;
  final OnScroll? onScrollOffset;
  final EdgeInsets groupListPadding;
  final EdgeInsets subListPadding;
  final EdgeInsets contentPadding;
  final Axis axis;
  final ScrollPhysics? groupScrollPhysics;
  final ScrollPhysics? listScrollPhysics;
  final RefreshIndicatorSettings refreshSettings;
  final Future<void> Function()? onRefresh;
  final double Function(double offset)? scrollOffset;
  final double? groupListFlex;
  final AutoScrollController<T, C>? autoScrollController;
  final NestedScrollViewHeaderSliversBuilder? sliverHeaderList;
  final Widget? emptyWidget;

  /// Provide a TabBar if want to use TabBar for horizontal group
  final GroupTabBarBuilder<C>? groupTabBarBuilder;
  final bool enabled;

  /// Avoid using same child for TabBarView, only allow to assign one child inside TabBarView children
  final Widget Function(BuildContext context, Widget child)
      nestedScrollViewBodyBuilder;

  /// Grid View Config for grid view
  final GridViewConfig? gridViewConfig;
  final GridItemBuilder<T, C>? gridItemBuilder;
  final GridViewBuilder<T, C>? gridViewBuilder;

  /// GroupListPlus<Item, Group>
  const GroupListPlus({
    super.key,
    required this.itemList,
    required this.groupBy,
    this.groupList = const [],
    this.sortGroupBy,
    this.sortGroupItemBy,
    this.groupHeaderBuilder,
    this.itemListBuilder,
    this.itemBuilder,
    this.itemSeparatorBuilder,
    this.itemListContainer,
    this.groupListContainer,
    this.groupItemBuilder,
    this.groupListSeparatorBuilder,
    this.groupSeparatorBuilder,
    this.listSeparatorBuilder,
    this.groupListPadding = EdgeInsets.zero,
    this.subListPadding = EdgeInsets.zero,
    this.contentPadding = EdgeInsets.zero,
    this.onScrollOffset,
    this.axis = Axis.horizontal,
    this.groupScrollPhysics,
    this.listScrollPhysics,
    this.refreshSettings = const RefreshIndicatorSettings(),
    this.onRefresh,
    this.scrollOffset,
    this.groupListFlex,
    this.autoScrollController,
    this.sliverHeaderList,
    this.emptyWidget,
    this.groupTabBarBuilder,
    this.nestedScrollViewBodyBuilder = _defaultNestedScrollViewBodyBuilder,
    this.enabled = true,
  })  : gridViewConfig = null,
        gridItemBuilder = null,
        gridViewBuilder = null;

  const GroupListPlus.gridView({
    super.key,
    required this.itemList,
    required this.groupBy,
    required GridViewConfig gridViewConfig,
    this.groupList = const [],
    this.sortGroupBy,
    this.sortGroupItemBy,
    this.groupHeaderBuilder,
    GridViewBuilder<T, C>? itemListBuilder,
    GridItemBuilder<T, C>? itemBuilder,
    //this.itemSeparatorBuilder,
    this.itemListContainer,
    this.groupListContainer,
    this.groupItemBuilder,
    this.groupListSeparatorBuilder,
    this.groupSeparatorBuilder,
    this.listSeparatorBuilder,
    this.groupListPadding = EdgeInsets.zero,
    this.subListPadding = EdgeInsets.zero,
    this.contentPadding = EdgeInsets.zero,
    this.onScrollOffset,
    this.axis = Axis.horizontal,
    this.groupScrollPhysics,
    this.listScrollPhysics,
    this.refreshSettings = const RefreshIndicatorSettings(),
    this.onRefresh,
    this.scrollOffset,
    this.groupListFlex,
    this.autoScrollController,
    this.sliverHeaderList,
    this.emptyWidget,
    this.groupTabBarBuilder,
    this.nestedScrollViewBodyBuilder = _defaultNestedScrollViewBodyBuilder,
    this.enabled = true,
  })  : gridViewConfig = gridViewConfig,
        gridItemBuilder = itemBuilder,
        gridViewBuilder = itemListBuilder,
        itemBuilder = null,
        itemListBuilder = null,
        itemSeparatorBuilder = null;

  static Widget _defaultNestedScrollViewBodyBuilder(
          BuildContext context, Widget child) =>
      child;

  @override
  State<StatefulWidget> createState() => _GroupListPlusState<T, C>();
}

class _GroupListPlusState<T, C> extends State<GroupListPlus<T, C>>
    with TickerProviderStateMixin
    implements AutoScrollInterface<T, C> {
  final Map<C, List<T>> groupDictionary = {};
  final ValueNotifier<Map<C, List<T>>> _displayList = ValueNotifier({});

  final ValueNotifier<int> currentGroupIndex = ValueNotifier(0);
  final ScrollController _nestedScrollController = ScrollController();
  final ScrollController _groupScrollController = ScrollController();
  late final SliverObserverController _observerController =
      SliverObserverController(controller: _nestedScrollController);
  late final SliverScrollUtil _scrollUtil =
      SliverScrollUtil(scrollController: _observerController);
  final Map<int, double> sliverChildLengthMap = {};
  final Set<int> displayHeader = {};
  final List<GlobalKey> _keys = [];
  final GlobalKey _nestedScrollKey = GlobalKey();
  final GlobalKey _horizontalGroupKey = GlobalKey();
  final GlobalKey<RectGetterState> _listKey = RectGetter.createGlobalKey();
  final GlobalKey<RectGetterState> _sliverPinnedInjectorKey =
      RectGetter.createGlobalKey();
  final Map<int, GlobalKey<RectGetterState>> _groundHeaderKeys = {};
  final _nestedScrollUtil = NestedScrollUtil();
  late TabController _tabController;
  bool isAnimating = false;

  double lastLeftOffset = 0;
  double lastRightOffset = 0;

  @override
  void initState() {
    super.initState();

    widget.autoScrollController?.attach(this);

    updateList();
    _tabController =
        TabController(length: _displayList.value.keys.length, vsync: this);
  }

  @override
  void didUpdateWidget(covariant GroupListPlus<T, C> oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (oldWidget.autoScrollController != widget.autoScrollController) {
        oldWidget.autoScrollController?.detach(this);
        widget.autoScrollController?.attach(this);
      }

      if (oldWidget.itemList != widget.itemList) {
        updateList();
        resetController();
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    _groupScrollController.dispose();
    widget.autoScrollController?.detach(this);
    super.dispose();
  }

  void updateList() {
    groupDictionary
      ..clear()
      ..addEntries(
        widget.itemList
            .groupListsBy<C?>((element) => widget.groupBy(element))
            .entries
            .where((entry) => entry.key != null)
            .map((entry) => MapEntry(entry.key as C, entry.value)),
      );

    if (widget.groupList.isNotEmpty) {
      for (var element in widget.groupList) {
        groupDictionary.putIfAbsent(element, () => List.empty());
      }
    }

    _sortList();
    /*for (final c in widget.categoryList!) {
        final list = widget.itemList
            .where((element) => widget.onMap?.call(element, c) ?? false);
        categoryMap[c] = list.toList();
      }*/

    _keys.clear();
    _keys.addAll(List.generate(groupDictionary.length, (index) => GlobalKey()));

    _displayList.value = Map.of(groupDictionary);
    /*if (context.mounted) {
      setState(() {});
    }*/
  }

  void resetController() {
    for (var ctx in _scrollUtil.allListContext) {
      _observerController.clearScrollIndexCache(sliverContext: ctx);
    }
    _scrollUtil.reset();
    _observerController.reattach();

    if (_nestedScrollController.hasClients) _nestedScrollController.jumpTo(0);
    if (_groupScrollController.hasClients) _groupScrollController.jumpTo(0);

    _tabController.dispose();
    _tabController =
        TabController(length: _displayList.value.keys.length, vsync: this);

    currentGroupIndex.value = 0;
  }

  void _sortList() {
    final sortedMapByKey = Map.fromEntries(groupDictionary.entries.toList()
      ..sort((a, b) => widget.sortGroupBy?.call(a.key, b.key) ?? 0));

    for (var key in sortedMapByKey.keys) {
      sortedMapByKey[key]
          ?.sort((a, b) => widget.sortGroupItemBy?.call(key, a, b) ?? 0);
    }

    groupDictionary.clear();
    groupDictionary.addAll(sortedMapByKey);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.contentPadding,
      child: SliverViewObserver(
        controller: _observerController,
        sliverContexts: () => _scrollUtil.allListContext,
        /*onObserveAll: (resultMap) {
          return;

          for (final e in resultMap.entries) {
            final index = reverseSearch(_scrollUtil.groupListContext, e.key);

            if (index == null) continue;

            if (!e.value.visible) {
              displayHeader.remove(index);
              if (displayHeader.isNotEmpty) {
                currentGroupIndex.value = displayHeader.reduce(
                        (value, element) => value < element ? value : element);
                scrollToGroup(_keys[currentGroupIndex.value].currentContext);
              }
              continue;
            }

            displayHeader.add(index);

            */ /*if(displayHeader.isNotEmpty && !displayHeader.contains(sliverContextMap.length - 1)){
            currentCategoryIndex.value = displayHeader.reduce((value, element) => value < element ? value : element);
          }
          else if(index == sliverContextMap.length - 1){
            currentCategoryIndex.value = index;
          }*/ /*
            currentGroupIndex.value = displayHeader
                .reduce((value, element) => value < element ? value : element);
            scrollToGroup(_keys[currentGroupIndex.value].currentContext);
          }
        },*/
        customOverlap: (context) {
          return _nestedScrollUtil.calcOverlap(
              nestedScrollViewKey: _nestedScrollKey, sliverContext: context);
        },
        child: CustomPullToRefresh(
          settings: widget.refreshSettings,
          onRefresh: widget.onRefresh,
          child: _buildSliverNestedScrollView(context),
        ),
      ),
    );
  }

  Widget _buildSliverNestedScrollView(BuildContext context) {
    return NestedScrollView(
        key: _nestedScrollKey,
        controller: _nestedScrollController,
        physics: widget.enabled
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        headerSliverBuilder: (context, _) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: MultiSliver(
                children: [
                  ...(widget.sliverHeaderList?.call(context, _) ?? []),
                ],
              ),
            )
          ];
        },
        body: Builder(
          builder: (context) {
            return widget.nestedScrollViewBodyBuilder(
              context,
              ValueListenableBuilder(
                valueListenable: _displayList,
                builder: (BuildContext context, Map<C, List<T>> value,
                    Widget? child) {
                  int groupFlex = 1;
                  int itemFlex = 1;
                  if (widget.groupListFlex != null) {
                    groupFlex = widget.groupListFlex!.toInt().abs();
                    if (widget.groupListFlex! <= 1) {
                      groupFlex = (widget.groupListFlex! * 100).toInt().abs();
                    }
                    if (groupFlex > 100) groupFlex = 100;
                    itemFlex = 100 - groupFlex;
                  }

                  _observerController.controller =
                      PrimaryScrollController.of(context);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.axis == Axis.vertical)
                        Expanded(
                          flex: groupFlex,
                          child: CustomScrollView(
                            controller: ScrollController(),
                            slivers: [
                              SliverPinnedOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                              ),
                              SliverFillRemaining(
                                hasScrollBody: true,
                                child: _buildGroupList(groupFlex),
                              )
                            ],
                          ),
                        ),
                      if (widget.listSeparatorBuilder != null)
                        widget.listSeparatorBuilder!(context),
                      Expanded(
                          flex: itemFlex,
                          child: RectGetter(
                            key: _listKey,
                            child: LayoutBuilder(
                              builder: (layoutContext, constraints) {
                                return NotificationListener<ScrollNotification>(
                                  onNotification: _onScrollNotification,
                                  child: CustomScrollView(
                                    physics: widget.enabled
                                        ? widget.listScrollPhysics
                                        : const NeverScrollableScrollPhysics(),
                                    slivers: [
                                      RectGetter(
                                          key: _sliverPinnedInjectorKey,
                                          child: SliverPinnedOverlapInjector(
                                            handle: NestedScrollView
                                                .sliverOverlapAbsorberHandleFor(
                                                    context),
                                          )),
                                      if (widget.axis == Axis.horizontal)
                                        SliverPinnedHeader(
                                          child: _buildGroupList(groupFlex),
                                        ),
                                      if (value.isNotEmpty) ...[
                                        ...value.keys
                                            .mapIndexed((index, element) {
                                          return _buildSliver(
                                              context,
                                              index,
                                              element,
                                              value[element] ?? [],
                                              constraints);
                                        }),
                                      ] else ...[
                                        SliverFillRemaining(
                                          hasScrollBody: true,
                                          child: widget.emptyWidget ??
                                              const SizedBox(),
                                        ),
                                      ]
                                    ],
                                  ),
                                );
                              },
                            ),
                          )),
                    ],
                  );
                },
              ),
            );
          },
        ));
  }

  bool _onScrollNotification(ScrollNotification notification) {
    widget.onScrollOffset
        ?.call(_scrollUtil.scrollController.controller?.offset ?? 0);

    if (isAnimating) return true;

    int lastIndex = _displayList.value.keys.length - 1;
    var visibleGroup = _getVisibleItemsIndex();

    if (visibleGroup.isEmpty) return true;

    var scrollController = _scrollUtil.scrollController.controller;
    if (scrollController != null) {
      if (scrollController.offset <= 10) {
        currentGroupIndex.value =
            currentGroupIndex.value > 0 ? visibleGroup.first : 0;
        scrollToGroup(_keys[currentGroupIndex.value].currentContext,
            currentGroupIndex.value);
        return false;
      }

      var maxScrollExtent = scrollController.position.maxScrollExtent;
      if (scrollController.offset >= maxScrollExtent - 10) {
        currentGroupIndex.value =
            visibleGroup.contains(lastIndex) ? lastIndex : visibleGroup.last;
        scrollToGroup(_keys[currentGroupIndex.value].currentContext,
            currentGroupIndex.value);
        return false;
      }
    }

    int sumIndex = visibleGroup.reduce((value, element) => value + element);
    int middleIndex = sumIndex ~/ visibleGroup.length;

    currentGroupIndex.value = middleIndex;

    scrollToGroup(
        _keys[currentGroupIndex.value].currentContext, currentGroupIndex.value);
    return false;
  }

  List<int> _getVisibleItemsIndex() {
    List<int> items = [];

    try {
      var rect = RectGetter.getRectFromKey(_listKey);
      var pinnedRect = RectGetter.getRectFromKey(_sliverPinnedInjectorKey);

      if (rect == null) return items;

      var top = (rect.top + (pinnedRect?.height ?? 0)).toInt();
      var bottom = rect.bottom.toInt();

      _groundHeaderKeys.forEach((index, e) {
        var itemRect = RectGetter.getRectFromKey(e);
        if (itemRect == null) return;
        if (itemRect.top.toInt() >= bottom) return;
        if (itemRect.bottom.toInt() <= top) return;
        items.add(index);
      });
    } catch (e) {
      //print(e);
    }

    return items;
  }

  Widget buildBody(
    BuildContext context, {
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    if (widget.axis == Axis.vertical) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  Widget _buildGroupList(int groupFlex) {
    if(groupFlex <= 0) return const SizedBox();
    if (_displayList.value.isEmpty) return const SizedBox();

    final content = ValueListenableBuilder(
      key: widget.axis == Axis.horizontal ? _horizontalGroupKey : null,
      valueListenable: _displayList,
      builder:
          (BuildContext context, Map<C, List<T>> dictionary, Widget? child) {
        if (widget.axis == Axis.horizontal &&
            widget.groupTabBarBuilder != null) {
          return Padding(
            padding: widget.groupListPadding,
            child: widget.groupTabBarBuilder!(
              context,
              _tabController,
              dictionary.keys.toList(),
              (index) => autoScrollTo(groupIndex: index),
            ),
          );
        }

        return SingleChildScrollView(
          padding: widget.groupListPadding,
          scrollDirection: widget.axis,
          controller: _groupScrollController,
          physics: widget.enabled
              ? widget.groupScrollPhysics
              : const NeverScrollableScrollPhysics(),
          child: ValueListenableBuilder(
            valueListenable: currentGroupIndex,
            builder: (BuildContext context, int value, Widget? child) {

              return buildGroupLayout(context,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < dictionary.keys.length; i++) ...[
                      InkWell(
                        key: _keys[i],
                        onTap: () => autoScrollTo(groupIndex: i),
                        child: widget.groupItemBuilder?.call(
                            context,
                            i,
                            dictionary.keys.elementAt(i),
                            i == value,
                            dictionary[dictionary.keys.elementAt(i)]
                                ?.isNotEmpty !=
                                true) ??
                            Container(
                              color: i == value ? Colors.red : Colors.white,
                              child: Text(
                                dictionary.keys.elementAt(i).toString(),
                                style: TextStyle(
                                  color:
                                  i == value ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                      ),
                      if (i != dictionary.keys.length - 1)
                        widget.groupListSeparatorBuilder?.call(context, i) ??
                            const SizedBox(),
                    ]
                  ]
              );
            },
          ),
        );
      },
    );

    return widget.groupListContainer?.call(context, content) ??
        Container(
          width: 100,
          color: Colors.white,
          child: content,
        );
  }

  Widget buildGroupLayout(
    BuildContext context, {
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    if (widget.axis == Axis.horizontal) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  Widget _buildSliver(BuildContext context, int index, C group,
      List<T> itemList, BoxConstraints constraints) {
    if (itemList.isEmpty) {
      return const SliverToBoxAdapter();
    }

    return MultiSliver(
      children: [
        SliverStickyHeader.builder(
          key: ValueKey(index),
          builder: (context, state) {
            _groundHeaderKeys[index] = RectGetter.createGlobalKey();

            return RectGetter(
              key: _groundHeaderKeys[index]!,
              child: widget.groupHeaderBuilder
                      ?.call(context, index, group, state) ??
                  Text(
                    group.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
            );
          },
          sliver: SliverPadding(
            padding: widget.subListPadding,
            sliver: SliverClip(
              child: Builder(
                builder: (_) {
                  if (widget.gridViewConfig != null) {
                    return _buildGridView(
                        context, index, group, itemList, constraints.copyWith(
                      maxWidth: constraints.maxWidth - widget.subListPadding.horizontal,
                    ));
                  }

                  return _buildListView(context, index, group, itemList);
                },
              ),
            ),
          ),
        ),
        if (widget.groupSeparatorBuilder != null)
          SliverToBoxAdapter(
            child: widget.groupSeparatorBuilder!(context, index),
          ),
      ],
    );
  }

  Widget _buildListView(
      BuildContext context, int index, C group, List<T> itemList) {
    if (widget.itemListBuilder != null) {
      return widget.itemListBuilder!(context, index, group, itemList,
          (context) {
        _scrollUtil.addGroupListContext(index, context);
      });
    }

    return SliverList.separated(
      itemBuilder: (context, itemIndex) {
        _scrollUtil.addGroupListContext(index, context);

        return widget.itemBuilder
                ?.call(context, itemIndex, group, itemList[itemIndex]) ??
            Text(itemList[itemIndex].toString());
      },
      separatorBuilder: (context, index) {
        return widget.itemSeparatorBuilder?.call(context, index) ??
            const SizedBox();
      },
      itemCount: itemList.length,
    );
  }

  Widget _buildGridView(BuildContext context, int index, C group,
      List<T> itemList, BoxConstraints constraints) {
    if (widget.gridViewConfig == null) {
      return SliverToBoxAdapter(
        child: ErrorWidget(FlutterError("GridViewConfig is needed")),
      );
    }

    if (widget.gridViewBuilder != null) {
      return widget.gridViewBuilder!(
          context, index, group, itemList, constraints, (context) {
        _scrollUtil.addGroupListContext(index, context);
      });
    }
    final config = widget.gridViewConfig!;
    final listItemCount = (itemList.length / config.crossAxisCount).ceil();

    return SliverList.separated(
      itemBuilder: (context, itemIndex) {
        _scrollUtil.addGroupListContext(index, context);

        buildGrid(BuildContext context, int index, int? childCount, double width) {
          final childIndex = itemIndex * config.crossAxisCount + index;
          if (childIndex < 0 || (childCount != null && childIndex >= childCount)) {
            return null;
          }

          return Padding(
            padding: EdgeInsets.only(
              right: (index < config.crossAxisCount - 1) ? config.crossAxisSpacing : 0,
            ),
            child: SizedBox(
              width: width,
              child: widget.gridItemBuilder
                  ?.call(context, childIndex, group, itemList[childIndex], width) ??
                  Text(itemList[childIndex].toString()),
            ),
          );
        }

        final children = [
          for (int i = 0; i < config.crossAxisCount; i++) ...[
            buildGrid(context, i, itemList.length,
                _getGridItemWidth(config.crossAxisCount, config.crossAxisSpacing, constraints.maxWidth)),
          ]
        ].whereType<Widget>().toList();

        if (children.isEmpty) return const SizedBox();

        return Row(
          mainAxisAlignment: config.mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(
          height: config.mainAxisSpacing,
        );
      },
      itemCount: listItemCount,
      findChildIndexCallback: config.findChildIndexCallback,
      addSemanticIndexes: config.addSemanticIndexes,
      addRepaintBoundaries: config.addRepaintBoundaries,
      addAutomaticKeepAlives: config.addAutomaticKeepAlives,
    );
  }

  double _getGridItemWidth(
      int crossAxisCount, double crossAxisSpacing, double maxWidth) {
    return (maxWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
        crossAxisCount;
  }

  void scrollToGroup(BuildContext? context, int index) {
    _tabController.animateTo(index,
        duration: const Duration(milliseconds: 200));

    if (context != null && context.findRenderObject() != null) {
      /*Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );*/
      _groupScrollController.position.ensureVisible(
        context.findRenderObject()!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  Map<K, V> reverseMap<K, V>(Map<K, V> map, V value) {
    for (var entry in map.entries) {
      if (entry.value == value) {
        return {entry.key: value};
      }
    }
    return {};
  }

  K? reverseSearch<K, V>(Map<K, V> map, V value) {
    for (var entry in map.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<void> autoScrollBy(
      {FutureOr<bool> Function(C group)? isGroup,
      FutureOr<bool> Function(T item)? isItem}) async {
    if (isGroup == null) return;

    final keys = groupDictionary.keys.toList();
    final groupIndex = await keys.asyncIndexWhere((e) => isGroup(e));

    if (groupIndex == -1) return;

    int? itemIndex;
    if (isItem != null) {
      final itemList = groupDictionary[keys[groupIndex]] ?? [];
      final index = await itemList.asyncIndexWhere((e) => isItem(e));

      if (index != -1) itemIndex = index;
    }

    return autoScrollTo(groupIndex: groupIndex, itemIndex: itemIndex);
  }

  @override
  Future<void> autoScrollTo({int? groupIndex = 0, int? itemIndex}) async {
    if (groupIndex == null) return;

    if (isAnimating) return;
    isAnimating = true;

    final sliverContext = _scrollUtil.getListContext(groupIndex);
    if (sliverContext == null) {
      isAnimating = false;
      return;
    }

    final current = currentGroupIndex.value;
    currentGroupIndex.value = groupIndex;
    scrollToGroup(_keys[groupIndex].currentContext, groupIndex);

    //_nestedScrollController.jumpTo(_nestedScrollController.position.pixels);
    if (_observerController.controller != null)
      _observerController.controller!
          .jumpTo(_observerController.controller!.position.pixels);

    // set to last item index if the index provided is more than list length
    final itemLength =
        groupDictionary[groupDictionary.keys.elementAt(groupIndex)]?.length ??
            0;
    if (itemIndex != null && itemLength > 0 && itemIndex >= itemLength) {
      itemIndex = itemLength - 1;
    }

    await _scrollUtil.autoScrollTo(
        groupIndex: groupIndex,
        itemIndex: itemIndex,
        currentGroupIndex: current,
        offset: (offset) {
          var additionalOffset = widget.scrollOffset?.call(offset) ?? 0;

          additionalOffset +=
              _horizontalGroupKey.currentContext?.size?.height ?? 0;
          if (itemIndex == 0 || itemIndex == null)
            additionalOffset += widget.subListPadding.top;
          if (widget.gridViewConfig != null && itemIndex != null) {
            // for fixed cross axis can ez calculate if item index more than cross count
            // if next line then we need to add additional offset for auto scroll
            if ((itemIndex + 1) > widget.gridViewConfig!.crossAxisCount) {
              additionalOffset += widget.gridViewConfig!.mainAxisSpacing;
            }
          }

          //print(additionalOffset);
          return additionalOffset;
        });

    displayHeader.clear();
    displayHeader.add(groupIndex);
    isAnimating = false;
  }

  @override
  void filterList(
      {bool Function(C group)? onFilterGroup,
      bool Function(T item)? onFilterItem}) {
    final temp = Map.of(groupDictionary);

    if (onFilterGroup != null) {
      temp.removeWhere((key, value) => !onFilterGroup(key));
    }

    if (onFilterItem != null) {
      temp.updateAll((key, value) {
        final newList = List.of(value);
        return newList.where(onFilterItem).toList();
      });
    }

    _keys.clear();
    _keys.addAll(List.generate(temp.length, (index) => GlobalKey()));
    displayHeader.clear();
    _displayList.value = temp;
    resetController();

    final index =
        temp.keys.toList().indexWhere((k) => temp[k]?.isEmpty != true);
    if (currentGroupIndex.value == index) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      autoScrollTo(groupIndex: index != -1 ? index : 0);
    });
  }
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E element) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));

  Future<int> asyncIndexWhere(FutureOr<bool> Function(E) test,
      [int start = 0]) async {
    for (int i = start; i < length; i++) {
      if (await test(elementAt(i))) {
        return i;
      }
    }

    return -1;
  }
}

interface class AutoScrollInterface<T, C> {
  Future<void> autoScrollTo({int? groupIndex, int? itemIndex}) async {}
  Future<void> autoScrollBy(
      {FutureOr<bool> Function(C group)? isGroup,
      FutureOr<bool> Function(T item)? isItem}) async {}

  void filterList(
      {bool Function(C group)? onFilterGroup,
      bool Function(T item)? onFilterItem}) {}
}

class AutoScrollController<T, C> implements AutoScrollInterface<T, C> {
  AutoScrollInterface<T, C>? _autoScrollInterface;

  void attach(AutoScrollInterface<T, C> autoScroll) {
    _autoScrollInterface = autoScroll;
  }

  void detach(AutoScrollInterface<T, C> autoScroll) {
    if (_autoScrollInterface != autoScroll) return;
    _autoScrollInterface = null;
  }

  @override
  Future<void> autoScrollBy(
      {FutureOr<bool> Function(C group)? isGroup,
      FutureOr<bool> Function(T item)? isItem}) async {
    return _autoScrollInterface?.autoScrollBy(isGroup: isGroup, isItem: isItem);
  }

  @override
  Future<void> autoScrollTo({int? groupIndex, int? itemIndex}) async {
    return _autoScrollInterface?.autoScrollTo(
        groupIndex: groupIndex, itemIndex: itemIndex);
  }

  @override
  void filterList(
      {bool Function(C group)? onFilterGroup,
      bool Function(T item)? onFilterItem}) {
    return _autoScrollInterface?.filterList(
        onFilterGroup: onFilterGroup, onFilterItem: onFilterItem);
  }
}

class SliverScrollUtil {
  final SliverObserverController scrollController;
  final Map<int, BuildContext> groupListContext;

  List<BuildContext> get allListContext => groupListContext.values.toList();

  SliverScrollUtil({
    required this.scrollController,
    Map<int, BuildContext>? groupListContext,
  }) : groupListContext = groupListContext ?? {};

  void addGroupListContext(int groupIndex, BuildContext context) {
    if (groupListContext[groupIndex] != context)
      groupListContext[groupIndex] = context;
  }

  BuildContext? getListContext(int groupIndex) => groupListContext[groupIndex];

  void reset() {
    groupListContext.clear();
  }

  Future<void> autoScrollTo(
      {int? groupIndex,
      int? itemIndex,
      int? currentGroupIndex,
      Duration? duration,
      Curve? curve,
      double Function(double offset)? offset}) async {
    if (groupIndex == null) return;

    final context = getListContext(groupIndex);

    if (context == null) return;

    if (currentGroupIndex != null &&
        (currentGroupIndex - groupIndex).abs() > 1) {
      //Jump first
      final previousIndex =
          currentGroupIndex > groupIndex ? groupIndex + 1 : groupIndex - 1;
      final previousContext = getListContext(previousIndex);

      if (previousContext != null) {
        await scrollController.jumpTo(
          index: 0,
          sliverContext: previousContext,
        );
      }
    }

    await scrollController.animateTo(
        sliverContext: context,
        index: itemIndex ?? 0,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOut,
        offset: (maxOffset) {
          double newOffset = 0;

          if (offset != null) newOffset += offset(maxOffset);

          return newOffset;
        });

    if (currentGroupIndex != null && groupIndex > currentGroupIndex) {
      await Future.delayed(const Duration(milliseconds: 10));

      await scrollController.jumpTo(
          index: itemIndex ?? 0,
          sliverContext: context,
          offset: (maxOffset) {
            double newOffset = 0;
            if (offset != null) newOffset += offset(maxOffset);
            return newOffset;
          });
    }

    currentGroupIndex = groupIndex;
  }
}

class GridViewConfig {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int? Function(Key)? findChildIndexCallback;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final MainAxisAlignment mainAxisAlignment;

  GridViewConfig(
      {required this.crossAxisCount,
      this.crossAxisSpacing = 0.0,
      this.mainAxisSpacing = 0.0,
      this.findChildIndexCallback,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.addSemanticIndexes = true,
      this.mainAxisAlignment = MainAxisAlignment.start});
}
