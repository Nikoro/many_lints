// ignore_for_file: unused_element, unused_local_variable

// check_is_not_closed_after_async_gap
//
// Warns when a bloc emits state after an await without checking isClosed.
// A bloc can be closed while a handler is suspended; emitting into a closed
// bloc throws a StateError from inside a detached future.

import 'package:bloc/bloc.dart';

class _Repository {
  Future<int> fetchA() async => 1;
  Future<int> fetchB() async => 2;
}

final _repository = _Repository();

// ❌ Bad: emitting after an await with no guard
class _BadCubit extends Cubit<int> {
  _BadCubit() : super(0);

  Future<void> load() async {
    final value = await _repository.fetchA();
    // LINT: the cubit may have been closed while this was suspended
    emit(value);
  }
}

// ❌ Bad: a second await needs its own guard
class _BadSecondGapCubit extends Cubit<int> {
  _BadSecondGapCubit() : super(0);

  Future<void> loadTwice() async {
    final a = await _repository.fetchA();
    if (isClosed) return;
    emit(a);

    final b = await _repository.fetchB();
    // LINT: the guard above no longer covers this await
    emit(b);
  }
}

sealed class LoadEvent {}

class StartLoading extends LoadEvent {}

// ❌ Bad: same problem inside a bloc event handler
class _BadBloc extends Bloc<LoadEvent, int> {
  _BadBloc() : super(0) {
    on<StartLoading>((event, emit) async {
      final value = await _repository.fetchA();
      // LINT: unguarded emit after an async gap
      emit(value);
    });
  }
}

// ✅ Good: early-return guard after each await
class _GoodCubit extends Cubit<int> {
  _GoodCubit() : super(0);

  Future<void> loadTwice() async {
    final a = await _repository.fetchA();
    if (isClosed) return;
    emit(a);

    final b = await _repository.fetchB();
    if (isClosed) return;
    emit(b);
  }
}

// ✅ Good: the inverted guard shape works too
class _GoodInvertedGuardCubit extends Cubit<int> {
  _GoodInvertedGuardCubit() : super(0);

  Future<void> load() async {
    final value = await _repository.fetchA();
    if (!isClosed) {
      emit(value);
    }
  }
}

// ✅ Good: emitting before the await needs no guard
class _GoodEmitFirstCubit extends Cubit<int> {
  _GoodEmitFirstCubit() : super(0);

  Future<void> load() async {
    emit(-1);
    final value = await _repository.fetchA();
  }
}

// ✅ Good: a synchronous method has no async gap at all
class _GoodSyncCubit extends Cubit<int> {
  _GoodSyncCubit() : super(0);

  void increment() => emit(state + 1);
}

// ✅ Edge case: emit on an unrelated object is not a bloc emit
class _Recorder {
  void emit(int value) {}
}

class _EdgeCaseCubit extends Cubit<int> {
  _EdgeCaseCubit() : super(0);

  final _recorder = _Recorder();

  Future<void> record() async {
    final value = await _repository.fetchA();
    // Not BlocBase.emit — no lint
    _recorder.emit(value);
  }
}
