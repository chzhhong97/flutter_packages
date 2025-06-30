import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jc_widgets/src/measure_size.dart';

import 'custom_sliver_app_bar_delegate.dart';

class CustomSliverAppBar extends StatefulWidget{
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final double collapsedHeight;
  final Widget Function(BuildContext context, double shrinkOffset, bool overlapContents) appBarBuilder;
  final Widget Function(BuildContext context, double shrinkOffset, bool overlapContents)? backgroundBuilder;
  final Widget Function(BuildContext context, double shrinkOffset, bool overlapContents)? bottomWidgetBuilder;
  /// The bottom widget size should be changes accordingly with this, else overflow will occur
  final double Function(double originalSize, double shrinkOffset, bool overlapContents)? recalculateBottomSize;
  final bool collapseIncludeBottom;
  final bool expandIncludeBottom;
  final void Function()? onSizeUpdated;
  final double bottomWidgetBorderRadius;
  final Color bottomWidgetBackgroundColor;

  const CustomSliverAppBar({
    super.key,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.appBarBuilder,
    this.backgroundBuilder,
    this.bottomWidgetBuilder,
    this.onSizeUpdated,
    this.recalculateBottomSize,
    this.collapseIncludeBottom = false,
    this.expandIncludeBottom = false,
    this.pinned = false,
    this.floating = false,
    this.bottomWidgetBorderRadius = 0,
    this.bottomWidgetBackgroundColor = Colors.white,
  });

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar>{

  double _bottomHeight = 0;
  double bottomHeight = 0;

  OverlayEntry? overlayEntry;
  final Queue<VoidCallback> _removeQueue = Queue();

  @override
  void initState() {
    //bottomHeight = widget.expandedHeight * .25;
    _calculateBottomWidgetSize();

    super.initState();
  }

  void _calculateBottomWidgetSize(){
    if(widget.bottomWidgetBuilder != null){
      removeOverlay();

      overlayEntry = OverlayEntry(
          builder: (context) => Stack(
            children: [
              Opacity(
                opacity: 0,
                child: MeasureSize(
                  onChange: (Size value) {
                    //final newHeight = value.height > widget.expandedHeight ? widget.expandedHeight : value.height;

                    removeOverlay();

                    if(value.height == _bottomHeight) return;
                    setState(() {
                      //print(value.height);
                      widget.onSizeUpdated?.call();
                      _bottomHeight = value.height;
                      bottomHeight = _bottomHeight;
                    });
                  },
                  child: widget.bottomWidgetBuilder!(context, 0, false),
                ),
              )
            ],
          )
      );

      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if(overlayEntry != null) Overlay.of(context).insert(overlayEntry!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant CustomSliverAppBar oldWidget) {

    if(oldWidget.bottomWidgetBuilder != widget.bottomWidgetBuilder && _bottomHeight != 0){
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _calculateBottomWidgetSize();
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: widget.pinned,
      floating: widget.floating,
      delegate: CustomSliverAppBarDelegate(
          expandedHeight: widget.expandIncludeBottom ? widget.expandedHeight + bottomHeight : widget.expandedHeight,
          collapsedHeight: widget.collapseIncludeBottom ? widget.collapsedHeight + bottomHeight : widget.collapsedHeight,
          appBarBuilder: widget.appBarBuilder,
          backgroundBuilder: (context, shrinkOffset, overlapContents){
            return Padding(
              padding: EdgeInsets.only(bottom: (bottomHeight - widget.bottomWidgetBorderRadius).clamp(0, bottomHeight)),
              child: widget.backgroundBuilder?.call(context, shrinkOffset, overlapContents),
            );
          },
          bottomWidgetBuilder: widget.bottomWidgetBuilder != null ? (context, shrinkOffset, overlapContents){
            return PreferredSize(
              preferredSize: Size.fromHeight(_recalculateSize(_bottomHeight, shrinkOffset, overlapContents)),
              child: Container(
                decoration: BoxDecoration(
                    color: widget.bottomWidgetBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(widget.bottomWidgetBorderRadius)
                    )
                ),
                child: widget.bottomWidgetBuilder!(context, shrinkOffset, overlapContents),
              ),
            );
          } : null
      ),
    );
  }

  double _recalculateSize(double originalSize, double shrinkOffset, bool overlapContents){
    if(widget.recalculateBottomSize == null || originalSize == 0) return originalSize;

    final newSize = widget.recalculateBottomSize!(originalSize, shrinkOffset, overlapContents).clamp(0, originalSize).toDouble();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        bottomHeight = newSize;
        widget.onSizeUpdated?.call();
      });
    });

    return newSize;
  }

  void removeOverlay(){
    _removeQueue.add(() {
      if(overlayEntry != null && overlayEntry?.mounted == true){
        overlayEntry?.remove();
      }
      overlayEntry = null;
    });

    _removeOverlay();
  }

  void _removeOverlay(){
    while(_removeQueue.isNotEmpty){
      var func = _removeQueue.removeFirst();
      func();
    }
  }

  @override
  void dispose() {
    removeOverlay();
    super.dispose();
  }
}