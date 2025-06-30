import 'package:flutter/material.dart';

import 'circular_reveal_painter.dart';
import 'circular_reveal_page.dart';

class CircularRevealWidget extends StatefulWidget {
  final List<CircularRevealPage> pages;
  final Widget Function(BuildContext context, int index, Widget child)? pageBuilder;
  final double circleRadius;
  final Alignment alignment;
  final Axis transitionDirection;
  final double transitionScaling;
  final double maxScrollExtentRatio;
  final double iconRatio;
  final IconData icon;
  final Alignment iconAlignment;
  final bool hideIconInTransition;
  final bool clipCanvas;
  final CircleLeftBoundAlignment circleLeftBoundAlignment;
  final Duration duration;
  const CircularRevealWidget({
    super.key,
    required this.pages,
    this.pageBuilder,
    this.circleRadius = 36,
    this.alignment = Alignment.bottomCenter,
    this.transitionDirection = Axis.horizontal,
    this.transitionScaling = .6,
    this.maxScrollExtentRatio = .8,
    this.iconRatio = .6,
    this.iconAlignment = Alignment.center,
    this.icon = Icons.arrow_forward_ios,
    this.hideIconInTransition = false,
    this.clipCanvas = true,
    this.circleLeftBoundAlignment = CircleLeftBoundAlignment.center,
    this.duration = const Duration(milliseconds: 1500)
  });

  @override
  State<CircularRevealWidget> createState() => _CircularRevealWidgetState();
}

