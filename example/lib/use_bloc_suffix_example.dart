import 'package:bloc/bloc.dart';

// use_bloc_suffix
//
// Classes extending Bloc should have the 'Bloc' suffix.

abstract class CounterEvent {}

class Increment extends CounterEvent {}

// LINT: Missing 'Bloc' suffix
class CounterManager extends Bloc<CounterEvent, int> {
  CounterManager() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
