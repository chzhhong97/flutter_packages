import 'dart:async';

import 'package:flutter/material.dart';

class ExpandedSection extends StatefulWidget {

  final Widget child;
  final bool expand;
  final Duration duration;
  final Duration collapseDelay;
  final Duration expandDelay;
  final bool topToBottom;
  const ExpandedSection({super.key,
    this.expand = false,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.collapseDelay = Duration.zero,
    this.expandDelay =  Duration.zero,
    this.topToBottom = false,
  });

  @override
  _ExpandedSectionState createState() => _ExpandedSectionState();
}

class _ExpandedSectionState extends State<ExpandedSection> with SingleTickerProviderStateMixin {
  late final AnimationController expandController = AnimationController(
      vsync: this,
      duration: widget.duration
  );
  late final Animation<double> animation = CurvedAnimation(
    parent: expandController,
    curve: Curves.fastOutSlowIn,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _runExpandCheck();
  }

  void _runExpandCheck() {
    _timer?.cancel();

    if(widget.expand) {
      if(expandController.status == AnimationStatus.forward) return;

      _timer = Timer(widget.expandDelay, () {
        if(widget.expand && context.mounted) expandController.forward().whenComplete(() => null);
      });
    }
    else {
      if(expandController.status == AnimationStatus.reverse) return;
      _timer = Timer(widget.collapseDelay, () {
        if(!widget.expand && context.mounted) expandController.reverse().whenComplete(() => null);
      });
    }
  }

  @override
  void didUpdateWidget(ExpandedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    expandController.dispose();
    _timer?.cancel();
    _timer = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        axisAlignment: widget.topToBottom ? -1.0 : 1.0,
        sizeFactor: animation,
        child: widget.child
    );
  }
}