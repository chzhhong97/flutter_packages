import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

/// The [delayEvent] transformer is pausing adding events for a particular
/// increment of time (that you specify) before emitting each of the events.
///
/// This has the effect of shifting the entire sequence of events added to the
/// bloc forward in time by that specified increment.
EventTransformer<Event> delayEvent<Event>(Duration duration) =>
    (events, mapper) => events.delay(duration).switchMap(mapper);
