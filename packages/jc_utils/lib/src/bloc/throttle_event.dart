import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

/// The [throttleEvent] transformer helps manage the rate of function invocations by
/// ensuring that the function is only triggered after a specified duration of
/// inactivity.
EventTransformer<Event> throttleEvent<Event>({
  Duration duration = const Duration(milliseconds: 300),
  bool trailing = false,
  bool leading = true,
}) {
  return (events, mapper) =>
      events.throttleTime(duration, trailing: trailing, leading: leading).switchMap(mapper);
}