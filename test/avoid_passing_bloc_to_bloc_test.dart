import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_passing_bloc_to_bloc.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidPassingBlocToBlocTest),
  );
}

@reflectiveTest
class AvoidPassingBlocToBlocTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPassingBlocToBloc();
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
    super.setUp();
  }

  Future<void> test_blocDependsOnBloc() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
abstract class EventB {}
class BlocA extends Bloc<EventA, int> {
  BlocA() : super(0);
}
class BlocB extends Bloc<EventB, int> {
  final BlocA blocA;
  BlocB(this.blocA) : super(0);
}
''',
      [lint(221, 5)],
    );
  }

  Future<void> test_blocDependsOnCubit() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
class CubitA extends Cubit<int> {
  CubitA() : super(0);
}
class BlocB extends Bloc<EventA, int> {
  final CubitA cubitA;
  BlocB(this.cubitA) : super(0);
}
''',
      [lint(193, 6)],
    );
  }

  Future<void> test_cubitDependsOnBloc() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
class BlocA extends Bloc<EventA, int> {
  BlocA() : super(0);
}
class CubitB extends Cubit<int> {
  final BlocA blocA;
  CubitB(this.blocA) : super(0);
}
''',
      [lint(191, 5)],
    );
  }

  Future<void> test_cubitDependsOnCubit() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
class CubitA extends Cubit<int> {
  CubitA() : super(0);
}
class CubitB extends Cubit<int> {
  final CubitA cubitA;
  CubitB(this.cubitA) : super(0);
}
''',
      [lint(163, 6)],
    );
  }

  Future<void> test_namedParameter() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
abstract class EventB {}
class BlocA extends Bloc<EventA, int> {
  BlocA() : super(0);
}
class BlocB extends Bloc<EventB, int> {
  final BlocA blocA;
  BlocB({required this.blocA}) : super(0);
}
''',
      [lint(231, 5)],
    );
  }

  Future<void> test_repositoryParameter_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
class MyRepository {}
class BlocA extends Bloc<EventA, int> {
  final MyRepository repo;
  BlocA(this.repo) : super(0);
}
''');
  }

  Future<void> test_noConstructorParameters_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
class BlocA extends Bloc<EventA, int> {
  BlocA() : super(0);
}
''');
  }

  Future<void> test_primitiveParameter_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
class BlocA extends Bloc<EventA, int> {
  final int initialValue;
  BlocA(this.initialValue) : super(0);
}
''');
  }

  Future<void> test_nonBlocClass_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class EventA {}
class BlocA extends Bloc<EventA, int> {
  BlocA() : super(0);
}
class NotABloc {
  final BlocA blocA;
  NotABloc(this.blocA);
}
''');
  }
}
