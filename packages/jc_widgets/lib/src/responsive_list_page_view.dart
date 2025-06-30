import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jc_widgets/src/size_measure_widget.dart';
import 'package:jc_widgets/src/slide_show/slide_show.dart';
import 'package:jc_widgets/src/widget_typedef.dart';
import 'package:loop_page_view/loop_page_view.dart';

class ResponsiveListPageView<T> extends StatefulWidget{
  final List<T> itemList;
  final ItemIndexedWidgetBuilder<T> itemBuilder;
  final double maxWidth;
  final double maxHeight;
  final double mainSpacing;
  final double crossSpacing;
  final Axis direction;
  final bool allowScrolling;
  final Duration pageDuration;
  final Duration? duration;
  final SlideShowController? controller;
  final LoopScrollMode scrollMode;

  const ResponsiveListPageView({
    super.key,
    required this.itemList,
    required this.itemBuilder,
    required this.maxWidth,
    required this.maxHeight,
    this.mainSpacing = 0,
    this.crossSpacing = 0,
    this.direction = Axis.vertical,
    this.allowScrolling = true,
    this.pageDuration = Duration.zero,
    this.duration,
    this.controller,
    this.scrollMode = LoopScrollMode.forwards,
  });

  @override
  State<ResponsiveListPageView<T>> createState() => _ResponsiveListPageViewState<T>();
}

class _ResponsiveListPageViewState<T> extends State<ResponsiveListPageView<T>> implements SlideShowFunction{

  final ValueNotifier<int> _currentPage = ValueNotifier(0);
  List<SizeMeasureWidget> children = [];
  List<List<Widget>> pages = [];
  late final LoopPageController _pageController = LoopPageController(
    scrollMode: widget.scrollMode,
  );
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.pageDuration != Duration.zero) {
      startAutoPlay();
    }

    _pageController.addListener(() {
      startAutoPlay();
    });

    widget.controller?.attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_){
      _reset();
    });
  }

  @override
  void didUpdateWidget(covariant ResponsiveListPageView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool listDiff = widget.itemList != oldWidget.itemList;
    bool widthDiff = widget.maxWidth != oldWidget.maxWidth;
    bool heightDiff = widget.maxHeight != oldWidget.maxHeight;
    bool spacingDiff = widget.mainSpacing != oldWidget.mainSpacing;
    bool crossSpacingDiff = widget.crossSpacing != oldWidget.crossSpacing;
    if(listDiff || widthDiff || heightDiff || spacingDiff || crossSpacingDiff){
      _reset();
    }

    if(oldWidget.pageDuration != widget.pageDuration){
      startAutoPlay();
    }

    if(oldWidget.controller != widget.controller){
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
  }

  void _reset() {
    stopAutoPlay();
    pages.clear();
    _buildChildren();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _calculatePages();
      if(_currentPage.value > pages.length - 1){
        _currentPage.value = 0;
      }

      WidgetsBinding.instance.addPostFrameCallback((_){
        if(_pageController.hasClients){
          _pageController.jumpToPage(
            _currentPage.value,
          );
        }
        startAutoPlay();
      });

    });
  }

  void _buildChildren(){
    setState(() {
      children = List.generate(
          widget.itemList.length,
          (i){
            return SizeMeasureWidget(
              child: widget.itemBuilder(context, i, widget.itemList[i]),
            );
          }
      );
    });
  }

  void _calculatePages(){
    List<List<Widget>> tempPages = [];

    double maxChildWidth = 0;
    double maxChildHeight = 0;

    for(int i = 0; i < children.length; i++){
      final child = children[i];
      final size = child.size;
      //print(size == null);
      if(size == null) continue;

      final childWidth = size.width + widget.crossSpacing;
      final childHeight = size.height + widget.mainSpacing;

      if(maxChildWidth < childWidth) maxChildWidth = childWidth;
      if(maxChildHeight < childHeight) maxChildHeight = childHeight;
    }

    //print('MAX_H:$maxChildHeight, MAX_W:$maxChildWidth');
    if(maxChildHeight == 0 && maxChildWidth == 0) return;
    final itemPerRow = (widget.maxWidth / maxChildWidth).floor();
    final itemPerColumn = (widget.maxHeight / maxChildHeight).floor();
    final itemPerPage = itemPerRow * itemPerColumn;
    //print(itemPerPage);
    if(itemPerPage <= 0) return;

    for(int i = 0; i < children.length; i += itemPerPage){
      tempPages.add(children
          .sublist(i, i + itemPerPage > children.length ? children.length : i + itemPerPage)
          .map((e){
            return Padding(
              padding: EdgeInsets.only(
                right: widget.crossSpacing,
                bottom: widget.mainSpacing,
              ),
              child: e.child,
            );
      }).toList());
    }

    /*for(int i = 0; i < children.length; i++){

      if(remainingWidth < maxChildWidth && currentPage.isNotEmpty){
        if(remainingHeight < maxChildHeight){
          tempPages.add(List.of(currentPage));
          currentPage = [];
          remainingWidth = widget.maxWidth;
          remainingHeight = widget.maxHeight;
        }
        else{
          remainingWidth = widget.maxWidth;
          remainingHeight -= maxChildHeight;
        }
      }

      if(remainingHeight < maxChildHeight && currentPage.isNotEmpty){
        tempPages.add(List.of(currentPage));
        currentPage = [];
        remainingWidth = widget.maxWidth;
        remainingHeight = widget.maxHeight;
      }

      currentPage.add(Padding(
        padding: EdgeInsets.only(
          right: widget.crossSpacing,
          bottom: widget.mainSpacing,
        ),
        child: children[i].child,
      ));
      remainingWidth -= maxChildWidth;
    }*/

    setState(() {
      pages = tempPages;
    });
  }

  @override
  Widget build(BuildContext context) {

    if(pages.isNotEmpty){
      return SizedBox(
        width: widget.maxWidth,
        height: widget.maxHeight,
        child: LoopPageView.builder(
          itemCount: pages.length,
          controller: _pageController,
          physics: widget.allowScrolling ? null : const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => _currentPage.value = index,
          itemBuilder: (context, index){
            return _buildWrap(pages[index]);
          },
        ),
      );
    }

    if(children.isNotEmpty){
      return SingleChildScrollView(
        scrollDirection: widget.direction,
        child: SizedBox(
          width: widget.maxWidth,
          height: widget.maxHeight,
          child: Wrap(
            direction: widget.direction,
            runSpacing: widget.crossSpacing,
            spacing: widget.mainSpacing,
            children: children,
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator(),);
  }

  Widget _buildWrap(List<Widget> itemList){
    return Wrap(
      direction: widget.direction,
      children: itemList,
    );
  }

  @override
  void startAutoPlay() {
    if(widget.pageDuration == Duration.zero || pages.length <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(
      widget.pageDuration,
      (timer) {
        int nextPage = _currentPage.value + 1;
        if(_currentPage.value >= pages.length-1) {
          nextPage = 0;
        }

        if(_pageController.hasClients){
          _pageController.animateToPage(
              nextPage,
              duration: widget.duration ?? const Duration(milliseconds: 350),
              curve: Curves.easeIn
          );
        }
       /* if (widget.isLoop) {
          nextPage = _currentSlideNotifier.value + 1;
          if(_currentSlideNotifier.value >= widget.slides.length-1) {
            nextPage = 0;
          }
        } else {
          if (_currentSlideNotifier.value < widget.slides.length - 1) {
            nextPage = _currentSlideNotifier.value + 1;
          } else {
            return;
          }
        }

        goToPage(nextPage);*/
      },
    );
  }

  @override
  void stopAutoPlay() {
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}