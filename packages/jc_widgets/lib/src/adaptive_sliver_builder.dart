import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jc_widgets/sliver_widgets.dart';
import 'package:sliver_tools/src/rendering/multi_sliver.dart';
import 'package:sliver_tools/src/rendering/sliver_stack.dart';
import 'package:sliver_tools/src/rendering/sliver_clip.dart';

class AdaptiveSliverBuilder extends StatelessWidget {
  /// Use this to detect if this widget is under RenderSliverViewport like CustomScrollView & NestedScrollView headers
  /// Not working for SliverStickyHeader
  const AdaptiveSliverBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool isSliverLayout) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context,
        _hasSupportRenderSliver(context) && _hasMatchingAncestor(context));
  }

  static const List<Type> _targetTypes = [
    CustomScrollView,
    NestedScrollViewViewport,
  ];

  bool _hasMatchingAncestor(BuildContext context) {
    for (final type in _targetTypes) {
      if (_typeToWidget(type, context) != null) {
        return true;
      }
    }
    return false;
  }

  bool _hasSupportRenderSliver(BuildContext context) {
    final renderSliver = context.findAncestorRenderObjectOfType<RenderSliver>();
    if (renderSliver == null) return true;

    switch (renderSliver.runtimeType) {
      case const (RenderMultiSliver):
      case const (RenderSliverPadding):
      case const (RenderSliverStack):
      case const (RenderSliverClip):
      case const (RenderSliverMainAxisGroup):
      case const (RenderSliverCrossAxisGroup):
      case const (RenderSliverOverlapAbsorber):
      case const (RenderSliverOverlapInjector):
      case const (RenderSliverStickyHeader):
        return true;
      default:
        return false;
    }
  }

  Widget? _typeToWidget(Type type, BuildContext context) {
    return switch (type) {
      const (CustomScrollView) =>
        context.findAncestorWidgetOfExactType<CustomScrollView>(),
      const (NestedScrollViewViewport) =>
        context.findAncestorWidgetOfExactType<NestedScrollViewViewport>(),
      _ => null,
    };
  }
}
