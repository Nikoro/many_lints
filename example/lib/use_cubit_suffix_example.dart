import 'package:bloc/bloc.dart';

// use_cubit_suffix
//
// Classes extending Cubit should have the 'Cubit' suffix.

// LINT: Missing 'Cubit' suffix
class Counter extends Cubit<int> {
  Counter() : super(0);

  void increment() => emit(state + 1);
}
