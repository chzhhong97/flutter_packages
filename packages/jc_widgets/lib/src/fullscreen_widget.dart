import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FullScreenWidget extends StatefulWidget{
  final Object tag;
  final Widget child;
  final Widget? secondChild;
  final Widget? fullScreenTopWidget;
  final Widget? fullScreenBottomWidget;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Duration duration;
  final EdgeInsets padding;
  final Axis direction;
  final void Function()? onFullScreen;
  final void Function()? onClose;

  const FullScreenWidget({
    super.key,
    required this.tag,
    required this.child,
    this.secondChild,
    this.fullScreenTopWidget,
    this.fullScreenBottomWidget,
    this.width,
    this.height,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 100),
    this.padding = EdgeInsets.zero,
    this.direction = Axis.horizontal,
    this.onFullScreen,
    this.onClose,
  });

  @override
  State<FullScreenWidget> createState() => _FullScreenWidgetState();
}

class _FullScreenWidgetState extends State<FullScreenWidget>{

  OverlayEntry? _entry;
  final ValueNotifier<bool> _isFullScreen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ValueListenableBuilder(
          valueListenable: _isFullScreen,
          builder: (BuildContext context, bool value, Widget? child) {
            if(value) return const SizedBox();

            return _buildWidget();
          },
        ),
      ),
    );
  }

  Widget _buildSecondWidget(){
    if(widget.secondChild == null) return _buildWidget();

    return Builder(
      builder: (context){
        return Hero(
            tag: widget.tag,
            child: widget.secondChild!
        );
      },
    );
  }

  Widget _buildWidget(){
    return Builder(
      builder: (context){
        return Hero(
            tag: widget.tag,
            child: widget.child
        );
      },
    );
  }

  void _openFullScreen(){
    _removeOverlay();
    var size = MediaQuery.of(context).size;
    var view = WidgetsBinding.instance.platformDispatcher.views.first;
    var width = (view.physicalSize.width/view.devicePixelRatio) - size.width;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final offset2 = box.localToGlobal(Offset(-width/2, 0));


    if(kDebugMode) debugPrint(offset.toString());
    if(kDebugMode) debugPrint(offset2.toString());

    _entry = OverlayEntry(
      builder: (context){
        return _OverlayWidget(
          offset: kIsWeb ? offset2 : offset,
          size: box.size,
          backgroundColor: widget.backgroundColor,
          duration: widget.duration,
          onOverlayClose: () {
            _isFullScreen.value = false;
            _removeOverlay();
            widget.onClose?.call();
          },
          padding: widget.padding,
          direction: widget.direction,
          topWidget: widget.fullScreenTopWidget,
          bottomWidget: widget.fullScreenBottomWidget,
          child: _buildSecondWidget(),
        );
      }
    );

    final OverlayState overlay = Overlay.of(context);
    overlay.insert(_entry!);

    _isFullScreen.value = true;

    widget.onFullScreen?.call();
  }

  void _removeOverlay(){
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}

class _OverlayWidget extends StatefulWidget{
  final Widget child;
  final Offset offset;
  final Size size;
  final Color? backgroundColor;
  final Duration duration;
  final EdgeInsets padding;
  final Function()? onOverlayClose;
  final Axis direction;
  final Widget? topWidget;
  final Widget? bottomWidget;

  const _OverlayWidget({
    required this.offset,
    required this.size,
    required this.child,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 300),
    this.onOverlayClose,
    this.padding = EdgeInsets.zero,
    this.direction = Axis.horizontal,
    this.topWidget,
    this.bottomWidget,
  });

  @override
  State<_OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<_OverlayWidget>{
  double _backgroundOpacity = 0;

  double _widgetPositionLeft = 0;
  double _widgetPositionTop = 0;
  double? _widgetPositionWidth = 0;
  double? _widgetPositionHeight = 0;
  bool _isFullScreen = false;
  bool _isDraging = false;

  double get closingThreshold => MediaQuery.of(context).size.height / 5;

  @override
  void initState() {
    _resetAnimation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 10), () => _startOpenAnimation());

    return GestureDetector(
      onTap: () => _startCloseAnimation(),
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: widget.duration,
              opacity: _backgroundOpacity,
              child: Container(
                color: widget.backgroundColor ?? Colors.white,
              ),
            ),
          ),
          AnimatedPositioned(
            left: _widgetPositionLeft,
            top: _widgetPositionTop,
            width: _widgetPositionWidth,
            height: _widgetPositionHeight,
            duration: widget.duration,
            child: RotatedBox(
              quarterTurns: widget.direction == Axis.vertical ? 1 : 0,
              child: widget.child,
            ),
            onEnd: (){
              if(_isDraging) return;

              _isFullScreen = !_isFullScreen;
              if(!_isFullScreen && !_isDraging) widget.onOverlayClose?.call();
            },
          ),
          getTopWidget(),
          getBottomWidget(),
        ],
      ),
    );
  }

  Widget getTopWidget(){
    if(widget.topWidget == null) return const SizedBox();

    if(widget.direction == Axis.vertical){
      return Positioned(
        right: 0,
        bottom: 0,
        top: 0,
        child: widget.topWidget!,
      );
    }
    else{
      return Positioned(
        left: 0,
        right: 0,
        top: widget.padding.top,
        child: widget.topWidget!,
      );
    }
  }

  Widget getBottomWidget(){
    if(widget.bottomWidget == null) return const SizedBox();

    if(widget.direction == Axis.vertical){
      return Positioned(
        left: 0,
        bottom: 0,
        top: 0,
        child: widget.bottomWidget!,
      );
    }
    else{
      return Positioned(
        left: 0,
        right: 0,
        bottom: widget.padding.bottom,
        child: widget.bottomWidget!,
      );
    }
  }

  void _resetAnimation(){
    _isFullScreen = false;
    _widgetPositionLeft = widget.offset.dx;
    _widgetPositionTop = widget.offset.dy;

    _widgetPositionWidth = widget.size.width;
    _widgetPositionHeight = widget.size.height;

    _backgroundOpacity = 0;

    if(context.mounted) setState(() {});
  }

  void _startOpenAnimation(){
    if(_isFullScreen) return;

    _widgetPositionLeft = widget.padding.left;
    _widgetPositionTop = widget.padding.top;

    _widgetPositionWidth = MediaQuery.of(context).size.width - widget.padding.horizontal;
    _widgetPositionHeight = MediaQuery.of(context).size.height - (widget.padding.top + widget.padding.bottom);


    _backgroundOpacity = 1;

    if(context.mounted) setState(() {});
  }

  void _startCloseAnimation(){
    if(!_isFullScreen) return;

    _isDraging = false;

    _widgetPositionLeft = widget.offset.dx;
    _widgetPositionTop = widget.offset.dy;

    _widgetPositionWidth = widget.size.width;
    _widgetPositionHeight = widget.size.height;

    _backgroundOpacity = 0;

    if(context.mounted) setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails details){
    setState(() {
      _isDraging = true;
      _widgetPositionTop += details.delta.dy;
      //_backgroundOpacity = (1 - (_widgetPositionTop / closingThreshold)).clamp(0, 1).toDouble();
    });
  }

  void _onDragEnd(DragEndDetails endDetails){
    // can close le
    print(_widgetPositionTop);
    print(widget.padding.top + closingThreshold);
    if(_widgetPositionTop > widget.padding.top + closingThreshold || _widgetPositionTop < widget.padding.top - closingThreshold){
      _startCloseAnimation();
    }
    else{
      setState(() {
        _widgetPositionTop = widget.padding.top;
        //_backgroundOpacity = 1;
      });
    }
  }
}