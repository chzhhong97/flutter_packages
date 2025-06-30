import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class MultilineText extends StatelessWidget {
  /// Auto expand height of the widget depend on max lines
  const MultilineText(String this.data,
      {super.key,
      this.style,
      this.strutStyle,
      this.textAlign,
      this.textDirection,
      this.locale,
      this.softWrap,
      this.overflow,
      @Deprecated(
        'Use textScaler instead. '
        'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
        'This feature was deprecated after v3.12.0-2.0.pre.',
      )
      this.textScaleFactor,
      this.textScaler,
      this.maxLines,
      this.semanticsLabel,
      this.textWidthBasis,
      this.textHeightBehavior,
      this.selectionColor,
        this.expandToMax = true,
        this.alignment = Alignment.topLeft
      }) : texts = const [], spacing = const [];

  const MultilineText.texts(this.texts,
      {super.key,
        this.spacing = const [],
        this.style,
        this.strutStyle,
        this.textAlign,
        this.textDirection,
        this.locale,
        this.softWrap,
        this.overflow,
        @Deprecated(
          'Use textScaler instead. '
              'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
              'This feature was deprecated after v3.12.0-2.0.pre.',
        )
        this.textScaleFactor,
        this.textScaler,
        this.maxLines,
        this.semanticsLabel,
        this.textWidthBasis,
        this.textHeightBehavior,
        this.selectionColor,
        this.expandToMax = true,
        this.alignment = Alignment.topLeft
      }) : data = null;

  final List<Text> texts;
  final String? data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Alignment alignment;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final bool expandToMax;
  final List<double> spacing;

  @override
  Widget build(BuildContext context) {
    if(data == null){
      return _buildMultiText(context);
    }

    return _buildSingleText(context);
  }

  Widget _buildSingleText(BuildContext context){
    final text = Text(
      data!,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );

    if(maxLines == null || maxLines! < 1){
      return text;
    }

    return LayoutBuilder(
      builder: (context, constraints){
        final textSize = _getTextSize(context, text, maxWidth: constraints.maxWidth);

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: expandToMax ? textSize.height : 0,
              maxHeight: textSize.height,
              maxWidth: textSize.width
          ),
          child: Align(
            alignment: alignment,
            child: text,
          ),
        );
      },
    );
  }

  Widget _buildMultiText(BuildContext context){
    if(texts.isEmpty) return const SizedBox();

    final totalSpacing = spacing.fold(0.0, (v, e) => v+e);

    return LayoutBuilder(
      builder: (context, constraints){
        Size totalSize = texts.map((e){
          return _getTextSize(context, e, maxWidth: constraints.maxWidth);
        })
            .fold(Size.zero, (initial, value){
          return Size(
            value.width > initial.width ? value.width : initial.width,
            initial.height + value.height,
          );
        });

        MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
        if(alignment.y == 0) {
          mainAxisAlignment = MainAxisAlignment.center;
        }
        else if(alignment.y > 0){
          mainAxisAlignment = MainAxisAlignment.end;
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: expandToMax ? (totalSize.height + totalSpacing) : 0,
            maxHeight: totalSize.height + totalSpacing,
            maxWidth: totalSize.width
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: mainAxisAlignment,
            children: [
              for(int i = 0; i < texts.length; i++)...[
                texts[i],
                if(i < spacing.length)
                  SizedBox(height: spacing[i],),
              ]
            ],
          ),
        );
      },
    );
  }

  Size _getTextSize(BuildContext context, Text text, {double minWidth = 0, double maxWidth = double.infinity}){
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = text.style;
    if (text.style == null || text.style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(text.style);
    }

    return Size(
      _getTextWidth(context, text, minWidth: minWidth, maxWidth: maxWidth, style: effectiveTextStyle),
      _getTextHeight(context, text, minWidth: minWidth, maxWidth: maxWidth, style: effectiveTextStyle),
    );
  }

  double _getTextHeight(BuildContext context, Text text, {double minWidth = 0, double maxWidth = double.infinity, TextStyle? style}){
    TextSpan ts = TextSpan(
      text: text.maxLines != null ? List.generate(text.maxLines!, (i) => '$i').join('\n') : text.data,
      style: style,
    );

    TextPainter tp = TextPainter(
      text: ts,
      textDirection: text.textDirection ?? TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
    tp.layout(minWidth: minWidth, maxWidth: maxWidth);

    return tp.height;
  }

  double _getTextWidth(BuildContext context, Text text, {double minWidth = 0, double maxWidth = double.infinity, TextStyle? style}){
    TextSpan ts = TextSpan(
      text: text.data,
      style: style,
    );

    TextPainter tp = TextPainter(
      text: ts,
      textDirection: text.textDirection ?? TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
    tp.layout(minWidth: minWidth, maxWidth: maxWidth);

    return tp.width;
  }
}
