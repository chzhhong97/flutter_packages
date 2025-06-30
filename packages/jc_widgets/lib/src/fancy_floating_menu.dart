import 'dart:async';
import 'package:flutter/material.dart';

class FancyFloatingMenu extends StatefulWidget{

  final Widget Function(BuildContext, Function(bool)? setSpawn, bool isSpawn) bodyBuilder;
  final Animation? menuAnimation;
  final Widget Function(BuildContext, Animation<Offset>, FancyFloatingMenuController controller) menuBuilder;
  final Duration? autoDismissDuration;
  final Function(dynamic value)? onDismiss;
  final FancyFloatingMenuController? controller;
  const FancyFloatingMenu({
    super.key,
    this.controller,
    required this.bodyBuilder,
    this.menuAnimation,
    required this.menuBuilder,
    this.autoDismissDuration,
    this.onDismiss,
  });
  @override
  State<StatefulWidget> createState() => _FancyFloatingMenu();
}

class _FancyFloatingMenu extends State<FancyFloatingMenu> with SingleTickerProviderStateMixin implements FancyFloatingMenuInterface{

  late AnimationController _animationController;
  late Animation _defaultAnimation;
  bool onSpawnFloating = false;
  Timer? autoDismissTimer;

  FancyFloatingMenuController controller = FancyFloatingMenuController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _defaultAnimation = widget.menuAnimation ?? Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceInOut,
    ));

    controller.attached(this);
    if(widget.controller != null){
      widget.controller?.attached(this);
    }
  }

  @override
  void didUpdateWidget(covariant FancyFloatingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(widget.controller != oldWidget.controller){
      oldWidget.controller?.detached();
      if(widget.controller != null){
        widget.controller?.attached(this);
      }
    }
  }


  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.bodyBuilder(context, setMenuSpawning, onSpawnFloating),
      if(onSpawnFloating)
      Positioned.fill(
          child: InkWell(
            onTap: () => setMenuSpawning(!onSpawnFloating),
            child: Container(
              color: Colors.white.withOpacity(.8),
              child: widget.menuBuilder(context, _defaultAnimation as Animation<Offset>, widget.controller ?? controller),
            ),
          )
      ),
      if(onSpawnFloating)
      Positioned.fill(
          child: GestureDetector(
            onPanUpdate: (_) => startTimer(),
            onTap: () => startTimer(),
            child: widget.menuBuilder(context, _defaultAnimation as Animation<Offset>, widget.controller ?? controller),
          )
      ),
    ],
  );


  @override
  void dispose() {
    widget.controller?.detached();
    controller.detached();

    _animationController.dispose();
    autoDismissTimer?.cancel();
    super.dispose();
  }

  void setMenuSpawning(bool spawn){
    if (spawn) {
      setState(() {
        onSpawnFloating = spawn;
        _animationController.forward();
        startTimer();
      });
    } else {
      _animationController.reverse().then((v){
        if(context.mounted){
          setState(() {
            onSpawnFloating = spawn;
          });
        }
        widget.onDismiss?.call(widget.controller?.value ?? controller.value);

        //reset
        widget.controller?.value = null;
        controller.value = null;
      });
      if(widget.autoDismissDuration != null) autoDismissTimer?.cancel();
    }
    /*setState(() {
      if (spawn) {
        _animationController.forward();
        startAutoDismissTimer();
      } else {
        _animationController.reverse();
        if(widget.autoDismissDuration != null) autoDismissTimer?.cancel();
      }
      onSpawnFloating = spawn;
    });*/
  }

  @override
  void dismissMenu() {
    if (onSpawnFloating) {
      setMenuSpawning(false);
    }
  }

  @override
  void startTimer() {
    if(widget.autoDismissDuration != null) {
      stopTimer(); // Cancel any existing timer
      autoDismissTimer = Timer(widget.autoDismissDuration!, () {
        if (onSpawnFloating) {
          setMenuSpawning(false);
        }
      });
    }
  }

  @override
  void stopTimer() {
    autoDismissTimer?.cancel();
  }

}

class FancyFloatingMenuController{
  FancyFloatingMenuInterface? _interface;
  dynamic value;

  void attached(FancyFloatingMenuInterface floatingMenu) {
    detached();
    _interface = floatingMenu;
  }

  void detached(){
    _interface = null;
  }

  void startTimer() => _interface?.startTimer();
  void stopTimer() => _interface?.stopTimer();
  void dismissMenu() => _interface?.dismissMenu();
  void setValue(dynamic value) => this.value = value;
}

interface class FancyFloatingMenuInterface{
  void startTimer(){}
  void stopTimer(){}
  void dismissMenu(){}
}