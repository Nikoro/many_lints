import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/check_is_not_closed_after_async_gap.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(CheckIsNotClosedAfterAsyncGapTest),
  );
}

@reflectiveTest
class CheckIsNotClosedAfterAsyncGapTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = CheckIsNotClosedAfterAsyncGap();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
typedef EventHandler<E, S> = Future<void> Function(E event, Emitter<S> emit);

class Emitter<S> {
  void call(S state) {}
}

abstract class BlocBase<S> {
  BlocBase(this.state);
  S state;
  bool get isClosed => false;
  void emit(S state) {}
}

abstract class Bloc<E, S> extends BlocBase<S> {
  Bloc(super.state);
  void on<T extends E>(EventHandler<T, S> handler) {}
}

abstract class Cubit<S> extends BlocBase<S> {
  Cubit(super.state);
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_cubitEmitAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    emit(1);
  }
}
''',
      [lint(175, 7)],
    );
  }

  Future<void> test_blocHandlerEmitAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class LoadEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<LoadEvent>((event, emit) async {
      await Future<void>.delayed(Duration.zero);
      emit(1);
    });
  }
}
''',
      [lint(257, 7)],
    );
  }

  Future<void> test_emitAfterSecondAwaitFollowingGuard() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (isClosed) return;
    emit(1);
    await Future<void>.delayed(Duration.zero);
    emit(2);
  }
}
''',
      [lint(261, 7)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_emitBeforeAwait() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    emit(1);
    await Future<void>.delayed(Duration.zero);
  }
}
''');
  }

  Future<void> test_emitAfterAwaitWithGuard() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (isClosed) return;
    emit(1);
  }
}
''');
  }

  Future<void> test_emitAfterAwaitWithGuardBlockBody() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (isClosed) {
      return;
    }
    emit(1);
  }
}
''');
  }

  Future<void> test_blocHandlerWithGuard() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class LoadEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<LoadEvent>((event, emit) async {
      await Future<void>.delayed(Duration.zero);
      if (isClosed) return;
      emit(1);
    });
  }
}
''');
  }

  Future<void> test_synchronousMethod() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  void increment() {
    emit(state + 1);
  }
}
''');
  }

  Future<void> test_negatedGuardWrapping() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (!isClosed) {
      emit(1);
    }
  }
}
''');
  }

  Future<void> test_emitOnUnrelatedClass() async {
    await assertNoDiagnostics(r'''
class Recorder {
  void emit(int value) {}
}

class NotABloc {
  Future<void> run() async {
    final recorder = Recorder();
    await Future<void>.delayed(Duration.zero);
    recorder.emit(1);
  }
}
''');
  }

  Future<void> test_emitOnOtherObjectInsideCubit() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class Recorder {
  void emit(int value) {}
}

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  final recorder = Recorder();

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    recorder.emit(1);
  }
}
''');
  }
}
