// ignore_for_file: unused_element, unused_local_variable
// ignore_for_file: many_lints/prefer_immutable_bloc_state, many_lints/emit_new_bloc_state_instances

// handle_bloc_event_subclasses
//
// Warns when a Bloc leaves a subclass of its sealed event type without an
// on<E> handler. Registration is a runtime lookup, so adding an unregistered
// event does nothing at all — no state change, no error, no log.

import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

// ❌ Bad: `Decrement` has no handler
// LINT: adding a Decrement event silently does nothing
class BadCounterBloc extends Bloc<CounterEvent, int> {
  BadCounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// ✅ Good: every subclass is registered
class GoodCounterBloc extends Bloc<CounterEvent, int> {
  GoodCounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}

// ✅ Good: a handler for the base type covers every subclass
class BaseHandlerBloc extends Bloc<CounterEvent, int> {
  BaseHandlerBloc() : super(0) {
    on<CounterEvent>((event, emit) => emit(state));
  }
}

// ✅ Edge case: an open (non-sealed) hierarchy has no knowable subtype set
class OpenEvent {}

class OpenIncrement extends OpenEvent {}

class OpenBloc extends Bloc<OpenEvent, int> {
  OpenBloc() : super(0) {
    on<OpenIncrement>((event, emit) => emit(state + 1));
  }
}