class _CircularRevealWidgetState extends State<CircularRevealWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  double _transitionPercent = 0;
  final GlobalKey _stackKey = GlobalKey();

  double _scrollOffset = 0.0;

  Size? _currentSize;

  final double _maxScrollExtent = 300;
  double get axisSize => (widget.transitionDirection == Axis.horizontal ? _currentSize?.width : _currentSize?.height) ?? _maxScrollExtent;
  double get axisMaxScroll => axisSize * widget.maxScrollExtentRatio.clamp(0, 1);

  int _currentPageIndex = 0;
  int _actualPageIndex = 0;
  CircularRevealPage? get _currentPage{
    return widget.pages.isNotEmpty ? widget.pages[_currentPageIndex] : null;
  }
  CircularRevealPage? get _secondPage{
    if(widget.pages.isEmpty) return null;
    return widget.pages[(_currentPageIndex + 1) % widget.pages.length];
  }

  CircularRevealPage? get _thirdPage{
    if(widget.pages.isEmpty) return null;
    return widget.pages[(_currentPageIndex + 2) % widget.pages.length];
  }
  CircularRevealPage? _visiblePage;

  bool _reverse = false;

  final ValueNotifier<Offset?> _buttonOffset = ValueNotifier(null);

  @override
  void initState() {
    super.initState();

    _visiblePage = _currentPage;

    _setupAnimationController();
    _getLocalOffset();
    _getSize();
  }

  @override
  void didUpdateWidget(covariant CircularRevealWidget oldWidget) {
    if(widget.duration != oldWidget.duration){
      _animationController.duration = widget.duration;
    }

    if(widget.pages.length != oldWidget.pages.length){
      if(_actualPageIndex >= widget.pages.length){
        setState(() {
          _actualPageIndex = widget.pages.length - 1;
          _currentPageIndex = _actualPageIndex;
          _visiblePage = _currentPage;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _getLocalOffset());

    super.didUpdateWidget(oldWidget);
  }

  void _setupAnimationController() {
    _animationController = AnimationController(
          vsync: this,
          duration: widget.duration,
        )
      ..addListener(() {
        if(widget.pages.isEmpty || widget.pages.length == 1){
          _animationController.animateBack(0.0, duration: Duration.zero);
        }

        setState(() {
          _transitionPercent = _animationController.value;

          _scrollOffset = _maxScrollExtent * _transitionPercent;

          if(_transitionPercent < .5){
            _visiblePage = _currentPage;
          }
          else{
            _visiblePage = _secondPage;
          }
        });
      })
      ..addStatusListener((status) {
        setState(() {
          if(status == AnimationStatus.completed){
            // Check to prevent if swipe backward
            if(_currentPageIndex == _actualPageIndex){
              if(!_reverse){
                _actualPageIndex = (_actualPageIndex + 1) % widget.pages.length;
              }
            }

            _currentPageIndex = _actualPageIndex;

            _reverse = false;
            _transitionPercent = 0;
            _animationController.animateBack(0.0, duration: Duration.zero);
          } // Swipe back
          else if(status == AnimationStatus.dismissed){
            if(_reverse){
              _actualPageIndex = _actualPageIndex - 1;
              if(_actualPageIndex < 0) _actualPageIndex = widget.pages.length -1;

              _currentPageIndex = _actualPageIndex;

              _reverse = false;
              _transitionPercent = 0;
              _animationController.animateBack(0.0, duration: Duration.zero);
            }
          }
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    //Calculate the position of content
    double offsetPercent = 1;
    if(_transitionPercent <= .25){
      offsetPercent = -_transitionPercent / .25;
    }
    else if(_transitionPercent >= .7){
      offsetPercent = (1 - _transitionPercent) / .3;
      offsetPercent = Curves.easeInCubic.transform(offsetPercent);
    }

    final double contentOffset = offsetPercent * axisSize;

    double scaling = widget.transitionScaling.clamp(0, 1);

    final double contentScale = scaling + ((1 - scaling) * (1 - offsetPercent.abs()));

    Widget child = _visiblePage?.child ?? const SizedBox();

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: CustomPaint(
        painter: CircularRevealPainter(
            backgroundColor: _currentPage?.backgroundColor ?? Colors.white,
            currentCircleColor: _secondPage?.backgroundColor ?? Colors.white,
            nextCircleColor: _thirdPage?.backgroundColor ?? Colors.white,
            transitionPercent: _transitionPercent,
            baseCircleRadius: widget.circleRadius,
            alignment: widget.alignment,
            transitionDirection: widget.transitionDirection,
            icon: widget.icon,
            iconAlignment: widget.iconAlignment,
            iconRatio: widget.iconRatio,
            clipCanvas: widget.clipCanvas,
            circleLeftBoundAlignment: widget.circleLeftBoundAlignment,
            hideIconInTransition: widget.hideIconInTransition,
        ),
        child: Stack(
          key: _stackKey,
          fit: StackFit.expand,
          children: [
            Transform(
              transform: Matrix4.translationValues(
                  widget.transitionDirection == Axis.horizontal ? contentOffset : 0,
                  widget.transitionDirection == Axis.vertical ? contentOffset : 0,
                  0)
                ..scale(contentScale, contentScale),
              alignment: Alignment.center,
              child: widget.pageBuilder != null ? widget.pageBuilder!(context, _currentPageIndex, child) : child,
            ),
            ValueListenableBuilder(
                valueListenable: _buttonOffset,
              builder: (BuildContext context, Offset? value, Widget? child) {

                  if(value == null) return const SizedBox();

                  return Positioned(
                      left: value.dx - widget.circleRadius,
                      top: value.dy - widget.circleRadius,
                      child: GestureDetector(
                        onTap: () {
                          if (_animationController.isAnimating) return;

                          _reverse = false;
                          _animationController.forward();
                        },
                        child: Container(
                          width: widget.circleRadius * 2,
                          height: widget.circleRadius * 2,
                          color: Colors.purple.withOpacity(0),
                        ),
                      ));
              },
            )
          ],
        ),
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details){
    if(widget.transitionDirection == Axis.vertical) return;

    if(_animationController.isAnimating) return;

    _scrollOffset += details.delta.dx;
    _onDragUpdate();
  }
  void _onHorizontalDragEnd(DragEndDetails details){
    if(widget.transitionDirection == Axis.vertical) return;
    if(_animationController.isAnimating) return;

    // Continue the animation
    _onDragEnd();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details){
    if(widget.transitionDirection == Axis.horizontal) return;
    if(_animationController.isAnimating) return;

    _scrollOffset += details.delta.dy;
    _onDragUpdate();
  }
  void _onVerticalDragEnd(DragEndDetails details){
    if(widget.transitionDirection == Axis.horizontal) return;
    if(_animationController.isAnimating) return;

    // Continue the animation
    _onDragEnd();
  }

  void _onDragUpdate(){
    _scrollOffset = _scrollOffset.clamp(-axisSize, axisSize);
    // swipe from right to left, so animation is forward
    _reverse = _scrollOffset > 0;
    if(!_reverse){
      setState(() {
        if(_currentPageIndex != _actualPageIndex){
          _currentPageIndex = _actualPageIndex;
        }

        _transitionPercent = (_scrollOffset.abs()/axisSize).clamp(0, 1);
      });
    }
    else {
      // swipe from left to right, so animation is backward
      setState(() {
        if(_currentPageIndex >= _actualPageIndex){
          _currentPageIndex = _actualPageIndex - 1;
          if(_currentPageIndex < 0) _currentPageIndex = widget.pages.length - 1;
        }

        _transitionPercent = 1 - (_scrollOffset/axisSize).clamp(0, 1);
      });
    }
  }

  void _onDragEnd(){
    // Continue the animation
    if(_transitionPercent >= .5){
      double from = (_scrollOffset.abs()/axisSize).clamp(0, 1);
      if(_reverse) from = 1 - from;
      _animationController.forward(from: from);
    }
    else{
      double from = (_scrollOffset.abs()/axisSize).clamp(0, 1);
      if(_reverse) from = 1 - from;
      _animationController.reverse(from: from);
    }
  }

  Future<void> _getSize() async {
    final box = (_stackKey.currentContext?.findRenderObject()) as RenderBox?;
    if (box != null) {
      setState(() {
        _currentSize = box.size;
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      return _getSize();
    }
  }

  Offset _getOffset(Size size){
    return Offset(size.width * _convertAlignment(widget.alignment.x),
        size.height * _convertAlignment(widget.alignment.y));
  }

  Future<void> _getLocalOffset() async {
    final box = (_stackKey.currentContext?.findRenderObject()) as RenderBox?;
    if (box != null) {
      _buttonOffset.value = _getOffset(box.size);
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      return _getLocalOffset();
    }
  }

  double _convertAlignment(double value) {
    return (value + 1) / 2;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
