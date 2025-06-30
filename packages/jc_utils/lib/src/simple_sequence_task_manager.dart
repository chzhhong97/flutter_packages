import 'dart:async';
import 'dart:collection';

class SimpleSequenceTaskManager{
  final Queue<Completer> _completerList = Queue();
  Completer? _completer;

  Future<void>? get future => _completer?.future;

  Completer register(Future<void> futureFunction){
    try{
      Completer completer = Completer();
      futureFunction.then((e) => completer.complete());

      _completerList.add(completer);
      return completer;
    }
    finally{
      _run();
    }
  }

  void _run() async {
    if(_completer != null) return;
    _completer = Completer();

    while(_completerList.isNotEmpty){
      final c = _completerList.removeFirst();
      await c.future;
    }

    _completer?.complete();
    _completer = null;
  }
}
