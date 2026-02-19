import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_bloc_public_methods.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidBlocPublicMethodsTest),
  );
}

@reflectiveTest
class AvoidBlocPublicMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBlocPublicMethods();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class Bloc<Event, State> {
  Bloc(State initialState);
  void add(Event event) {}
  void onChange(dynamic change) {}
}
class Cubit<State> extends Bloc<dynamic, State> {
  Cubit(super.initialState);
}
''');
    super.setUp();
  }

  Future<void> test_publicMethod() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  void changeState(int newState) {}
}
''',
      [lint(151, 11)],
    );
  }

  Future<void> test_publicGetter() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  int get currentValue => 0;
}
''',
      [lint(154, 12)],
    );
  }

  Future<void> test_publicSetter() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  set currentValue(int value) {}
}
''',
      [lint(150, 12)],
    );
  }

  Future<void> test_multiplePublicMethods() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  void increment() {}
  void decrement() {}
}
''',
      [lint(151, 9), lint(173, 9)],
    );
  }

  Future<void> test_privateMethod_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  void _changeState(int newState) {}
}
''');
  }

  Future<void> test_overrideMethod_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  @override
  void onChange(dynamic change) {}
}
''');
  }

  Future<void> test_staticMethod_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
  static void helper() {}
}
''');
  }

  Future<void> test_cubit_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() {}
}
''');
  }

  Future<void> test_notABloc_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class Counter {
  void increment() {}
}
''');
  }
}
