import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/handle_bloc_event_subclasses.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(HandleBlocEventSubclassesTest),
  );
}

@reflectiveTest
class HandleBlocEventSubclassesTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = HandleBlocEventSubclasses();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
typedef EventHandler<E, S> = void Function(E event, Emitter<S> emit);

class Emitter<S> {
  void call(S state) {}
}

abstract class Bloc<E, S> {
  Bloc(this.state);
  S state;
  void on<T extends E>(EventHandler<T, S> handler) {}
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_missingHandler() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) {});
  }
}
''',
      [lint(152, 11)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_allHandlersRegistered() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) {});
    on<Decrement>((event, emit) {});
  }
}
''');
  }

  Future<void> test_baseTypeHandlerCoversAll() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterEvent>((event, emit) {});
  }
}
''');
  }

  Future<void> test_nonSealedEventIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) {});
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_sealedWithNoSubclassesIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}
''');
  }

  Future<void> test_nonBlocClassIsIgnored() async {
    await assertNoDiagnostics(r'''
sealed class CounterEvent {}

class Increment extends CounterEvent {}

class NotABloc {
  void on<T>(void Function(T, int) handler) {}
}
''');
  }
}
