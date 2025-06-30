import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  
  final double collapsedHeight;
  final double expandedHeight;
  final Widget Function(BuildContext context, double shrinkOffset, bool overlapsContent) appBarBuilder;
  final Widget Function(BuildContext context, double shrinkOffset, bool overlapsContent)? backgroundBuilder;
  final PreferredSize Function(BuildContext context, double shrinkOffset, bool overlapsContent)? bottomWidgetBuilder;

  double bottomHeight = 0;

  CustomSliverAppBarDelegate({
    required this.collapsedHeight, 
    required this.expandedHeight,
    required this.appBarBuilder,
    this.backgroundBuilder,
    this.bottomWidgetBuilder,
  });
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bottomWidget = bottomWidgetBuilder?.call(context, shrinkOffset, overlapsContent);
    if(bottomWidget != null) bottomHeight = bottomWidget.preferredSize.height;

    return Stack(
      children: [
        if(backgroundBuilder != null)
          Positioned.fill(
            child: backgroundBuilder!(context, shrinkOffset, overlapsContent)
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: appBarBuilder(context, shrinkOffset, overlapsContent),
        ),
        if(bottomWidget != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: bottomHeight,
              child: bottomWidget.child,
            ),
          ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant CustomSliverAppBarDelegate oldDelegate) {
    if(oldDelegate.appBarBuilder != appBarBuilder) return true;
    if(oldDelegate.bottomWidgetBuilder != bottomWidgetBuilder) return true;
    if(oldDelegate.expandedHeight != expandedHeight) return true;
    if(oldDelegate.collapsedHeight != collapsedHeight) return true;
    if(oldDelegate.bottomHeight != bottomHeight) return true;
    if(oldDelegate.maxExtent != maxExtent) return true;
    if(oldDelegate.minExtent != minExtent) return true;
    return false;
  }
  
  @override
  OverScrollHeaderStretchConfiguration? get stretchConfiguration => OverScrollHeaderStretchConfiguration();
  
}