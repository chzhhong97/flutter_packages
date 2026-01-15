import 'dart:math';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:jc_widgets/src/custom_pull_to_refresh/classic_pull_to_refresh_indicator.dart';

export 'package:custom_refresh_indicator/custom_refresh_indicator.dart';

class CustomPullToRefresh extends StatefulWidget {
  final Widget child;
  final RefreshIndicatorSettings settings;
  final Future<void> Function()? onRefresh;

  const CustomPullToRefresh(
      {super.key,
      this.settings = const RefreshIndicatorSettings(),
      this.onRefresh,
      required this.child});

  @override
  State<CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<CustomPullToRefresh> {
  @override
  Widget build(BuildContext context) {
    if (widget.onRefresh == null) return widget.child;

    if (widget.settings.useMaterial) {
      return CustomMaterialIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          durations: widget.settings.durations,
          trigger: widget.settings.trigger,
          triggerMode: widget.settings.triggerMode,
          controller: widget.settings.controller,
          backgroundColor: widget.settings.backgroundColor,
          displacement: widget.settings.height,
          edgeOffset: widget.settings.edgeOffset ?? (-CustomMaterialIndicator.defaultIndicatorSize.width / 2),
          indicatorSize: widget.settings.materialIndicatorSize ?? CustomMaterialIndicator.defaultIndicatorSize,
          indicatorBuilder: (context, controller) {
            if (widget.settings.indicatorBuilder != null) {
              return widget.settings.indicatorBuilder?.call(
                  context,
                  controller.state,
                  controller.value.clamp(0.0, 1.25),
                  controller.edge ?? IndicatorEdge.leading);
            }

            return Padding(
              padding: const EdgeInsets.all(6.0),
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                value: controller.state.isLoading
                    ? null
                    : min(controller.value, 1.0),
              ),
            );
          },
          notificationPredicate: (n) {
            if (widget.settings.depths.isEmpty) return true;
            return widget.settings.depths.contains(n.depth);
          },
          child: widget.child);
    }

    return CustomRefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        durations: widget.settings.durations,
        trigger: widget.settings.trigger,
        triggerMode: widget.settings.triggerMode,
        controller: widget.settings.controller,
        builder: (context, child, controller) {
          final height = widget.settings.height;
          return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                var dy = -(controller.value.clamp(0.0, 1.25) *
                    -(height - (height * 0.25)));

                double? top = -height;
                double? bottom;

                if (controller.edge == IndicatorEdge.trailing) {
                  top = null;
                  bottom = -height;
                  dy *= -1;
                }

                return Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(0.0, dy),
                      child: child,
                    ),
                    Positioned(
                      bottom: bottom,
                      top: top,
                      left: 0,
                      right: 0,
                      height: height,
                      child: Container(
                        transform: Matrix4.translationValues(0.0, dy, 0.0),
                        constraints: const BoxConstraints.expand(),
                        color: widget.settings.backgroundColor,
                        padding: EdgeInsets.only(
                          top: controller.edge == IndicatorEdge.leading
                              ? height * .25
                              : 0,
                          bottom: controller.edge == IndicatorEdge.trailing
                              ? height * .25
                              : 0,
                        ),
                        child: widget.settings.indicatorBuilder?.call(
                                context,
                                controller.state,
                                controller.value.clamp(0.0, 1.25),
                                controller.edge ?? IndicatorEdge.leading) ??
                            CustomRefreshState(
                              state: controller.state,
                              value: controller.value.clamp(0.0, 1.25),
                              edge: controller.edge ?? IndicatorEdge.leading,
                              child: widget.settings.refreshIndicator,
                            ),
                      ),
                    ),
                  ],
                );
              });
        },
        notificationPredicate: (n) {
          if (widget.settings.depths.isEmpty) return true;
          return widget.settings.depths.contains(n.depth);
        },
        child: widget.child);
  }
}

class CustomRefreshState extends InheritedWidget {
  const CustomRefreshState({
    super.key,
    required this.state,
    required this.value,
    required this.edge,
    required super.child,
  });

  final IndicatorState state;
  final double value;
  final IndicatorEdge edge;

  static CustomRefreshState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CustomRefreshState>();

  @override
  bool updateShouldNotify(CustomRefreshState oldWidget) =>
      oldWidget.state != state ||
      oldWidget.value != value ||
      oldWidget.edge != edge;
}

class RefreshIndicatorSettings {
  /// If use material this will use as displacement
  final double height;
  final RefreshIndicatorDurations durations;
  final Widget refreshIndicator;
  final Function(BuildContext context, IndicatorState state, double value,
      IndicatorEdge edge)? indicatorBuilder;
  final IndicatorTrigger trigger;
  final IndicatorTriggerMode triggerMode;
  final IndicatorController? controller;
  final Color? backgroundColor;
  final List<int> depths;
  final bool useMaterial;
  /// Edge offset for material indicator
  final double? edgeOffset;
  /// Size for material indicator
  final Size? materialIndicatorSize;

  const RefreshIndicatorSettings({
    this.height = 150.0,
    this.durations = const RefreshIndicatorDurations(),
    this.refreshIndicator = const ClassicPullToRefreshIndicator(),
    this.indicatorBuilder,
    this.trigger = IndicatorTrigger.leadingEdge,
    this.triggerMode = IndicatorTriggerMode.onEdge,
    this.controller,
    this.backgroundColor,
    this.depths = const [],
    this.useMaterial = false,
    this.edgeOffset,
    this.materialIndicatorSize,
  });

  RefreshIndicatorSettings copyWith({
    double? height,
    RefreshIndicatorDurations? durations,
    Widget? refreshIndicator,
    Function(BuildContext context, IndicatorState state, double value,
            IndicatorEdge edge)?
        indicatorBuilder,
    IndicatorTrigger? trigger,
    IndicatorTriggerMode? triggerMode,
    IndicatorController? controller,
    Color? backgroundColor,
    List<int>? depths,
    bool? useMaterial,
    double? edgeOffset,
    Size? materialIndicatorSize,
  }) {
    return RefreshIndicatorSettings(
      height: height ?? this.height,
      durations: durations ?? this.durations,
      refreshIndicator: refreshIndicator ?? this.refreshIndicator,
      indicatorBuilder: indicatorBuilder ?? this.indicatorBuilder,
      trigger: trigger ?? this.trigger,
      triggerMode: triggerMode ?? this.triggerMode,
      controller: controller ?? this.controller,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      depths: depths ?? this.depths,
      useMaterial: useMaterial ?? this.useMaterial,
      edgeOffset: edgeOffset ?? this.edgeOffset,
      materialIndicatorSize: materialIndicatorSize ?? this.materialIndicatorSize,
    );
  }
}
