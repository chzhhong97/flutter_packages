import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DynamicHeightSliverAppBar extends StatefulWidget {
  const DynamicHeightSliverAppBar({
    this.flexibleSpace,
    super.key,
    this.appBarKey,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.titleBuilder,
    this.actions,
    this.actionsBuilder,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.backgroundGradient,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
    this.toolbarHeight = kToolbarHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.appBarClipper,
    this.onCollapsed,
  });

  final Key? appBarKey;
  final Widget? flexibleSpace;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final Widget? Function(BuildContext context, bool isCollapsed)? titleBuilder;
  final List<Widget>? actions;
  final List<Widget>? Function(BuildContext context, bool isCollapsed)? actionsBuilder;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final bool forceElevated;
  final Color? backgroundColor;

  /// If backgroundGradient is non null, backgroundColor will be ignored
  final LinearGradient? backgroundGradient;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double? expandedHeight;
  final double? collapsedHeight;
  final bool floating;
  final bool pinned;
  final ShapeBorder? shape;
  final double toolbarHeight;
  final double? leadingWidth;
  final TextStyle? toolbarTextStyle;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? Function(bool)? systemOverlayStyle;
  final bool forceMaterialTransparency;
  final Clip? clipBehavior;
  final bool snap;
  final bool stretch;
  final double stretchTriggerOffset;
  final AsyncCallback? onStretchTrigger;
  final CustomClipper<Path>? appBarClipper;
  final void Function(bool)? onCollapsed;

  @override
  State<DynamicHeightSliverAppBar> createState() => _DynamicHeightSliverAppBarState();
}

class _DynamicHeightSliverAppBarState extends State<DynamicHeightSliverAppBar> {

  final GlobalKey _childKey = GlobalKey();
  final ValueNotifier<bool> _isCollapsed = ValueNotifier(false);
  double _height = 0;

  @override
  void initState() {
    super.initState();
    _updateHeight();
  }

  @override
  void didUpdateWidget(covariant DynamicHeightSliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateHeight();
  }

  void _updateHeight() {
    // Gets the new height and updates the sliver app bar. Needs to be called after the last frame has been rebuild
    // otherwise this will throw an error
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_childKey.currentContext == null) return;
      setState(() {
        final newHeight = (_childKey.currentContext!.findRenderObject()! as RenderBox).size.height;
        if(_height != newHeight) {
          _height = newHeight;
        }
      });
    });
  }

  Widget? _getFlexibleSpace(Widget? flexibleSpace){
    if(flexibleSpace != null){
      if(flexibleSpace is FlexibleSpaceBar) return flexibleSpace.background;
      return flexibleSpace;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SliverStack(
      children: [
        SliverOpacity(
          opacity: _height == 0 ? 1 : 0,
          sliver: SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                    key: _childKey,
                    child: _getFlexibleSpace(widget.flexibleSpace) ??
                        const SizedBox(height: kToolbarHeight)
                ),
                Positioned.fill(
                  // 10 is the magic number which the app bar is pushed down within the sliver app bar. Couldnt find exactly where this number
                  // comes from and found it through trial and error.
                  top: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: widget.leading,
                      actions: widget.actions,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        if(_height > 0)
          ValueListenableBuilder(
            valueListenable: _isCollapsed,
            builder: (BuildContext context, bool value, Widget? child) {
              return SliverAppBar(
                key: widget.appBarKey,
                leading: widget.leading,
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
                title: widget.titleBuilder?.call(context, value) ?? widget.title,
                actions: widget.actionsBuilder?.call(context, value) ?? widget.actions,
                bottom: widget.bottom,
                elevation: widget.elevation,
                scrolledUnderElevation: widget.scrolledUnderElevation,
                shadowColor: widget.shadowColor,
                surfaceTintColor: widget.surfaceTintColor,
                forceElevated: widget.forceElevated,
                backgroundColor: widget.backgroundColor,
                foregroundColor: widget.foregroundColor,
                iconTheme: widget.iconTheme,
                actionsIconTheme: widget.actionsIconTheme,
                primary: widget.primary,
                centerTitle: widget.centerTitle,
                excludeHeaderSemantics: widget.excludeHeaderSemantics,
                titleSpacing: widget.titleSpacing,
                collapsedHeight: widget.collapsedHeight,
                floating: widget.floating,
                pinned: widget.pinned,
                snap: widget.snap,
                stretch: widget.stretch,
                stretchTriggerOffset: widget.stretchTriggerOffset,
                onStretchTrigger: widget.onStretchTrigger,
                shape: widget.shape,
                toolbarHeight: widget.toolbarHeight,
                expandedHeight: widget.expandedHeight ?? (_height - MediaQuery.paddingOf(context).top),
                leadingWidth: widget.leadingWidth,
                toolbarTextStyle: widget.toolbarTextStyle,
                titleTextStyle: widget.titleTextStyle,
                systemOverlayStyle: widget.systemOverlayStyle?.call(value),
                forceMaterialTransparency: widget.forceMaterialTransparency,
                clipBehavior: widget.clipBehavior,
                flexibleSpace: widget.flexibleSpace != null ? LayoutBuilder(
                  builder: (context, constraints){
                    final top = constraints.constrainHeight();
                    final collapsedHeight = MediaQuery.of(context).viewPadding.top + (widget.collapsedHeight ?? widget.toolbarHeight) + (widget.bottom?.preferredSize.height ?? 0);

                    onCollapsed((collapsedHeight.toInt() - top.toInt()).abs() < 10);

                    return widget.flexibleSpace is FlexibleSpaceBar ? widget.flexibleSpace! : FlexibleSpaceBar(background: widget.flexibleSpace,);
                  },
                ) : null,
              );
            },
          )
      ],
    );
  }

  void onCollapsed(bool isCollapsed){
    if(_isCollapsed.value == isCollapsed) return;

    WidgetsBinding.instance.addPostFrameCallback((t){
      _isCollapsed.value = isCollapsed;
      widget.onCollapsed?.call(_isCollapsed.value);
    });
  }
}
