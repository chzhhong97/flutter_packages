import 'dart:async';

class CoroutineWithResult<T> {
  final FutureOr<void> Function(CoroutineWithResult<T> coroutine, int retries) _process;

  /// Process will only start when [awaitResult] called
  CoroutineWithResult({
    required FutureOr<void> Function(CoroutineWithResult<T> coroutine, int retries) process,
  }) : _process = process;
  final Completer<T?> _completer = Completer();

  Future<T?> get awaitResult async {
    _run();
    return _completer.future;
  }

  void resolvedWith(T? result) => _completer.complete(result);

  Future<void> _run() async {
    try {
      int count = 0;
      while (true) {
        await _process(this, count);

        if(_completer.isCompleted){
          return;
        }

        count++;
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}