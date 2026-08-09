// ignore_for_file: unused_element
// These blocs deliberately register only some events, to keep the duplicate
// registration the single point of the file.
// ignore_for_file: many_lints/handle_bloc_event_subclasses

// avoid_duplicate_bloc_event_handlers
//
// Warns when the same event type is registered with Bloc.on more than once.
// Bloc allows one handler per event type and throws a StateError on the
// second registration, at construction time.

import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class IncrementEvent extends CounterEvent {}

class DecrementEvent extends CounterEvent {}

// ❌ Bad: the same event registered twice
class _BadBloc extends Bloc<CounterEvent, int> {
  _BadBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    // LINT: throws at construction — the type argument was never updated
    on<IncrementEvent>((event, emit) => emit(state - 1));
  }
}

// ✅ Good: one handler per event type
class _GoodBloc extends Bloc<CounterEvent, int> {
  _GoodBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    on<DecrementEvent>((event, emit) => emit(state - 1));
  }
}

// ✅ Good: merge the behaviours into one handler
class _GoodMergedBloc extends Bloc<CounterEvent, int> {
  _GoodMergedBloc() : super(0) {
    on<IncrementEvent>((event, emit) {
      emit(state + 1);
      _logIncrement();
    });
  }

  void _logIncrement() {}
}

// ✅ Edge case: two constructors may each register the same event, since
// only one of them runs for any given instance
class _GoodTwoConstructorsBloc extends Bloc<CounterEvent, int> {
  _GoodTwoConstructorsBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
  }

  _GoodTwoConstructorsBloc.stepsOfTen() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 10));
  }
}
