import 'package:bloc/bloc.dart';

// use_class_suffix
//
// Warns when a class deriving from a configured type lacks the required name
// suffix. The rule reports nothing until you configure it — see the
// `use_class_suffix` entry in example/many_lints.yaml, which requires the
// 'Bloc' suffix for subtypes of Bloc.
//
// The base type matches whether it is reached by extends, implements, with,
// or an indirect ancestor.

sealed class CounterEvent {}

// LINT: derives from Bloc but does not end with 'Bloc'
class CounterManager extends Bloc<CounterEvent, int> {
  CounterManager() : super(0);
}

// OK: carries the required suffix.
class SettingsBloc extends Bloc<CounterEvent, int> {
  SettingsBloc() : super(0);
}

// OK: unrelated to any configured type.
class PlainHelper {}
