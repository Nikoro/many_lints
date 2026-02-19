// ignore_for_file: unused_local_variable

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

// prefer_immutable_bloc_state
//
// Bloc state classes should be annotated with @immutable to ensure
// that emit always receives a newly created state object.

abstract class CounterEvent {}

// ❌ Bad: State classes without @immutable annotation

// LINT: Missing @immutable on sealed state class
sealed class BadCounterState {}

// LINT: Missing @immutable on state subclass
class BadCounterInitial extends BadCounterState {}

// LINT: Missing @immutable on state subclass
class BadCounterLoaded extends BadCounterState {
  final int count;
  BadCounterLoaded(this.count);
}

class BadCounterBloc extends Bloc<CounterEvent, BadCounterState> {
  BadCounterBloc() : super(BadCounterInitial());
}

// ✅ Good: State classes annotated with @immutable

@immutable
sealed class GoodCounterState {}

@immutable
class GoodCounterInitial extends GoodCounterState {}

@immutable
class GoodCounterLoaded extends GoodCounterState {
  final int count;
  GoodCounterLoaded(this.count);
}

class GoodCounterBloc extends Bloc<CounterEvent, GoodCounterState> {
  GoodCounterBloc() : super(GoodCounterInitial());
}

// ✅ Good: Cubit with immutable state
@immutable
sealed class TimerState {}

@immutable
class TimerInitial extends TimerState {}

class TimerCubit extends Cubit<TimerState> {
  TimerCubit() : super(TimerInitial());
}
