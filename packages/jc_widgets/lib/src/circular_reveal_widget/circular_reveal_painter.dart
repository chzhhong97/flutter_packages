import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CircularRevealPainter extends CustomPainter {
  CircularRevealPainter({
    required Color backgroundColor,
    required Color currentCircleColor,
    required Color nextCircleColor,
    this.transitionPercent = 0,
    this.baseCircleRadius = 36,
    this.iconRatio = .6,
    this.alignment = Alignment.center,
    this.iconAlignment = Alignment.center,
    this.icon = Icons.arrow_forward_ios,
    this.hideIconInTransition = false,
    this.clipCanvas = true,
    this.circleLeftBoundAlignment = CircleLeftBoundAlignment.center,
    this.transitionDirection = Axis.horizontal,
    this.curve = Curves.easeInOut,
  })  : backgroundPaint = Paint()..color = backgroundColor,
        currentCirclePaint = Paint()..color = currentCircleColor,
        nextCirclePaint = Paint()..color = nextCircleColor;

  final Paint backgroundPaint;
  final Paint currentCirclePaint;
  final Paint nextCirclePaint;
  final double transitionPercent;
  final double baseCircleRadius;
  final double iconRatio;
  final Alignment alignment;
  final IconData icon;
  final Alignment iconAlignment;
  final bool hideIconInTransition;
  final bool clipCanvas;
  final CircleLeftBoundAlignment circleLeftBoundAlignment;
  final Axis transitionDirection;
  final Curve curve;

  @override
  void paint(Canvas canvas, Size size) {
    if(clipCanvas){
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.clipRect(rect);
    }

    if (transitionPercent < 0.5) {
      final double expansionPercent = transitionPercent / .5;
      _paintExpansion(canvas, size, expansionPercent);
    } else {
      final double contractionPercent = (transitionPercent - .5) / .5;
      _paintContraction(canvas, size, contractionPercent);
    }
  }

  void _paintExpansion(Canvas canvas, Size size, double percent) {
    // The max radius
    final double maxRadius = size.height * 200;

    // Original offset
    Offset baseCircleCenter = Offset(
        size.width * _convertAlignment(alignment.x),
        size.height * _convertAlignment(alignment.y));

    final easedExpansionPercent = percent;
    // Make circle expand slow
    final double slowedExpansionPercent =
        pow(easedExpansionPercent, 8).toDouble();

    final double currentRadius =
        (maxRadius * slowedExpansionPercent) + baseCircleRadius;

    // Left side of circle
    //final leftBoundOffset = transformCircleLeftBoundOnStart ? baseCircleRadius * easedExpansionPercent : 0;
    double leftBoundOffset = 0;
    switch (circleLeftBoundAlignment) {
      case CircleLeftBoundAlignment.left:
        leftBoundOffset = 0;
        break;
      case CircleLeftBoundAlignment.center:
        leftBoundOffset = baseCircleRadius * easedExpansionPercent;
        break;
      case CircleLeftBoundAlignment.right:
        leftBoundOffset = (baseCircleRadius * 2) * easedExpansionPercent;
        break;
    }

    //final double circleLeftBound = baseCircleCenter.dx - (baseCircleRadius - leftBoundOffset);
    double circleX = baseCircleCenter.dx;
    double circleY = baseCircleCenter.dy;

    switch (transitionDirection) {
      case Axis.horizontal:
        circleX = (baseCircleCenter.dx - (baseCircleRadius - leftBoundOffset)) +
            currentRadius;
        break;
      case Axis.vertical:
        circleY = (baseCircleCenter.dy - (baseCircleRadius - leftBoundOffset)) +
            currentRadius;
        break;
    }

    final Offset currentCircleCenter = Offset(
      circleX,
      circleY,
    );

    //Paint background
    canvas.drawPaint(backgroundPaint);

    //Pain circle
    canvas.drawCircle(currentCircleCenter, currentRadius, currentCirclePaint);

    //Paint icon
    if (hideIconInTransition && percent >= .1) return;

    _paintIcon(canvas, baseCircleCenter, backgroundPaint.color);
  }

  void _paintContraction(Canvas canvas, Size size, double percent) {
    // The max radius
    final double maxRadius = size.height * 200;

    // Original offset
    Offset baseCircleCenter = Offset(
        size.width * _convertAlignment(alignment.x),
        size.height * _convertAlignment(alignment.y));

    // Make circle contract slow
    final easedContractionPercent = curve.transform(percent);
    final double inverseContractionPercent = 1 - percent;
    final double slowedInverseContractionPercent =
        pow(inverseContractionPercent, 8).toDouble();

    final double currentRadius =
        (maxRadius * slowedInverseContractionPercent) + baseCircleRadius;

    // The right side of the circle that will become left side
    //final double circleRightSideOffset = transformCircleLeftBoundOnStart ? 0 : baseCircleRadius;
    double circleRightSideOffset = 0;
    switch (circleLeftBoundAlignment) {
      case CircleLeftBoundAlignment.left:
        circleRightSideOffset = baseCircleRadius;
        break;
      case CircleLeftBoundAlignment.center:
        circleRightSideOffset = 0;
        break;
      case CircleLeftBoundAlignment.right:
        circleRightSideOffset = -baseCircleRadius;
        break;
    }

    double circleCurrentCenterX = baseCircleCenter.dx;
    double circleCurrentCenterY = baseCircleCenter.dy;

    switch (transitionDirection) {
      case Axis.horizontal:
        final double circleStartingRightSide =
            baseCircleCenter.dx - circleRightSideOffset;

        // The final right side of circle
        final double circleEndingRightSide =
            baseCircleCenter.dx + baseCircleRadius;

        final double circleCurrentRightSide = circleStartingRightSide +
            ((circleEndingRightSide - circleStartingRightSide) *
                easedContractionPercent);
        circleCurrentCenterX = circleCurrentRightSide - currentRadius;
        break;
      case Axis.vertical:
        final double circleStartingTopSide =
            baseCircleCenter.dy - circleRightSideOffset;

        // The final top side of circle
        final double circleEndingTopSide =
            baseCircleCenter.dy + baseCircleRadius;

        final double circleCurrentTopSide = circleStartingTopSide +
            ((circleEndingTopSide - circleStartingTopSide) *
                easedContractionPercent);
        circleCurrentCenterY = circleCurrentTopSide - currentRadius;
        break;
    }

    final Offset currentCircleCenter = Offset(
      circleCurrentCenterX,
      circleCurrentCenterY,
    );

    //Paint background
    canvas.drawPaint(currentCirclePaint);

    //Paint circle
    canvas.drawCircle(currentCircleCenter, currentRadius, backgroundPaint);

    //Paint new expanding circle
    if (easedContractionPercent > .9) {
      double newCircleExpansionPercent = (easedContractionPercent - .9) / .1;
      double newCircleRadius = baseCircleRadius * newCircleExpansionPercent;

      canvas.drawCircle(currentCircleCenter, newCircleRadius, nextCirclePaint);
    }

    //Paint icon
    if (hideIconInTransition && percent < .95) return;

    _paintIcon(canvas, baseCircleCenter, currentCirclePaint.color);
  }

  void _paintIcon(Canvas canvas, Offset circleCenter, Color color) {
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: icon.fontFamily,
        fontSize: baseCircleRadius * iconRatio.clamp(0, 1),
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(ui.TextStyle(color: color))
      ..addText(String.fromCharCode(icon.codePoint));

    final ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: baseCircleRadius));

    canvas.drawParagraph(
        paragraph,
        circleCenter -
            Offset(paragraph.width - (paragraph.width * _convertAlignment(iconAlignment.x)),
                paragraph.height - (paragraph.height * _convertAlignment(iconAlignment.y))));
  }

  double _convertAlignment(double value) {
    return (value + 1) / 2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

enum CircleLeftBoundAlignment {
  left,
  center,
  right;
}
