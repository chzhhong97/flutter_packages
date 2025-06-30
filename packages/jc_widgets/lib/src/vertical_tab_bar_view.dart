import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class VerticalTabBarView extends StatefulWidget{
  final int itemCount;
  final Widget Function(BuildContext context, int index, bool currentTab)? tabBarBuilder;
  final Widget Function(BuildContext context, int index)? tabBarViewBuilder;
  final Widget Function(BuildContext context, int index)? indicatorBuilder;
  final void Function(int index)? onPageChanged;
  final double? tabBarMaxWidth;
  final double flex;
  final TextStyle? textStyle;
  final TextStyle? unselectedTextStyle;
  final BoxDecoration? tabBarDecoration;
  final Duration tabAnimatedDuration;
  final bool animateToPage;

  const VerticalTabBarView({
    super.key,
    required this.itemCount,
    this.tabBarBuilder,
    this.tabBarViewBuilder,
    this.indicatorBuilder,
    this.tabBarMaxWidth,
    this.flex = 0,
    this.textStyle,
    this.unselectedTextStyle,
    this.tabBarDecoration,
    this.tabAnimatedDuration = const Duration(milliseconds: 200),
    this.animateToPage = true,
    this.onPageChanged,
  });

  @override
  State<VerticalTabBarView> createState() => _VerticalTabBarViewState();
}

class _VerticalTabBarViewState extends State<VerticalTabBarView> with TickerProviderStateMixin{

  late TabController _tabController;
  final PageController _pageController = PageController();

  int currentIndex = 0;
  int previousIndex = 0;
  bool _changeViewByTap = false;

  List<GlobalKey> globalList = [];

  ValueNotifier<BuildContext?> currentTabContext = ValueNotifier(null);
  final GlobalKey _stackKey = GlobalKey();

  Duration get tabAnimateDuration => Duration(
    microseconds: widget.tabAnimatedDuration.inMicroseconds + (widget.tabAnimatedDuration.inMicroseconds/10 * (currentIndex - previousIndex).abs()).toInt(),
  );

  @override
  void initState() {
    _setupTabController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VerticalTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(oldWidget.itemCount != widget.itemCount){
      setState(() {
        _tabController.dispose();
        _setupTabController();
      });
    }
  }

  void _setupTabController(){
    _tabController = TabController(length: widget.itemCount, vsync: this);
    globalList = List.generate(widget.itemCount, (e) => GlobalKey());
    currentIndex = 0;

    SchedulerBinding.instance.addPostFrameCallback((timeStamp){
      currentTabContext.value = globalList.isNotEmpty ? globalList[currentIndex].currentContext : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildSecondApproach(context);
  }

  Widget _buildSecondApproach(BuildContext context){
    int flex = (100 * widget.flex).toInt();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: flex,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.tabBarMaxWidth ?? double.infinity
            ),
            decoration: widget.tabBarDecoration,
            child: SingleChildScrollView(
              child: Stack(
                key: _stackKey,
                children: [
                  ValueListenableBuilder(
                    valueListenable: currentTabContext,
                    builder: (BuildContext context, BuildContext? value, Widget? child) {
                      if(value?.findRenderObject() != null && _stackKey.currentContext?.findRenderObject() != null){
                        final box = value!.findRenderObject() as RenderBox;
                        final stackBox = _stackKey.currentContext!.findRenderObject() as RenderBox;
                        final offset = box.localToGlobal(Offset.zero, ancestor: stackBox);
                        return AnimatedPositioned(
                          top: offset.dy,
                          left: 0,
                          height: box.size.height,
                          width: box.size.width,
                          duration: tabAnimateDuration,
                          child: _buildIndicator(context, currentIndex)
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(
                      widget.itemCount,
                          (index){
                        Widget tab = widget.tabBarBuilder?.call(context, index, index == currentIndex) ?? Tab(text: 'Tab $index',);

                        return _buildTab(context, tab, index);
                      }
                    ),
                  ),
                ],
              ),
            ),
          )
        ),
        Expanded(
          flex: 100 - flex,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.itemCount,
            itemBuilder: (context, index) {
              if(widget.tabBarViewBuilder != null) return widget.tabBarViewBuilder!(context, index);

              return Center(
                child: Text(
                  'TabBarView: $index',
                ),
              );
            },
            onPageChanged: (index){
              if(!_changeViewByTap) {
                _setIndex(index);
                _scrollToItem(globalList[index]);
              }
              if(currentIndex == index) _changeViewByTap = false;

              setState(() {});
            },
          ),
        )
      ],
    );
  }

  Widget _buildTab(BuildContext context, Widget tab, int index){
    return Stack(
      key: globalList[index],
      children: [
        /*Positioned.fill(
          child: currentIndex == index ? _buildIndicator(context, index) : const SizedBox(),
        ),*/
        Align(
          alignment: Alignment.center,
          child: _buildTabWidget(tab, currentIndex == index),
        ),
        Positioned.fill(
          child: InkWell(
            onTap: (){
              setState(() {
                _changeViewByTap = true;
                _setIndex(index);
              });
              _scrollToItem(globalList[index]);
              widget.animateToPage ? _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut
              ) : _pageController.jumpToPage(index);
            },
          ),
        )
      ],
    );
  }

  Widget _buildTabWidget(Widget tab, bool currentTab){
    if(tab is! Tab) return tab;

    if(tab.child != null) return tab.child!;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(tab.icon != null)
            Container(
              margin: tab.iconMargin,
              child: tab.icon,
            ),
          if(tab.text != null)
            Flexible(
              child: Text(
                tab.text!,
                softWrap: true,
                style: currentTab ? widget.textStyle : widget.unselectedTextStyle,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildIndicator(BuildContext context, int index){
    if(widget.indicatorBuilder != null) return widget.indicatorBuilder!(context, index);

    return Container(
      color: Colors.white,
    );
  }

  void _setIndex(int index){
    previousIndex = currentIndex;
    currentIndex = index;

    widget.onPageChanged?.call(index);
  }

  void _scrollToItem(GlobalKey key) async {
    if(key.currentContext != null){
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: .5,
        duration: const Duration(milliseconds: 300)
      );

      currentTabContext.value = key.currentContext;
    }
  }
}