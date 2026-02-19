import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_passing_build_context_to_blocs.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidPassingBuildContextToBlocsTest),
  );
}

@reflectiveTest
class AvoidPassingBuildContextToBlocsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPassingBuildContextToBlocs();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class BlocBase<State> {
  BlocBase(State initialState);
  Stream<State> get stream => Stream.empty();
}
class Bloc<Event, State> extends BlocBase<State> {
  Bloc(super.initialState);
  void add(Event event) {}
}
class Cubit<State> extends BlocBase<State> {
  Cubit(super.initialState);
}
''');
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
''');
    super.setUp();
  }

  Future<void> test_constructorWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc(BuildContext context) : super(0);
}
''',
      [lint(182, 7)],
    );
  }

  Future<void> test_namedConstructorWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc({required BuildContext context}) : super(0);
}
''',
      [lint(192, 7)],
    );
  }

  Future<void> test_cubitMethodWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void doSomething(BuildContext context) {}
}
''',
      [lint(173, 7)],
    );
  }

  Future<void> test_cubitConstructorWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
class CounterCubit extends Cubit<int> {
  CounterCubit(BuildContext context) : super(0);
}
''',
      [lint(140, 7)],
    );
  }

  Future<void> test_multipleMethodsWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void first(BuildContext context) {}
  void second(BuildContext context) {}
}
''',
      [lint(167, 7), lint(206, 7)],
    );
  }

  Future<void> test_nonBuildContextParameter_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc(int initialValue) : super(0);
}
''');
  }

  Future<void> test_noBlocClass_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class NotABloc {
  NotABloc(BuildContext context);
  void doWork(BuildContext context) {}
}
''');
  }

  Future<void> test_noParameters_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}
''');
  }

  Future<void> test_privateMethodWithBuildContext() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void _privateMethod(BuildContext context) {}
}
''',
      [lint(176, 7)],
    );
  }
}
