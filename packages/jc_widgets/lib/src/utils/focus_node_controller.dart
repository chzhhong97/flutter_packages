import 'package:flutter/material.dart';

class FocusNodeController{
  final Map<String, FocusNode> _entries = {};

  FocusNode assignNode(String tag, {bool reassign = false}){
    if(_entries.containsKey(tag) && !reassign) return _entries[tag]!;

    final node = FocusNode();
    _entries.update(tag, (v){
      v.dispose();
      return node;
    }, ifAbsent: () => node);

    return node;
  }

  FocusNode? getNode(String tag){
    return _entries[tag];
  }

  void dispose(){
    for (var e in _entries.values) {
      e.dispose();
    }
    _entries.clear();
  }
}