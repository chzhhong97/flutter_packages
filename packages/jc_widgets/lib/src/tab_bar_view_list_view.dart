import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jc_widgets/src/custom_pull_to_refresh/custom_pull_to_refresh.dart';
import 'package:jc_widgets/src/sliver_pinned_overlap_injector.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TabBarViewListView<T, G> extends StatefulWidget{
  const TabBarViewListView({
    super.key,
    required this.itemList,
    required this.groupBy,
    this.groupList = const [],
    this.groupAllBy,
    this.sortGroupBy,
    this.sortGroupItemBy,
    this.useSliver = false,
    this.tabBarBuilder,
    this.emptyBuilder,
    this.tabBarDecoration,
    this.listDecoration,
    this.listBuilder,
    this.listItemBuilder,
    this.listItemSeparatorBuilder,
    this.tabFooterBuilder,
    this.tabBarHeaderBuilder,
    this.physics,
    this.separatorBuilder,
    this.listHeaderBuilder,
    this.listFooterBuilder,
    this.onTabControllerCreated,
    this.onTabBarChanged,
    this.listPadding,
    this.onRefresh,
    this.refreshIndicatorSettings = const RefreshIndicatorSettings(),
    this.hideSingleTabBar = false,
    this.emptyTabBarView,

    this.isScrollable = false,
    this.tabBarPadding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.tabBarPhysics,
    this.splashFactory,
    this.splashBorderRadius,
    this.tabAlignment,
    this.tabBarViewPhysics,
    this.clipBehavior = Clip.hardEdge,
  });

  //region TabBar
  final bool isScrollable;
  final EdgeInsetsGeometry? tabBarPadding;
  final EdgeInsetsGeometry? listPadding;
  final Color? indicatorColor;
  final double indicatorWeight;
  final EdgeInsetsGeometry indicatorPadding;
  final Decoration? indicator;
  final bool automaticIndicatorColorAdjustment;
  final TabBarIndicatorSize? indicatorSize;
  final Color? dividerColor;
  final double? dividerHeight;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final WidgetStateProperty<Color?>? overlayColor;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final bool? enableFeedback;
  final ValueChanged<int>? onTap;
  final ScrollPhysics? tabBarPhysics;
  final InteractiveInkFeatureFactory? splashFactory;
  final BorderRadius? splashBorderRadius;
  final TabAlignment? tabAlignment;
  //endregion

  //region TabBarView
  final ScrollPhysics? tabBarViewPhysics;
  final Clip clipBehavior;
  //endregion

  //region TabBarViewListView
  final List<T> itemList;
  final List<G> groupList;
  final G? Function(T element) groupBy;
  final G? Function()? groupAllBy;
  final int Function(G a, G b)? sortGroupBy;
  final int Function(G g, T a, T b)? sortGroupItemBy;
  final Widget Function(BuildContext context, G item, int index)? tabBarBuilder;
  final Widget Function(BuildContext context, G item, int index)? emptyBuilder;
  final BoxDecoration Function(BuildContext context, G item, int index)? listDecoration;
  final BoxDecoration Function(BuildContext context)? tabBarDecoration;
  final Widget Function(BuildContext context, T item, G group, int itemIndex)? listItemBuilder;
  ///Widget to replace listview, can use this if want to replace listview to animated list view
  ///
  ///Provide Sliver Widget if useSliver is true
  final Widget Function(BuildContext context, G group, int tabIndex, List<T> itemList)? listBuilder;
  final Widget Function(BuildContext context, G group, int itemIndex)? listItemSeparatorBuilder;
  ///Widget between TabBar and TabBarView, which persist even change of TabBarView page
  ///
  ///Provide Sliver Widget if useSliver is true
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)? separatorBuilder;
  ///Widget before TabBar
  ///
  ///Provide Sliver Widget if useSliver is true
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)? tabBarHeaderBuilder;
  ///Widget before the list, con provide different widget base on TabBar index
  ///
  /// Where callback is provided for filter function
  ///
  ///Provide Sliver Widget if useSliver is true
  final List<Widget> Function(BuildContext context, G group, Function(bool Function(T) where) onFilter)? listHeaderBuilder;
  ///ListView footer for each TabBarView
  ///
  ///Provide Normal widget for both useSliver or not
  final Widget Function(BuildContext context, G group,)? listFooterBuilder;
  ///Widget after TabBarView
  ///
  ///Provide Normal widget for both useSliver or not
  final Widget Function(BuildContext context)? tabFooterBuilder;
  final void Function(TabController controller)? onTabControllerCreated;
  final void Function(int index, G group)? onTabBarChanged;
  ///Use sliver if you want to use this
  final Future<void> Function()? onRefresh;
  final RefreshIndicatorSettings refreshIndicatorSettings;
  final bool useSliver;
  final ScrollPhysics? physics;
  final bool hideSingleTabBar;
  final WidgetBuilder? emptyTabBarView;
  //endregion

  @override
  State<TabBarViewListView<T, G>> createState() => _TabBarViewListViewState<T, G>();
}

