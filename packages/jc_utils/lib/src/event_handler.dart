import 'package:flutter/cupertino.dart';

abstract class EventHandlerList<T extends Function>{
  @protected
  final List<T> handlers = [];

  void operator +(T handler) => addHandler(handler);
  void operator -(T handler) => removeHandler(handler);
  
  bool hasHandler(T handler) => handlers.contains(handler);
  
  void addHandler(T handler) => handlers.add(handler);
  void removeHandler(T handler) => handlers.remove(handler);

  /// Due to dart limitation you have to implement [invoke] method manually
  ///
  /// Example:
  /// ```dart
  /// class MyEventHandler extends EventHandlerList<void Function(String)>{
  ///   @override
  ///   void Function(String p1) get invoke => _invoke;
  ///
  ///   void _invoke(String p1){
  ///     handlers.forEach((e) => e.call(p1));
  ///   }
  /// }
  /// ```
  ///
  /// [_invoke] method should call
  /// ```dart
  /// handlers.forEach((e) => e.call(p1));
  /// ```
  /// else the all the event will not invoke
  T get invoke;
}

final class VoidEventHandler extends EventHandlerList<void Function()>{
  @override
  void Function() get invoke => _invoke;

  void _invoke(){
    if(handlers.isEmpty) return;

    handlers.toList().forEach((e) => e.call());
  }
}

final class StringEventHandler extends EventHandlerList<void Function(String)>{
  @override
  void Function(String value) get invoke => _invoke;

  void _invoke(String value){
    if(handlers.isEmpty) return;

    handlers.toList().forEach((e) => e.call(value));
  }
}