import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_duplicate_bloc_event_handlers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDuplicateBlocEventHandlersTest),
  );
}

@reflectiveTest
class AvoidDuplicateBlocEventHandlersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateBlocEventHandlers();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
typedef EventHandler<E, S> = void Function(E event, Emitter<S> emit);

class Emitter<S> {
  void call(S state) {}
}

abstract class BlocBase<S> {
  BlocBase(this.state);
  S state;
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

  Future<void> test_duplicateEventHandler() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    on<IncrementEvent>((event, emit) => emit(state + 2));
  }
}
''',
      [lint(229, 2)],
    );
  }

  Future<void> test_duplicateWithThisPrefix() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    this.on<IncrementEvent>((event, emit) => emit(state + 2));
  }
}
''',
      [lint(234, 2)],
    );
  }

  Future<void> test_tripleRegistrationReportsBothRepeats() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    on<IncrementEvent>((event, emit) => emit(state + 2));
    on<IncrementEvent>((event, emit) => emit(state + 3));
  }
}
''',
      [lint(229, 2), lint(287, 2)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_distinctEventHandlers() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}
class DecrementEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    on<DecrementEvent>((event, emit) => emit(state - 1));
  }
}
''');
  }

  Future<void> test_singleEventHandler() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
  }
}
''');
  }

  Future<void> test_sameEventInDifferentConstructors() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
  }

  MyBloc.alternative() : super(10) {
    on<IncrementEvent>((event, emit) => emit(state + 2));
  }
}
''');
  }

  Future<void> test_onCallOnUnrelatedClass() async {
    await assertNoDiagnostics(r'''
class Registry {
  void on<T>(void Function() handler) {}
}

class NotABloc {
  NotABloc() {
    final registry = Registry();
    registry.on<int>(() {});
    registry.on<int>(() {});
  }
}
''');
  }

  Future<void> test_onCallOnOtherObjectInsideBloc() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

abstract class MyEvent {}
class IncrementEvent extends MyEvent {}

class Registry {
  void on<T>(void Function() handler) {}
}

class MyBloc extends Bloc<MyEvent, int> {
  MyBloc() : super(0) {
    final registry = Registry();
    registry.on<int>(() {});
    registry.on<int>(() {});
    on<IncrementEvent>((event, emit) => emit(state + 1));
  }
}
''');
  }
}