class _TabBarViewListViewState<T, G> extends State<TabBarViewListView<T, G>>{

  final Map<G, List<T>> groupDictionary = {};
  final Map<G, List<T>> groupDictionaryDisplay = {};

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((d) => _updateList());
  }

  @override
  void didUpdateWidget(covariant TabBarViewListView<T, G> oldWidget) {
    if(oldWidget.itemList != widget.itemList){
      _updateList();
    }

    if(oldWidget.groupList != widget.groupList){
      groupDictionary.removeWhere((key, value) => value.isEmpty);
      groupDictionaryDisplay.removeWhere((key, value) => value.isEmpty);

      for(final key in widget.groupList){
        groupDictionary.putIfAbsent(key, () => List.empty());
        groupDictionaryDisplay.putIfAbsent(key, () => List.empty());
      }
    }

    _sortActual();
    _sortDisplay();

    setState(() {});

    super.didUpdateWidget(oldWidget);
  }

  void _updateList(){
    groupDictionary.clear();
    //groupDictionary.addAll(widget.itemList.groupListsBy<G>((element) => widget.groupBy(element)));

    for(final i in widget.itemList){
      var g = widget.groupBy(i);
      if(g != null){
        groupDictionary.putIfAbsent(g, () => List.empty(growable: true));
        groupDictionary.update(g, (v) => v..add(i));
      }
    }

    if(widget.groupList.isNotEmpty){
      for (var element in widget.groupList) {
        groupDictionary.putIfAbsent(element, () => List.empty());
      }
    }

    var allGroup = widget.groupAllBy?.call();
    if(allGroup != null){
      G? firstKey;
      if(groupDictionary.length == 1){
        firstKey = groupDictionary.keys.first;
      }

      groupDictionary.putIfAbsent(allGroup, () => List.of(widget.itemList));
      groupDictionary.remove(firstKey);
    }

    _sortActual();

    groupDictionaryDisplay.clear();
    groupDictionaryDisplay.addAll(Map.of(groupDictionary));

    if(context.mounted) setState(() {});
  }

  void _sortActual(){
    final sortedMapByKey = Map.fromEntries(
        groupDictionary.entries.toList()..sort(
                (a, b) => widget.sortGroupBy?.call(a.key, b.key) ?? 0
        )
    );

    for(var key in sortedMapByKey.keys){
      sortedMapByKey[key]?.sort((a, b) => widget.sortGroupItemBy?.call(key, a, b) ?? 0);
    }

    groupDictionary.clear();
    groupDictionary.addAll(sortedMapByKey);
  }

  void _sortDisplay(){
    final sortedMapByKey = Map.fromEntries(
        groupDictionaryDisplay.entries.toList()..sort(
                (a, b) => widget.sortGroupBy?.call(a.key, b.key) ?? 0
        )
    );

    for(var key in sortedMapByKey.keys){
      sortedMapByKey[key]?.sort((a, b) => widget.sortGroupItemBy?.call(key, a, b) ?? 0);
    }

    groupDictionaryDisplay.clear();
    groupDictionaryDisplay.addAll(sortedMapByKey);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildTabBarViewPlus(context),
        ),
        if(widget.tabFooterBuilder != null) widget.tabFooterBuilder!(context),
      ],
    );
  }

  Widget _buildTabBarViewPlus(BuildContext context){
    return TabBarViewPlus(
      itemCount: groupDictionaryDisplay.length,
      useSliver: widget.useSliver,
      isScrollable: widget.isScrollable,
      tabBarPadding: widget.tabBarPadding,
      indicatorColor: widget.indicatorColor,
      automaticIndicatorColorAdjustment: widget.automaticIndicatorColorAdjustment,
      indicatorWeight: widget.indicatorWeight,
      indicatorPadding: widget.indicatorPadding,
      indicator: widget.indicator,
      indicatorSize: widget.indicatorSize,
      dividerColor: widget.dividerColor,
      dividerHeight: widget.dividerHeight,
      labelColor: widget.labelColor,
      labelStyle: widget.labelStyle,
      labelPadding: widget.labelPadding,
      unselectedLabelColor: widget.unselectedLabelColor,
      unselectedLabelStyle: widget.unselectedLabelStyle,
      dragStartBehavior: widget.dragStartBehavior,
      overlayColor: widget.overlayColor,
      mouseCursor: widget.mouseCursor,
      enableFeedback: widget.enableFeedback,
      onTap: widget.onTap,
      tabBarPhysics: widget.tabBarPhysics,
      splashFactory: widget.splashFactory,
      splashBorderRadius: widget.splashBorderRadius,
      tabAlignment: widget.tabAlignment,
      tabBarViewPhysics: widget.tabBarViewPhysics,
      clipBehavior: widget.clipBehavior,
      separatorBuilder: widget.separatorBuilder,
      onTabControllerCreated: widget.onTabControllerCreated,
      onTabChanged: (index) {
        if(groupDictionaryDisplay.isNotEmpty) widget.onTabBarChanged?.call(index, groupDictionaryDisplay.keys.elementAt(index));
      },
      onRefresh: widget.onRefresh,
      refreshIndicatorSettings: widget.refreshIndicatorSettings,
      tabBarBuilder: (context, index) => widget.tabBarBuilder?.call(context, groupDictionaryDisplay.keys.elementAt(index), index) ?? Tab(text: groupDictionaryDisplay.keys.elementAt(index).toString(),),
      tabBarHeaderBuilder: widget.tabBarHeaderBuilder,
      tabBarViewBuilder: (context, tabIndex){
        var itemList = groupDictionaryDisplay[groupDictionaryDisplay.keys.elementAt(tabIndex)];

        if(widget.useSliver) return _buildSliverView(context, groupDictionaryDisplay.keys.elementAt(tabIndex), tabIndex, itemList);

        return _buildNormalView(context, groupDictionaryDisplay.keys.elementAt(tabIndex), tabIndex, itemList);
      },
      tabBarViewDecoration: widget.listDecoration != null ? (context, index){
        return widget.listDecoration!(context, groupDictionaryDisplay.keys.elementAt(index), index);
      } : null,
      tabBarDecoration: widget.tabBarDecoration,
      hideSingleTabBar: widget.hideSingleTabBar,
      emptyTabBarView: widget.emptyTabBarView,
    );
  }

  Widget _buildNormalView(BuildContext context, G group, int tabIndex, List<T>? itemList){
    if(itemList == null) return const SizedBox();

    return Column(
      children: [
        if(widget.listHeaderBuilder != null)
          ...widget.listHeaderBuilder!(context, group, (where) => _onFilter(group, where)),
        itemList.isEmpty ?
        widget.emptyBuilder?.call(context, group, tabIndex) ?? const Center(child: Text('Empty List'),) :
        Expanded(
          child: widget.listBuilder?.call(context, group, tabIndex, itemList) ?? ListView.separated(
              padding: widget.listPadding,
              itemBuilder: (context, index){
                if(index == itemList.length){
                  return widget.listFooterBuilder?.call(context, group);
                }

                return widget.listItemBuilder?.call(context, itemList[index], group, index) ?? Text(itemList[index].toString());
              },
              separatorBuilder: (context, index) => widget.listItemSeparatorBuilder?.call(context, group, index) ?? const SizedBox(),
              itemCount: itemList.length + (widget.listFooterBuilder != null ? 1 : 0)
          ),
        )
      ],
    );
  }

  Widget _buildSliverView(BuildContext context, G group, int tabIndex, List<T>? itemList){
    if(itemList == null) return const SliverToBoxAdapter(child:  SizedBox(),);

    return MultiSliver(
      children: [
        if(widget.listHeaderBuilder != null)
          ...widget.listHeaderBuilder!(context, group, (where) => _onFilter(group, where)),
        itemList.isEmpty ?
        SliverFillRemaining(hasScrollBody: false, child: widget.emptyBuilder?.call(context, group, tabIndex) ?? const Center(child: Text('Empty List'),),) :
        SliverPadding(
          padding: widget.listPadding ?? EdgeInsets.zero,
          sliver: widget.listBuilder?.call(context, group, tabIndex, itemList) ?? SliverList.separated(
              itemBuilder: (context, index){
                if(index == itemList.length){
                  return widget.listFooterBuilder?.call(context, group);
                }

                return widget.listItemBuilder?.call(context, itemList[index], group, index) ?? Text(itemList[index].toString());
              },
              separatorBuilder: (context, index) => widget.listItemSeparatorBuilder?.call(context, group, index) ?? const SizedBox(),
              itemCount: itemList.length + (widget.listFooterBuilder != null ? 1 : 0)
          ),
        )
      ],
    );
  }

  void _onFilter(G group, bool Function(T) where){
    final list = groupDictionary[group];
    if(list?.isNotEmpty == true){
      final filtered = list!.where(where).toList();
      setState(() {
        groupDictionaryDisplay[group] = filtered;
      });
    }
  }
}

