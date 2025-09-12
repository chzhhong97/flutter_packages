import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jc_utils/jc_utils.dart';

typedef DialogBuilder = Widget Function(BuildContext context, void Function([dynamic]) popDialog, void Function(SnackBar snackBar) showSnackBar);

class CustomDialog{
  CustomDialog._();
  static const Color primaryColor = Colors.blue;
  static const DialogSettings defaultSettings = DialogSettings();
  static final Queue<Completer<BuildContext>> _contextQueue = Queue();
  static final SimpleSequenceTaskManager _sequenceHideTask = SimpleSequenceTaskManager();
  static GlobalKey<NavigatorState>? _globalKey;
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  static void setKey(GlobalKey<NavigatorState> globalKey){
    _globalKey = globalKey;
  }

  static void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey){
    _scaffoldMessengerKey = scaffoldMessengerKey;
  }

  static ScaffoldMessengerState? get scaffoldMessenger => _scaffoldMessengerKey?.currentState;

  static Future showLoadingDialog({
    String label = 'Loading...',
    BuildContext? context,
    bool fullScreen = false,
    Color? background,
    DialogBuilder? builder,
  }){
    return show(
      context: context,
      settings: DialogSettings(
          canPop: false,
          barrierDismissible: false,
          fullScreen: fullScreen,
          contentAlignment: Alignment.center,
          backgroundColor: background,
          builder: (context, pop, snack){
            return builder?.call(context, pop, snack) ?? CustomDialog.defaultLoadingDialog(context, label: label);
          }
      )
    );
  }

  static Future showFullScreenDialog({DialogSettings settings = defaultSettings, BuildContext? context}){
    return show(
        context: context,
        settings: settings.copyWith(
          fullScreen: true,
        ),
    );
  }

  static Future show({DialogSettings settings = defaultSettings, BuildContext? context}) async {
    if(_globalKey?.currentContext == null && context == null){
      print('Unable to show dialog without context');
      return;
    }

    Completer<BuildContext> completer = Completer();
    if(settings.addToQueue) {
      _contextQueue.add(completer);
      _debugLog("Add completer to queue, len: ${_contextQueue.length}");
    }

    completer.future.then((context){
      settings.startDismissOperation(onDone: (){
        if(context.mounted){
          Navigator.of(context).pop(false);
        }
      });
    });

    final result = await showDialog(
        context: context ?? _globalKey!.currentContext!,
        barrierDismissible: settings.barrierDismissible,
        barrierColor: settings.barrierColor,
        builder: (c){
          WidgetsBinding.instance.addPostFrameCallback((d){
            if(!_contextQueue.contains(completer) && settings.addToQueue) return;
            _debugLog("Complete completer with context, mounted: ${c.mounted}");
            if(!completer.isCompleted) completer.complete(c);
          });
          return _buildDialog(
              c,
              settings.builder == null && settings.completeBuilder == null ? settings.copyWith(canPop: false) : settings,
            onPop: () {
              _contextQueue.remove(completer);
              _debugLog(
                  "Remove completer from queue, len: ${_contextQueue.length}");
            }
          );
        }
    );

    if(settings.onDismiss != null) await Future.delayed(const Duration(milliseconds: 100), () => settings.onDismiss?.call());

    return result;
  }

  static Future<void> hide({bool absolute = false}) async {
    _debugLog("Register hide task");
    return _sequenceHideTask.register(Future(() async => _hide(absolute: absolute))).future;
  }

  static Future<void> _hide({bool absolute = false, bool sync = false}) async {
    _debugLog("Start hide task, len: ${_contextQueue.length}");
    if(absolute){
      final List<Completer<BuildContext>> toKeep = [];
      for(var item in _contextQueue){
        if(item.isCompleted){
          final context = await item.future;
          if(!context.mounted) continue;
        }
        toKeep.add(item);
      }
      _contextQueue.clear();
      _contextQueue.addAll(toKeep);
    }

    if(_contextQueue.isEmpty) return;
    final completedQueue = sync ? _contextQueue.where((e) => e.isCompleted) : <Completer<BuildContext>>[];

    if(sync && completedQueue.isEmpty) return;

    final completer = sync ? completedQueue.first : _contextQueue.removeFirst();

    if(sync) _contextQueue.remove(completer);

    _debugLog("Await completer context");
    final context = await completer.future;
    _debugLog("Get context from completer, mounted: ${context.mounted}");
    if(context.mounted){
      Navigator.of(context).pop(false);
    }
  }

  static void hideAllSync() {
    hideAll();
  }

  static Future<void> hideAll() {
    return Future.doWhile(() async {
      if(_contextQueue.isEmpty) return false;
      await hide();
      return true;
    });
  }

  static Widget _buildDialog(BuildContext context, DialogSettings settings, {void Function()? onPop}){
    final bottomButton = settings.actions != null || settings.positiveButton.isNotEmpty || settings.negativeButton.isNotEmpty;
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    return Stack(
      children: [
        IgnorePointer(
          child: ScaffoldMessenger(
            key: scaffoldMessengerKey,
            child: const Scaffold(
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(settings.borderRadius)
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: settings.fullScreen ? EdgeInsets.zero : settings.insetPadding,
          alignment: settings.dialogAlignment,
          child: PopScope(
            canPop: settings.canPop,
            onPopInvoked: (didPop) {
              if(settings.onBackPressed != null) settings.onBackPressed!(didPop);
              if(didPop) onPop?.call();
            },
            child: settings.completeBuilder?.call(
                context, ([value]){
              if(context.mounted){
                Navigator.of(context).pop(value);
              }
            }, (snackBar) => scaffoldMessengerKey.currentState?.showSnackBar(snackBar)
            ) ?? Stack(
              alignment: settings.fullScreen ? AlignmentDirectional.topStart : settings.contentAlignment,
              children: [
                Container(
                  margin: EdgeInsets.only(top: settings.topIconPosition.top),
                  padding: EdgeInsets.only(top: settings.topIconPosition.top),
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: settings.backgroundColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(settings.borderRadius),
                      boxShadow: settings.backgroundColor == null ? const [
                        BoxShadow(color: Colors.black26,offset: Offset(0,5),
                            blurRadius: 5
                        ),
                      ] : null
                  ),
                  alignment: settings.fullScreen ? settings.contentAlignment : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: settings.stretchCrossAxis ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                            padding: settings.contentPadding,
                            child: settings.builder != null ?
                            settings.builder!(context, ([value]){
                              if(context.mounted){
                                Navigator.of(context).pop(value);
                              }
                            }, (snackBar) => scaffoldMessengerKey.currentState?.showSnackBar(snackBar)) :
                            defaultLoadingDialog(context)
                        ),
                      ),
                      Visibility(
                        visible: bottomButton,
                        child: Padding(
                          padding: settings.buttonPadding,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: settings.actions != null ?
                            settings.actions!(context):
                            [
                              if(settings.negativeButton.isNotEmpty)
                                DialogSettings.defaultTextButton(
                                    context: context,
                                    buttonText: settings.negativeButton,
                                    textStyle: const TextStyle(color: Colors.red),
                                    onPressed: (context){
                                      if(context.mounted){
                                        Navigator.of(context).pop(false);
                                      }
                                    }
                                ),
                              if(settings.negativeButton.isNotEmpty && settings.positiveButton.isNotEmpty)
                                const SizedBox(width: 10,),
                              if(settings.positiveButton.isNotEmpty)
                                DialogSettings.defaultTextButton(
                                    context: context,
                                    buttonText: settings.positiveButton,
                                    textStyle: const TextStyle(color: primaryColor),
                                    onPressed: (context){
                                      if(context.mounted){
                                        Navigator.of(context).pop(true);
                                      }
                                    }
                                )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                if(settings.topIcon != null)
                  Positioned(
                      left: settings.topIconPosition.left,
                      right: settings.topIconPosition.right,
                      child: settings.topIcon!(context)
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget defaultLoadingDialog(BuildContext context, {String label = 'Loading...', TextStyle? style}){
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(label, style: style ?? const TextStyle(fontSize: 14),),
          const SizedBox(height: 10,),
          CircularProgressIndicator(color: Theme.of(context).primaryColor,),
        ],
      ),
    );
  }

  static _debugLog(Object object) {
    if (kDebugMode) debugPrint("CustomDialogLog: $object");
  }
}

class DialogSettings{
  final Duration duration;
  ///Operation to done before dismiss, will ignore duration when this is provided
  final List<Future Function()> dismissOperation;
  final VoidCallback? onDismiss;
  final DialogBuilder? builder;
  final DialogBuilder? completeBuilder;
  final List<Widget> Function(BuildContext context)? actions;
  final Widget Function(BuildContext context)? topIcon;
  final String positiveButton;
  final String negativeButton;
  final bool barrierDismissible;
  final bool Function(bool didPop)? onBackPressed;
  final bool canPop;
  final double borderRadius;
  final EdgeInsets insetPadding;
  final EdgeInsets contentPadding;
  final EdgeInsets buttonPadding;
  final bool addToQueue;
  final EdgeInsets topIconPosition;
  final Color? backgroundColor;
  final Color? barrierColor;
  final AlignmentGeometry? dialogAlignment;
  final AlignmentGeometry contentAlignment;
  final bool stretchCrossAxis;
  final bool fullScreen;


  const DialogSettings({
    this.duration = Duration.zero,
    this.dismissOperation = const [],
    this.onDismiss,
    this.builder,
    this.completeBuilder,
    this.actions,
    this.topIcon,
    this.positiveButton = "",
    this.negativeButton = "",
    this.barrierDismissible = false,
    this.onBackPressed,
    this.canPop = true,
    this.borderRadius = 20,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
    this.contentPadding = EdgeInsets.zero,
    this.buttonPadding = const EdgeInsets.all(10),
    this.topIconPosition = EdgeInsets.zero,
    this.addToQueue = true,
    this.backgroundColor,
    this.barrierColor,
    this.dialogAlignment,
    this.contentAlignment = AlignmentDirectional.topStart,
    this.stretchCrossAxis = true,
    this.fullScreen = false,
  });

  static Widget defaultTextButton({
    required BuildContext context,
    required String buttonText,
    TextStyle textStyle = const TextStyle(color: Colors.black),
    TextAlign align = TextAlign.center,
    Function(BuildContext context)? onPressed
  }){
    return TextButton(
        onPressed: () => onPressed?.call(context),
        child: Text(buttonText, style: textStyle, textAlign: align, maxLines: 2,)
    );
  }

  static Widget defaultElevatedButton({
    required BuildContext context,
    required String buttonText,
    EdgeInsets contentPadding = EdgeInsets.zero,
    Widget? leading,
    Widget? trailing,
    Color? backgroundColor,
    double borderRadius = 12,
    double iconSpacing = 0,
    TextStyle textStyle = const TextStyle(),
    TextAlign align = TextAlign.center,
    Function(BuildContext context)? onPressed
  }){
    return ElevatedButton(
        onPressed: () => onPressed?.call(context),
        child: Container(
          padding: contentPadding,
          decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius)
          ),
          child: Row(
            children: [
              if(leading != null) leading,
              Padding(
                padding: EdgeInsets.only(
                  left: leading != null ? iconSpacing : 0,
                  right: trailing != null ? iconSpacing : 0,
                ),
                child: Text(buttonText, style: textStyle, textAlign: align, maxLines: 2,),
              ),
              if(trailing != null) trailing,
            ],
          ),
        )
    );
  }

  void startDismissOperation({Function()? onDone}) async {
    if(dismissOperation.isEmpty && duration == Duration.zero) return;

    if(dismissOperation.isNotEmpty){
      await Future.forEach(dismissOperation, (a) => a());
    }
    else{
      await Future.delayed(duration);
    }

    onDone?.call();
  }

  DialogSettings copyWith({
    Duration? duration,
    List<Future Function()>? dismissOperation,
    VoidCallback? onDismiss,
    DialogBuilder? builder,
    DialogBuilder? completeBuilder,
    List<Widget> Function(BuildContext context)? actions,
    Widget Function(BuildContext context)? topIcon,
    String? positiveButton,
    String? negativeButton,
    bool? barrierDismissible,
    bool Function(bool didPop)? onBackPressed,
    bool? canPop,
    double? borderRadius,
    EdgeInsets? insetPadding,
    EdgeInsets? contentPadding,
    EdgeInsets? buttonPadding,
    bool? addToQueue,
    EdgeInsets? topIconPosition,
    Color? backgroundColor,
    Color? barrierColor,
    AlignmentGeometry? dialogAlignment,
    AlignmentGeometry? contentAlignment,
    bool? stretchCrossAxis,
    bool? fullScreen,
  }) {
    return DialogSettings(
      duration: duration ?? this.duration,
      dismissOperation: dismissOperation ?? this.dismissOperation,
      onDismiss: onDismiss ?? this.onDismiss,
      builder: builder ?? this.builder,
      completeBuilder: completeBuilder ?? this.completeBuilder,
      actions: actions ?? this.actions,
      topIcon: topIcon ?? this.topIcon,
      positiveButton: positiveButton ?? this.positiveButton,
      negativeButton: negativeButton ?? this.negativeButton,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      onBackPressed: onBackPressed ?? this.onBackPressed,
      canPop: canPop ?? this.canPop,
      borderRadius: borderRadius ?? this.borderRadius,
      insetPadding: insetPadding ?? this.insetPadding,
      contentPadding: contentPadding ?? this.contentPadding,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      addToQueue: addToQueue ?? this.addToQueue,
      topIconPosition: topIconPosition ?? this.topIconPosition,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      barrierColor: barrierColor ?? this.barrierColor,
      dialogAlignment: dialogAlignment ?? this.dialogAlignment,
      contentAlignment: contentAlignment ?? this.contentAlignment,
      stretchCrossAxis: stretchCrossAxis ?? this.stretchCrossAxis,
      fullScreen: fullScreen ?? this.fullScreen,
    );
  }
}