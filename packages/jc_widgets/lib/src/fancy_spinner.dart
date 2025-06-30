import 'package:flutter/material.dart';

class FancySpinner<T> extends StatefulWidget {
  final List<T> selections;
  final T? currentSelection;
  final double listItemHeight;
  final TextStyle? defaultSelectTextStyle;
  final TextStyle? defaultUnselectTextStyle;
  final Widget? Function()? focusedWheelBuilder;
  final Widget Function(T, bool)? itemBuilder;
  final Function(T?)? onFocusItem;
  final String Function(T)? onMapSelectionLabel;
  final int visibleItemLength;
  final double magnification;

  @override
  State<StatefulWidget> createState() => _FancySpinnerState<T>();

  const FancySpinner(
      {super.key, required this.selections,
        this.currentSelection,
      this.itemBuilder,
      this.listItemHeight = 40,
      this.defaultSelectTextStyle,
      this.defaultUnselectTextStyle,
      this.focusedWheelBuilder,
      this.visibleItemLength = 5,
      this.onFocusItem,
        this.onMapSelectionLabel,
        this.magnification = 1.5,
      });
}

class _FancySpinnerState<T> extends State<FancySpinner<T>> {
  double listHeight = 1;
  double listItemHeight = 40;
  final listItemKey = GlobalKey();
  T? currentSelection;
  final _controller = FixedExtentScrollController();


  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
              child: Center(
            child: SizedBox(
              height: listItemHeight,
              child: widget.focusedWheelBuilder?.call() ??
                  Container(
                    color: Theme.of(context).primaryColor.withOpacity(.2),
                  ),
            ),
          )),
          SizedBox(
            height: listHeight,
            child: ListWheelScrollView(
              useMagnifier: true,
              diameterRatio: 1,
              magnification: widget.magnification,
              controller: _controller,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  currentSelection = widget.selections[index];
                });
                widget.onFocusItem?.call(currentSelection);
              },
              itemExtent: listItemHeight,
              children: widget.selections.map((e) {
                bool selected = e == currentSelection;

                return SizedBox(
                  key: e == widget.selections.first ? listItemKey : null,
                  height: listItemHeight,
                  child: Center(
                    child: widget.itemBuilder?.call(e, selected) ??
                        Text(
                            widget.onMapSelectionLabel?.call(e) ?? e.toString(),
                            style: selected
                                ? widget.defaultSelectTextStyle ??
                                    const TextStyle(color: Colors.black)
                                : widget.defaultUnselectTextStyle ??
                                    const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async  {
      currentSelection = widget.currentSelection ?? widget.selections.first;
      final renderBox =
          listItemKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        updateListSize(renderBox.size.height);
        await autoScrollToDefaultSelection();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FancySpinner<T> oldWidget) {
    if(oldWidget.currentSelection != widget.currentSelection){
      currentSelection = widget.currentSelection ?? widget.selections.first;
      WidgetsBinding.instance.addPostFrameCallback((timestamp) async{
        await autoScrollToDefaultSelection();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  void updateListSize(double listItemSize) {
    setState(() {
      listHeight = listItemHeight * widget.visibleItemLength;
    });
  }

  Future autoScrollToDefaultSelection() async {
    int defaultIndex = 0;

    for(int i = 0; i < widget.selections.length; i++){
      if(widget.selections[i] == currentSelection) {
        defaultIndex = i;
        widget.onFocusItem?.call((widget.selections[i]));
        break;
      }
    }

    await _controller.animateTo(
        listItemHeight * defaultIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn
    );
  }

}
