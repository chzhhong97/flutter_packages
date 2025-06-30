import 'package:flutter/material.dart';

class IndicatorPreferences{
  final String? text;
  final Widget? indicatorWidget;
  final TextStyle? textStyle;
  final double size;

  const IndicatorPreferences({
    this.text,
    this.indicatorWidget,
    this.textStyle,
    this.size = 25,
  });

  IndicatorPreferences merge(IndicatorPreferences? other){
    return IndicatorPreferences(
      text: other?.text ?? text,
      indicatorWidget: other?.indicatorWidget ?? indicatorWidget,
      textStyle: textStyle?.merge(other?.textStyle),
      size: other?.size ?? size,
    );
  }
}