class TabBarViewPlus extends StatefulWidget{
  const TabBarViewPlus({
    super.key,
    required this.itemCount,
    this.useSliver = false,
    this.tabBarBuilder,
    this.tabBarViewBuilder,
    this.separatorBuilder,
    this.tabBarHeaderBuilder,
    this.tabBarDecoration,
    this.tabBarViewDecoration,
    this.onTabControllerCreated,
    this.onTabChanged,
    this.onRefresh,
    this.refreshIndicatorSettings = const RefreshIndicatorSettings(),
    this.hideSingleTabBar = false,
    this.emptyTabBarView,

    this.isScrollable = false,
    this.tabBarPadding,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.dividerColor,
    this.dividerHeight,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.tabBarPhysics,
    this.splashFactory,
    this.splashBorderRadius,
    this.tabAlignment,
    this.tabBarViewPhysics,
    this.clipBehavior = Clip.hardEdge,
  });

  //region TabBar
  final bool isScrollable;
  final EdgeInsetsGeometry? tabBarPadding;
  final Color? indicatorColor;
  final double indicatorWeight;
  final EdgeInsetsGeometry indicatorPadding;
  final Decoration? indicator;
  final bool automaticIndicatorColorAdjustment;
  final TabBarIndicatorSize? indicatorSize;
  final Color? dividerColor;
  final double? dividerHeight;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final WidgetStateProperty<Color?>? overlayColor;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final bool? enableFeedback;
  final ValueChanged<int>? onTap;
  final ScrollPhysics? tabBarPhysics;
  final InteractiveInkFeatureFactory? splashFactory;
  final BorderRadius? splashBorderRadius;
  final TabAlignment? tabAlignment;
  //endregion

