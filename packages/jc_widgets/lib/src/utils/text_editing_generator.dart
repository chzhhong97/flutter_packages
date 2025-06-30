import 'package:flutter/material.dart';

class TextEditingGenerator{
  final Map<String, TextEditingController> _entries = {};
  final Map<String, bool> _enables = {};

  /// The [entries] should provide tag and text
  ///
  /// Example: MapEntry('tag', 'hello')
  void generateController(List<MapEntry<String, String?>> entries, {bool reassign = false}){
    for (var e in entries) {
      assignController(e.key, text: e.value, reassign: reassign);
    }
  }

  TextEditingController assignController(String tag, {String? text, bool reassign = false, bool enable = true}){
    if(_entries.containsKey(tag) && !reassign) return _entries[tag]!;

    final controller = TextEditingController(text: text);
    _entries.update(tag, (v){
      v.dispose();
      return controller;
    }, ifAbsent: () => controller);

    setEnabled(tag, enable: enable);

    return controller;
  }

  TextEditingController? getController(String tag){
    return _entries[tag];
  }

  bool isEnabled(String tag){
    return _enables[tag] ?? true;
  }

  void setBatchEnabled(Set<String> tags, {bool enable = true}){
    for (var tag in tags) {
      setEnabled(tag, enable: enable);
    }
  }

  void setEnabled(String tag, {bool enable = true}){
    _enables.update(tag, (v){
      return enable;
    }, ifAbsent: () => enable);
  }

  void resetEnabled(){
    for (var e in _enables.keys) {
      _enables[e] = true;
    }
  }

  void clearAllText(){
    for (var e in _entries.values) {
      e.clear();
    }
  }

  void clearText(Set<String> tags){
    for (var tag in tags) {
      _entries[tag]?.clear();
    }
  }

  void dispose(){
    for (var e in _entries.values) {
      e.dispose();
    }
    _entries.clear();
  }
}