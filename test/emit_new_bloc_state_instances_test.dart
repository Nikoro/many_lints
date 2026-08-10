import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/emit_new_bloc_state_instances.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(EmitNewBlocStateInstancesTest),
  );
}

@reflectiveTest
class EmitNewBlocStateInstancesTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = EmitNewBlocStateInstances();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
typedef EventHandler<E, S> = void Function(E event, Emitter<S> emit);

class Emitter<S> {
  void call(S state) {}
}

abstract class BlocBase<S> {
  BlocBase(this.state);
  S state;
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

  Future<void> test_cubitEmitsStateDirectly() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  void refresh() {
    emit(state);
  }
}
''',
      [lint(122, 5)],
    );
  }

  Future<void> test_thisQualifiedState() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  void refresh() {
    emit(this.state);
  }
}
''',
      [lint(122, 10)],
    );
  }

  Future<void> test_blocHandlerEmitterParameter() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyBloc extends Bloc<int, int> {
  MyBloc() : super(0) {
    on<int>((event, emit) {
      emit(state);
    });
  }
}
''',
      [lint(135, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_emitsDerivedValue() async {
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

  Future<void> test_emitsCopyWith() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyState {
  const MyState(this.count);
  final int count;
  MyState copyWith({int? count}) => MyState(count ?? this.count);
}

class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState(0));

  void increment() {
    emit(state.copyWith(count: state.count + 1));
  }
}
''');
  }

  Future<void> test_emitsNewInstance() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class MyState {
  const MyState(this.count);
  final int count;
}

class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState(0));

  void reset() {
    emit(const MyState(0));
  }
}
''');
  }

  Future<void> test_nonBlocClassIsIgnored() async {
    await assertNoDiagnostics(r'''
class NotABloc {
  int state = 0;
  void emit(int value) {}

  void refresh() {
    emit(state);
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_emitOnAnotherObjectIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class Other {
  int state = 0;
  void emit(int value) {}
}

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  final Other other = Other();

  void refresh() {
    other.emit(other.state);
  }
}
''');
  }

  Future<void> test_stateInsideCallbackIsReported() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  void refresh() {
    [1].forEach((_) {
      emit(state);
    });
  }
}
''',
      [lint(146, 5)],
    );
  }

  Future<void> test_parenthesizedStateIsReported() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

class MyCubit extends Cubit<int> {
  MyCubit() : super(0);

  void refresh() {
    emit((state));
  }
}
''',
      [lint(122, 7)],
    );
  }
}
