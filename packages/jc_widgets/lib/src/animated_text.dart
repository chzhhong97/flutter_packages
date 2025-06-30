import 'package:flutter/cupertino.dart';

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final Duration duration;
  final void Function()? onEnd;
  final Curve curve;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const AnimatedText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.textHeightBehavior,
    this.textWidthBasis = TextWidthBasis.parent,
    this.onEnd,
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  @override
  void didUpdateWidget(covariant AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style ||
        oldWidget.text != widget.text ||
        oldWidget.overflow != widget.overflow ||
        oldWidget.softWrap != widget.softWrap ||
        oldWidget.maxLines != widget.maxLines ||
        oldWidget.textWidthBasis != widget.textWidthBasis ||
        oldWidget.textHeightBehavior != widget.textHeightBehavior ||
        oldWidget.textAlign != widget.textAlign) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedDefaultTextStyle(
      style: widget.style,
      textAlign: widget.textAlign,
      duration: widget.duration,
      onEnd: widget.onEnd,
      curve: widget.curve,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      child: Text(widget.text));
}
