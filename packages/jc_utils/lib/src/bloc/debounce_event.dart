import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

/// The [debounceEvent] transformer allows us to delay the processing of events until a specific period has passed without any new events
EventTransformer<Event> debounceEvent<Event>({Duration duration = const Duration(milliseconds: 300)}) {
  return (events, mapper) =>
      events.debounceTime(duration).switchMap(mapper);
}