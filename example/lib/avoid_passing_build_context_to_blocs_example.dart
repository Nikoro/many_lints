// ignore_for_file: unused_element, unused_field

// avoid_passing_build_context_to_blocs
//
// Warns when a Bloc/Cubit class accepts a BuildContext parameter in its
// constructor or methods. Passing BuildContext creates unnecessary coupling
// between Blocs and widgets, and can introduce bugs when context is unmounted.

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

// ❌ Bad: Bloc constructor accepts BuildContext
class BadBloc extends Bloc<CounterEvent, int> {
  // LINT: Avoid passing BuildContext to a Bloc/Cubit
  final BuildContext context;

  BadBloc(this.context) : super(0);
}

// ❌ Bad: Cubit method accepts BuildContext
class BadCubit extends Cubit<int> {
  BadCubit() : super(0);

  // LINT: Avoid passing BuildContext to a Bloc/Cubit
  void doSomething(BuildContext context) {}
}

// ❌ Bad: Named constructor parameter with BuildContext
class AnotherBadBloc extends Bloc<CounterEvent, int> {
  // LINT: Avoid passing BuildContext to a Bloc/Cubit
  AnotherBadBloc({required BuildContext context}) : super(0);
}

// ✅ Good: Bloc with repository dependency (no BuildContext)
class CounterRepository {
  int getValue() => 0;
}

class GoodBloc extends Bloc<CounterEvent, int> {
  final CounterRepository repository;

  GoodBloc(this.repository) : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// ✅ Good: Cubit with no BuildContext dependency
class GoodCubit extends Cubit<int> {
  GoodCubit() : super(0);

  void increment() => emit(state + 1);
}

// ✅ Good: Non-Bloc class can freely accept BuildContext
class NotABloc {
  final BuildContext context;

  NotABloc(this.context);

  void doWork(BuildContext context) {}
}
