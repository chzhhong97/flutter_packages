import 'package:flutter/material.dart';

class SizeMeasureWidget extends StatelessWidget{
  final GlobalKey _globalKey = GlobalKey();
  final Widget child;

  SizeMeasureWidget({super.key, required this.child});

  Size? get size => (_globalKey.currentContext?.findRenderObject() as RenderBox?)?.size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _globalKey,
      child: child,
    );
  }
}