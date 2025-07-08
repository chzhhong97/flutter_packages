import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class RawData{
  final Map<String, dynamic> _data;
  Map<String, dynamic> get rawData => _data;
  final Map<String, dynamic> _cahces = {};

  RawData({
    Map<String, dynamic> data = const {},
  }) : _data = data;

  bool containsKey(String key) => _data.containsKey(key);
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  Map<K, V> getMap<K, V>(String key){
    if(_cahces.containsKey(key) && _cahces[key] is Map<K, V>) return _cahces[key] as Map<K, V>;

    try{
      if(_data.containsKey(key)){
        if(_data[key] is Map<String, dynamic>){
          final value = (_data[key] as Map<String, dynamic>).map((k, v) => MapEntry(k as K, v as V));
          _cahces[key] = value;
          return value;
        }
      }
    }
    catch(e){
      debugPrint("RawDataException: $e");
    }

    return {};
  }

  List<T> getList<T>(String key){
    if(_cahces.containsKey(key) && _cahces[key] is List<T>) return _cahces[key] as List<T>;

    try{
      if(_data.containsKey(key)){
        if(_data[key] is List<dynamic>){
          final value = (_data[key] as List<dynamic>).map((e) => e as T).toList();
          _cahces[key] = value;
          return value;
        }
      }
    }
    catch(e){
      debugPrint("RawDataException: $e");
    }


    return [];
  }

  T? getData<T>(String key){
    if(_cahces.containsKey(key)) return _cahces[key] as T;

    dynamic value;
    if(_data.containsKey(key)){
      if(_data[key] is num){
        if(T == int) value = (_data[key] as num).toInt() as T;
        if(T == double) value = (_data[key] as num).toDouble() as T;
      }
      if(_data[key] is String){
        if(T == int) value = int.tryParse(_data[key]) as T;
        if(T == double) value = double.tryParse(_data[key]) as T;
      }

      if(_data[key] is T) value = _data[key] as T;
    }

    if(value != null) _cahces[key] = value;

    return value;
  }

  void setData(String key, dynamic value) {
    _data[key] = value;
    _cahces[key] = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RawData &&
              runtimeType == other.runtimeType &&
              const DeepCollectionEquality().equals(_data, other._data);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_data);

  factory RawData.fromJson(Map<String, dynamic> json) => RawData(data: json);
  Map<String, dynamic> toJson() => rawData;
}