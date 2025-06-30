import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';


/// The [debounceSequential] transformer allows us to delay the processing of events until a
/// specific period has passed without any new events
///
/// It also process events one at a time by maintaining a queue of added events
/// and processing the events sequentially.
EventTransformer<E> debounceSequential<E>(Duration duration) {
  return (events, mapper) {
    return sequential<E>().call(events.debounceTime(duration), mapper);
  };
}