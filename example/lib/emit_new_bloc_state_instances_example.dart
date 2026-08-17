// ignore_for_file: unused_element, unused_local_variable
// The state class is deliberately plain so the emit shapes stay the focus.
// ignore_for_file: many_lints/prefer_immutable_bloc_state
// ignore_for_file: many_lints/prefer_returning_shorthands

// emit_new_bloc_state_instances
//
// Warns when emit receives the current state object instead of a new instance.
// BlocBase.emit compares the incoming state with `==` and drops it when it
// equals the current one, so emitting `state` back is a silent no-op.

import 'package:bloc/bloc.dart';

class _TodoState {
  const _TodoState(this.items);

  final List<String> items;

  _TodoState copyWith({List<String>? items}) => _TodoState(items ?? this.items);
}

// ❌ Bad: mutating the state and re-emitting the same instance
class _BadTodoCubit extends Cubit<_TodoState> {
  _BadTodoCubit() : super(const _TodoState([]));

  void add(String todo) {
    state.items.add(todo);
    // LINT: same instance, so `==` holds and no listener is notified
    emit(state);
  }
}

// ❌ Bad: the `this.` qualified form has the same problem
class _BadQualifiedCubit extends Cubit<int> {
  _BadQualifiedCubit() : super(0);

  void refresh() {
    // LINT: emitting the current state through `this.state`
    emit(this.state);
  }
}

// ❌ Bad: inside a Bloc handler, where `emit` is the Emitter parameter
class _BadBloc extends Bloc<String, int> {
  _BadBloc() : super(0) {
    on<String>((event, emit) {
      // LINT: the Emitter parameter has the same no-op behaviour
      emit(state);
    });
  }
}

// ✅ Good: copyWith produces a new instance
class _GoodTodoCubit extends Cubit<_TodoState> {
  _GoodTodoCubit() : super(const _TodoState([]));

  void add(String todo) {
    emit(state.copyWith(items: [...state.items, todo]));
  }
}

// ✅ Good: a value derived from the state is a different object
class _GoodCounterCubit extends Cubit<int> {
  _GoodCounterCubit() : super(0);

  void increment() {
    emit(state + 1);
  }
}

// ✅ Good: a freshly constructed instance
class _GoodResetCubit extends Cubit<_TodoState> {
  _GoodResetCubit() : super(const _TodoState([]));

  void reset() {
    emit(const _TodoState([]));
  }
}

// ✅ Edge case: `emit` on an unrelated class is not a Bloc emit
class _NotABloc {
  int state = 0;

  void emit(int value) {}

  void refresh() {
    emit(state);
  }
}
// ignore_for_file: many_lints/prefer_immutable_state
