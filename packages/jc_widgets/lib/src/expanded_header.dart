import 'package:flutter/material.dart';

class ExpandedHeader extends StatefulWidget {

  final Widget Function(bool,Function({bool? value}))? headerBuilder;
  final Widget Function(bool,Function({bool? value}))? footerBuilder;
  final Widget Function(BuildContext context) expandedBuilder;
  final Duration duration;
  final Function(bool)? onExpandChanged;
  final bool? initialExpand;
  final bool prioritizeInitExpand;

  const ExpandedHeader({super.key,
    required this.expandedBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.onExpandChanged,
    this.duration = const Duration(milliseconds: 300),
    this.initialExpand,
    this.prioritizeInitExpand = false
  });

  @override
  State<ExpandedHeader> createState() => _ExpandedHeaderState();
}

class _ExpandedHeaderState extends State<ExpandedHeader> with SingleTickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> animation;
  ValueNotifier<bool> expandedNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    if(widget.initialExpand != null) expandedNotifier.value = widget.initialExpand!;

    prepareAnimations();
    _runExpandCheck();
  }

  ///Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(
        vsync: this,
        duration: widget.duration
    );
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _runExpandCheck() {
    if(expandedNotifier.value == true) {
      expandController.forward().then((v) => widget.onExpandChanged?.call(expandedNotifier.value));
    }
    else {
      expandController.reverse().then((v) => widget.onExpandChanged?.call(expandedNotifier.value));
    }
  }

  @override
  void didUpdateWidget(ExpandedHeader oldWidget) {
    if(widget.prioritizeInitExpand) {
      expandedNotifier.value = widget.initialExpand ?? false;
      _runExpandCheck();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: expandedNotifier,
        builder: (context, value, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(widget.headerBuilder != null)
              widget.headerBuilder!.call(value, ({value}) => setExpandValue(currentValue: value)),
            SizeTransition(
                axisAlignment: 1.0,
                sizeFactor: animation,
                child: widget.expandedBuilder(context)
            ),
            if(widget.footerBuilder != null)
              widget.footerBuilder!.call(value, ({value}) => setExpandValue(currentValue: value)),
          ],
        )
    );
  }

  void setExpandValue({bool? currentValue}){
    expandedNotifier.value = currentValue ?? !expandedNotifier.value;
    _runExpandCheck();
  }
}