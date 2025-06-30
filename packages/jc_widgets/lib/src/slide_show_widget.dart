import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jc_widgets/src/slide_show/slide_show.dart';

class SlideShowWidget<T> extends StatefulWidget{
  final List<T> slides;
  final double height;
  final Widget Function(BuildContext,T) itemBuilder;
  final Widget? Function(BuildContext, int itemCount, int currentIndex) indicatorBuilder;
  final bool isLoop;
  final bool allowScrolling;
  final Duration autoSlideDuration;
  final double indicatorBottom;
  final SlideShowController? controller;
  final Function(int index, T item)? onSlideChanged;

  const SlideShowWidget({
    super.key,
    required this.slides,
    required this.height,
    required this.itemBuilder,
    required this.indicatorBuilder,
    this.controller,
    this.autoSlideDuration = Duration.zero,
    this.isLoop = false,
    this.allowScrolling = true,
    this.indicatorBottom = 10,
    this.onSlideChanged,
  });

  @override
  State<SlideShowWidget> createState() => _SlideShowWidgetState<T>();
}

class _SlideShowWidgetState<T> extends State<SlideShowWidget<T>> implements SlideShowFunction{
  final ValueNotifier<int> _currentSlideNotifier = ValueNotifier(0);
  final PageController _pageController = PageController();
  ScrollBehavior _scrollBehavior = const ScrollBehavior();
  Timer? _timer;

  @override
  void initState() {

    _setupScrolling();

    if (widget.autoSlideDuration != Duration.zero) {
      startAutoPlay();
    }

    _pageController.addListener(() {
      startAutoPlay();
    });

    widget.controller?.attach(this);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant SlideShowWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(oldWidget.allowScrolling != widget.allowScrolling){
      _setupScrolling();
    }

    if(oldWidget.autoSlideDuration != widget.autoSlideDuration){
      startAutoPlay();
    }

    if(oldWidget.controller != widget.controller){
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }

    setState(() {});
  }

  void _setupScrolling(){
    _scrollBehavior = widget.allowScrolling == false
        ? const ScrollBehavior().copyWith(
      scrollbars: false,
      dragDevices: {},
    )
        : const ScrollBehavior().copyWith(
      scrollbars: false,
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              scrollBehavior: _scrollBehavior,
              itemCount: widget.slides.length,
              itemBuilder: (context, index) => widget.itemBuilder.call(context,widget.slides[index]),
              onPageChanged: (index) {
                widget.onSlideChanged?.call(index, widget.slides[index]);
                _currentSlideNotifier.value = index;
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.indicatorBottom,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentSlideNotifier,
              builder: (BuildContext context, int value, Widget? child) {
                return widget.indicatorBuilder.call(context,widget.slides.length, value ) ?? const SizedBox();
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  void startAutoPlay() {
    _timer?.cancel();

    if(widget.autoSlideDuration == Duration.zero) return;

    _timer = Timer.periodic(
      widget.autoSlideDuration,
          (timer) {
        int nextPage;
        if (widget.isLoop) {
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

        goToPage(nextPage);
      },
    );
  }

  void goToPage(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void stopAutoPlay() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _pageController.dispose();
    _currentSlideNotifier.dispose();
    _timer?.cancel();
    super.dispose();
  }

}