import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GenericGridRadioGroup<T> extends StatefulWidget{
  const GenericGridRadioGroup({
    super.key,
    required this.items,
    required this.crossAxisCount,
    required this.areItemSame,
    this.onItemSelected,
    required this.builder,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.padding,
    this.scrollable = true,
    this.scrollDirection = Axis.vertical,
    this.initialValue,
    this.prioritizeInitial = false,
    this.disabledItems,
  });

  final List<T> items;
  final Widget Function(BuildContext buildContext, int index, T item, bool isSelected) builder;
  final bool Function(T a, T b) areItemSame;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets? padding;
  final bool scrollable;
  final Axis scrollDirection;
  final T? initialValue;
  final bool prioritizeInitial;
  final bool Function(T item)? disabledItems;
  final Function(T? value)? onItemSelected;


  @override
  State<GenericGridRadioGroup> createState() => _GenericGridRadioGroup<T>();
}

class _GenericGridRadioGroup<T> extends State<GenericGridRadioGroup<T>>{

  final ValueNotifier<int?> selectItem = ValueNotifier(null);

  @override
  void initState() {
    _updateValue();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GenericGridRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(widget.prioritizeInitial){
      _updateValue();
    }

  }

  void _updateValue(){
    if(widget.initialValue == null) {
      selectItem.value = null;
      return;
    }

    final index = widget.items.indexWhere((e) => widget.areItemSame(e, widget.initialValue as T));
    if(index != -1){
      selectItem.value = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlignedGridView.count(
      crossAxisSpacing: widget.crossAxisSpacing,
      mainAxisSpacing: widget.mainAxisSpacing,
      crossAxisCount: widget.crossAxisCount,
      padding: widget.padding,
      shrinkWrap: !widget.scrollable,
      physics: widget.scrollable ? null : const NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (context, index){
        return ValueListenableBuilder(
          valueListenable: selectItem,
          builder: (BuildContext context, int? value, Widget? child) {
            return InkWell(
              onTap: (widget.disabledItems?.call(widget.items[index]) ?? false) ? null : (){
                selectItem.value = index;
                widget.onItemSelected?.call(widget.items[index]);
              },
              child: widget.builder(context, index, widget.items[index], index == value),
            );
          },
        );
      }
    );
  }
}