  //region TabBarView
  final ScrollPhysics? tabBarViewPhysics;
  final Clip clipBehavior;
  //endregion

  //region TabBarViewPlus
  final int itemCount;
  final IndexedWidgetBuilder? tabBarBuilder;
  ///Can provide decoration for TabBar, e.g background color
  final BoxDecoration Function(BuildContext context)? tabBarDecoration;
  ///Provide Sliver Widget if useSliver is true,
  final Widget Function(BuildContext context, int index)? tabBarViewBuilder;
  ///Can provide decoration for TabBarView, e.g background color
  final BoxDecoration Function(BuildContext context, int index)? tabBarViewDecoration;
  ///Widget between TabBar and TabBarView, which persist even change of TabBarView page
  ///
  ///Provide Sliver Widget if useSliver is true,
  ///
  ///innerBoxIsScrolled will always return false if useSliver is false
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)? separatorBuilder;
  ///Widget before TabBar
  ///
  ///Provide Sliver Widget if useSliver is true
  ///
  ///innerBoxIsScrolled will always return false if useSliver is false
  final List<Widget> Function(BuildContext context, bool innerBoxIsScrolled)? tabBarHeaderBuilder;
  final void Function(TabController controller)? onTabControllerCreated;
  final void Function(int index)? onTabChanged;
  ///Use sliver if you want to use this
  final Future<void> Function()? onRefresh;
  final RefreshIndicatorSettings refreshIndicatorSettings;

  final bool useSliver;

  final bool hideSingleTabBar;

  ///Widget to build when provided item count < 1
  final WidgetBuilder? emptyTabBarView;
  //endregion

  @override
  State<TabBarViewPlus> createState() => _TabBarViewPlusState();
}

class _TabBarViewPlusState extends State<TabBarViewPlus> with TickerProviderStateMixin{

  late TabController _tabController;

  @override
  void initState() {
    _setupTabController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TabBarViewPlus oldWidget) {

    if(oldWidget.itemCount != widget.itemCount){
      setState(() {
        _tabController.dispose();
        _setupTabController();
      });
    }

    if(oldWidget.onTabControllerCreated != widget.onTabControllerCreated && widget.onTabControllerCreated != null){
      widget.onTabControllerCreated?.call(_tabController);
    }

    super.didUpdateWidget(oldWidget);
  }

