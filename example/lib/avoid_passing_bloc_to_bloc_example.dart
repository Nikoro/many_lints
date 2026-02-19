import 'package:bloc/bloc.dart';

// avoid_passing_bloc_to_bloc
//
// Blocs/Cubits should not depend on other Blocs/Cubits directly.
// State changes should flow through the presentation layer or
// be pushed down into the domain layer (repositories).

abstract class CounterEvent {}

class Increment extends CounterEvent {}

abstract class TimerEvent {}

class TimerStarted extends TimerEvent {}

// ❌ Bad: Bloc depends on another Bloc
class TimerBloc extends Bloc<TimerEvent, int> {
  // LINT: Passing a Bloc to another Bloc creates tight coupling
  final CounterBloc counterBloc;

  TimerBloc(this.counterBloc) : super(0);
}

// ❌ Bad: Cubit depends on a Bloc
class SummaryCubit extends Cubit<int> {
  // LINT: Passing a Bloc to a Cubit creates tight coupling
  final CounterBloc counterBloc;

  SummaryCubit(this.counterBloc) : super(0);
}

// ❌ Bad: Bloc depends on a Cubit
class AnalyticsBloc extends Bloc<TimerEvent, int> {
  // LINT: Passing a Cubit to a Bloc creates tight coupling
  final SummaryCubit summaryCubit;

  AnalyticsBloc(this.summaryCubit) : super(0);
}

// ✅ Good: Bloc depends on a repository instead
class CounterRepository {
  int getValue() => 0;
}

class CounterBloc extends Bloc<CounterEvent, int> {
  final CounterRepository repository;

  CounterBloc(this.repository) : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// ✅ Good: Bloc with no external Bloc dependencies
class IndependentBloc extends Bloc<TimerEvent, int> {
  IndependentBloc() : super(0);
}
