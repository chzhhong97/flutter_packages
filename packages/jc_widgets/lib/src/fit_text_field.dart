import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FitTextField extends StatefulWidget {
  final double? minWidth;
  final double? maxWidth;
  final String? textValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;

  final int? maxLines;
  final int? minLines;
  final bool expands;
  final bool readOnly;
  final bool? showCursor;
  static const int noMaxLength = -1;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final bool? ignorePointers;
  final double cursorWidth;

  factory FitTextField.digit(num count, {
    TextEditingController? controller,
    FocusNode? focusNode,
    int precision = 0,
    int minValue = 0,
    int? maxValue,
    required Function(int value) onChanged,
    Function(int value)? onSubmitted,
    double? minWidth,
    double? maxWidth,
    int maxLines = 1,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    bool? showCursor,
  }) => FitTextField(
    textValue: count.toStringAsFixed(precision),
    controller: controller,
    focusNode: focusNode,
    minWidth: minWidth,
    maxWidth: maxWidth,
    decoration: InputDecoration.collapsed(
      hintText: count.toStringAsFixed(precision),
      border: InputBorder.none,
    ),
    style: style,
    maxLines: maxLines,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      TextInputFormatter.withFunction(
              (oldValue, newValue){
            if(newValue.text.isEmpty) return TextEditingValue(text: minValue.toStringAsFixed(precision));
            if(oldValue.text.length == 1 && oldValue.text == '0') {
              final firstChar = newValue.text.substring(0, 1);
              final secondChar = newValue.text.substring(1, 2);
              return TextEditingValue(text: firstChar == '0' ? secondChar : firstChar);
            }

            var count = int.tryParse(newValue.text);
            if(count != null && maxValue != null && count > maxValue){
              return TextEditingValue(text: maxValue.toStringAsFixed(precision));
            }

            return newValue;
          }
      )
    ],
    textAlign: textAlign,
    showCursor: showCursor,
    onChanged: (text){
      final count = int.tryParse(text);
      if(count != null) onChanged(count);
    },
    onSubmitted: (text){
      final count = int.tryParse(text);
      if(count != null) onSubmitted?.call(count);
    },
  );

  const FitTextField({
    super.key,
    this.minWidth = 30,
    this.maxWidth,
    this.textValue,
    this.style,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    TextInputType? keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.showCursor,
    this.textDirection,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.ignorePointers,
    this.cursorWidth = 2.0,
  }) : keyboardType = keyboardType ?? (maxLines == 1 ? TextInputType.text : TextInputType.multiline);

  @override
  State<StatefulWidget> createState() => FitTextFieldState();
}

class FitTextFieldState extends State<FitTextField> {

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    if(widget.textValue != null) _controller.text = widget.textValue!;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FitTextField oldWidget) {
    if(widget.textValue != null && oldWidget.textValue != widget.textValue) _controller.text = widget.textValue!;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // TextField merges given textStyle with text style from current theme
    // Do the same to get final TextStyle
    final ThemeData themeData = Theme.of(context);
    final style = themeData.textTheme.bodyLarge?.merge(widget.style);
    final textField = widget.controller ?? _controller;

    // Use TextPainter to calculate the width of our text
    TextSpan ts = TextSpan(style: style, text: textField.text);
    TextPainter tp = TextPainter(
      text: ts,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    // Enforce a minimum width
    double textWidth = max(widget.minWidth ?? 0, tp.width + widget.cursorWidth * 2);
    if(widget.maxWidth != null && textWidth > widget.maxWidth!) textWidth = widget.maxWidth!;

    return Container(
      width: textWidth,
      padding: EdgeInsets.only(
        left: widget.cursorWidth
      ),
      child: TextField(
        cursorWidth: widget.cursorWidth,
        style: style,
        controller: textField,
        inputFormatters: widget.inputFormatters,
        decoration: widget.decoration,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textAlignVertical: widget.textAlignVertical,
        textDirection: widget.textDirection,
        showCursor: widget.showCursor,
        readOnly: widget.readOnly,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        maxLengthEnforcement: widget.maxLengthEnforcement,
        onEditingComplete: widget.onEditingComplete,
        enabled: widget.enabled,
        ignorePointers: widget.ignorePointers,
        expands: widget.expands,
        onChanged: (text) {
          // Redraw the widget
          setState(() {});
          widget.onChanged?.call(text);
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}