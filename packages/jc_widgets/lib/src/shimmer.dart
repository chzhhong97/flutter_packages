import 'package:cross_fade/cross_fade.dart';
import 'package:flutter/material.dart';

const shimmerGradient = LinearGradient(
  colors: [
    Color(0xFFEBEBF4),
    Color(0xFFF4F4F4),
    Color(0xFFEBEBF4),
  ],
  stops: [
    0.1,
    0.3,
    0.4,
  ],
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  tileMode: TileMode.mirror,
);

const shimmerGradient2 = LinearGradient(
  colors: [
    Color(0xFFFAFAFA), // Even Lighter Grey
    Color(0xFFFFEAF0), // Even Lighter Pink
    Color(0xFFFAFAFA), // Ev/ Even Lighter Pink (back to the original)
  ],
  stops: [
    0.1,
    0.3,
    0.4,
  ],
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  tileMode: TileMode.clamp,
);

class Shimmer extends StatefulWidget {
  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  const Shimmer({
    super.key,
    this.linearGradient = shimmerGradient,
    this.duration = const Duration(milliseconds: 1500),
    this.child,
  });

  final LinearGradient linearGradient;
  final Widget? child;
  final Duration duration;

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: widget.duration);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
// code-excerpt-closing-bracket
  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    if(oldWidget.duration != widget.duration){
      _shimmerController.stop();
      _shimmerController.repeat(min: -0.5, max: 1.5, period: widget.duration);
    }
    super.didUpdateWidget(oldWidget);
  }

  LinearGradient get gradient => LinearGradient(
    colors: widget.linearGradient.colors,
    stops: widget.linearGradient.stops,
    begin: widget.linearGradient.begin,
    end: widget.linearGradient.end,
    transform:
    _SlidingGradientTransform(slidePercent: _shimmerController.value),
  );

  bool get isSized => (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  Size get size => (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;

  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject() as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  Listenable get shimmerChanges => _shimmerController;

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerLoading extends StatefulWidget {
  static _ShimmerLoadingState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ShimmerLoadingState>();
  }
  const ShimmerLoading({
    super.key,
    this.isLoading = true,
    this.duration = const Duration(milliseconds: 300),
    required this.child,
  });

  final bool isLoading;
  final Widget child;
  final Duration duration;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  bool get isLoading => widget.isLoading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.isLoading) {
      setState(() {
        // update the shimmer painting.
      });
    }
  }
// code-excerpt-closing-bracket

  @override
  Widget build(BuildContext context) {

    return CrossFade<bool>(
      key: widget.child.key,
      value: widget.isLoading,
      duration: !widget.isLoading ? Duration.zero : widget.duration,
      builder: (BuildContext context, bool isLoading) {
        if(isLoading) return _buildShimmer(context, widget.child);
        return widget.child;
      },
    );
  }

  Widget _buildShimmer(BuildContext context, Widget child){
    // Collect ancestor shimmer info.
    final shimmer = Shimmer.of(context);
    if(shimmer == null) {
      throw Exception('You must wrap a Shimmer on ShimmerLoading');
    }
    if (!shimmer.isSized) {
      // The ancestor Shimmer widget has not laid
      // itself out yet. Return an empty box.
      return child;
    }
    final shimmerSize = shimmer.size;
    final gradient = shimmer.gradient;

    RenderObject? ro = context.findRenderObject();
    if(ro != null) {
      final offsetWithinShimmer = shimmer.getDescendantOffset(
        descendant: ro as RenderBox,
      );

      BorderRadiusGeometry? borderRadius;

      if (widget.child is Container) {
        final container = widget.child as Container;
        final d = container.decoration as BoxDecoration?;
        borderRadius = d?.borderRadius;
      }

      if (widget.child is Card) {
        final card = widget.child as Card;
        if (card.shape is RoundedRectangleBorder) {
          borderRadius = (card.shape as RoundedRectangleBorder).borderRadius;
        }
      }

      final shimmerWidget = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          return gradient.createShader(
            Rect.fromLTWH(
              -offsetWithinShimmer.dx,
              -offsetWithinShimmer.dy,
              shimmerSize.width,
              shimmerSize.height,
            ),
          );
        },
        child: widget.child,
      );

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: shimmerWidget,
        );
      }

      return shimmerWidget;
    }
    return const SizedBox();
  }
}

class ShimmerContainer extends StatelessWidget{
  const ShimmerContainer({super.key, required this.child, this.borderRadius});

  final Widget child;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {

    final isLoading = ShimmerLoading.of(context)?.isLoading ?? false;

    return Container(
      decoration: BoxDecoration(
          color: isLoading ? Colors.white : Colors.transparent,
          borderRadius: borderRadius ?? BorderRadius.circular(8)
      ),
      child: child,
    );
  }
}