  void _setupTabController(){
    _tabController = TabController(length: widget.itemCount, vsync: this);
    _tabController.addListener(() => widget.onTabChanged?.call(_tabController.index));
    widget.onTabChanged?.call(_tabController.index);
    widget.onTabControllerCreated?.call(_tabController);
  }

  @override
  Widget build(BuildContext context) {
    if(widget.useSliver){
      return _buildSliver(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if(widget.tabBarHeaderBuilder != null)
          ...widget.tabBarHeaderBuilder!(context, false),
        _buildTabBar(context),
        if(widget.separatorBuilder != null)
          ...widget.separatorBuilder!(context, false),
        Expanded(
          child: _buildTabBarView(context),
        ),
      ],
    );
  }

  Widget _buildSliver(BuildContext context){

    final scrollView = NestedScrollView(
      physics: widget.onRefresh != null ? const AlwaysScrollableScrollPhysics() : null,
      headerSliverBuilder: (context, innerBoxIsScrolled){
        return [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: MultiSliver(
              children: [
                if(widget.tabBarHeaderBuilder != null)
                  ...widget.tabBarHeaderBuilder!(context, innerBoxIsScrolled),
                SliverPinnedHeader(
                  child: _buildTabBar(context),
                ),
                if(widget.separatorBuilder != null)
                  ...widget.separatorBuilder!(context, innerBoxIsScrolled),
              ],
            ),
          )
        ];
      },
      body: _buildTabBarView(context),
    );

    if(widget.onRefresh == null){
      return scrollView;
    }

    return CustomPullToRefresh(
        onRefresh: widget.onRefresh,
        settings: widget.refreshIndicatorSettings.copyWith(
            depths: [0, 2]
        ),
        child: scrollView
    );
  }

  Widget _buildTabBar(BuildContext context) => Visibility(
    visible: widget.itemCount <= 1 ? !widget.hideSingleTabBar : true,
    child: Container(
      decoration: widget.tabBarDecoration?.call(context),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        padding: widget.tabBarPadding,
        indicatorColor: widget.indicatorColor,
        automaticIndicatorColorAdjustment: widget.automaticIndicatorColorAdjustment,
        indicatorWeight: widget.indicatorWeight,
        indicatorPadding: widget.indicatorPadding,
        indicator: widget.indicator,
        indicatorSize: widget.indicatorSize,
        dividerColor: widget.dividerColor,
        dividerHeight: widget.dividerHeight,
        labelColor: widget.labelColor,
        labelStyle: widget.labelStyle,
        labelPadding: widget.labelPadding,
        unselectedLabelColor: widget.unselectedLabelColor,
        unselectedLabelStyle: widget.unselectedLabelStyle,
        dragStartBehavior: widget.dragStartBehavior,
        overlayColor: widget.overlayColor,
        mouseCursor: widget.mouseCursor,
        enableFeedback: widget.enableFeedback,
        onTap: widget.onTap,
        physics: widget.tabBarPhysics,
        splashFactory: widget.splashFactory,
        splashBorderRadius: widget.splashBorderRadius,
        tabAlignment: widget.tabAlignment,
        tabs: List.generate(
          widget.itemCount,
              (index) => widget.tabBarBuilder?.call(context, index) ?? Tab(text: 'Tab $index',),
        ),
      ),
    ),
  );

  Widget _buildTabBarView(BuildContext context){
    if(widget.itemCount <= 0){
      return widget.emptyTabBarView?.call(context) ?? const SizedBox();
    }

    return TabBarView(
      controller: _tabController,
      physics: widget.tabBarViewPhysics,
      clipBehavior: widget.clipBehavior,
      children: List.generate(
        widget.itemCount,
            (index) => _buildTabBarViewItem(context, index),
      ),
    );
  }

  Widget _buildTabBarViewItem(BuildContext context, int index){

    final child = widget.tabBarViewBuilder?.call(context, index) ?? _buildDefaultTabBarViewChild(index);

    if(widget.useSliver){
      return Builder(
        builder: (context){
          return Container(
            decoration: widget.tabBarViewDecoration?.call(context, index),
            child: NotificationListener(
              onNotification: (n) => false,
              child: CustomScrollView(
                slivers: [
                  SliverPinnedOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
                  SliverClip(
                    child: child,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: widget.tabBarViewDecoration?.call(context, index),
      child: child,
    );
  }

  Widget _buildDefaultTabBarViewChild(int index){
    if(widget.useSliver){
      return SliverFillRemaining(
        hasScrollBody: false,
        fillOverscroll: true,
        child: Center(child: Text('TabView : $index'),),
      );
    }

    return Center(child: Text('TabView : $index'),);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}