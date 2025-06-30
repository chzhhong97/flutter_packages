import "dart:async" show Completer;
import "dart:collection" show Queue;

abstract class BlockingStack<T>{
  factory BlockingStack() = _BlockingStack;

  int get length;
  bool get isNotEmpty;
  bool get isEmpty;
  Future<T> removeNext();
  T removeLast();
  void add(T value);
  bool remove(T value);
  void removeWhere(bool Function(T element) test);
}

class _BlockingStack<T> implements BlockingStack<T>{
  final Queue<T> _writes = Queue();
  final Queue<Completer<T>> _reads = Queue();

  @override
  int get length => _writes.length;

  @override
  bool get isNotEmpty => _writes.isNotEmpty;

  @override
  bool get isEmpty => _writes.isEmpty;
  
  @override
  void removeWhere(bool Function(T element) test) {
    _writes.removeWhere(test);
  }

  @override
  bool remove(T value) {
    return _writes.remove(value);
  }
  
  @override
  T removeLast() {
    return _writes.removeLast();
  }

  @override
  Future<T> removeNext(){
    if(_writes.isNotEmpty) return Future.value(_writes.removeLast());
    var completer = Completer<T>();
    _reads.add(completer);
    return completer.future;
  }

  @override
  void add(T value){
    if(_reads.isNotEmpty){
      _reads.removeFirst().complete(value);
    }
    else{
      _writes.add(value);
    }
  }

  @override
  String toString(){
    return _writes.toList().join(",");
  }
}