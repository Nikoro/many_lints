import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_immutable_bloc_state.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferImmutableBlocStateTest),
  );
}

@reflectiveTest
class PreferImmutableBlocStateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferImmutableBlocState();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class Bloc<Event, State> {
  Bloc(State initialState);
  void add(Event event) {}
}
class Cubit<State> extends Bloc<dynamic, State> {
  Cubit(super.initialState);
}
''');
    newPackage('meta').addFile('lib/meta.dart', r'''
class immutable {
  const immutable();
}
const immutable = immutable();
''');
    super.setUp();
  }

  Future<void> test_sealedStateWithoutImmutable() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
sealed class CounterState {}
class CounterInitial extends CounterState {}
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial());
}
''',
      [lint(77, 12), lint(99, 14)],
    );
  }

  Future<void> test_stateSubclassWithoutImmutable() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
sealed class CounterState {}
class CounterInitial extends CounterState {}
class CounterLoaded extends CounterState {}
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial());
}
''',
      [lint(77, 12), lint(99, 14), lint(144, 13)],
    );
  }

  Future<void> test_cubitStateWithoutImmutable() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
sealed class CounterState {}
class CounterInitial extends CounterState {}
class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterInitial());
}
''',
      [lint(46, 12), lint(68, 14)],
    );
  }

  Future<void> test_stateNamePattern_noBloc() async {
    await assertDiagnostics(
      r'''
class MyFeatureState {}
''',
      [lint(6, 14)],
    );
  }

  Future<void> test_stateWithImmutable_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
abstract class CounterEvent {}
@immutable
sealed class CounterState {}
@immutable
class CounterInitial extends CounterState {}
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial());
}
''');
  }

  Future<void> test_cubitStateWithImmutable_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
@immutable
sealed class CounterState {}
@immutable
class CounterInitial extends CounterState {}
class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterInitial());
}
''');
  }

  Future<void> test_nonStateClass_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class MyWidget {}
class MyService {}
''');
  }

  Future<void> test_blocClassItself_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}
''');
  }

  Future<void> test_stateImplementsInterface() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
abstract class CounterEvent {}
sealed class CounterState {}
class CounterLoaded implements CounterState {}
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterLoaded());
}
''',
      [lint(77, 12), lint(99, 13)],
    );
  }

  Future<void> test_partiallyAnnotated() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
abstract class CounterEvent {}
@immutable
sealed class CounterState {}
class CounterInitial extends CounterState {}
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial());
}
''',
      [lint(143, 14)],
    );
  }

  Future<void> test_classNamedState_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class State {}
''');
  }

  // --- Cover Cubit state detection (lines 83-89) ---
  // The Cubit path is an `else if` that only fires when the Bloc branch
  // doesn't match. Since Cubit extends Bloc, MyCubit matches Bloc first.
  // To trigger the Cubit path, we need a standalone Cubit not extending Bloc.
  // Use a separate mock package with Cubit not extending Bloc.

  Future<void> test_cubitOnlyWithNonStateNamedClass() async {
    // Use a separate file in the existing bloc package where Cubit
    // does not extend Bloc, to isolate the Cubit detection path.
    final blocPkg = newPackage('bloc');
    blocPkg.addFile('lib/cubit_only.dart', r'''
class Cubit<State> {
  Cubit(State initialState);
}
''');

    await assertDiagnostics(
      r'''
import 'package:bloc/cubit_only.dart';
class MyData {}
class MyCubit extends Cubit<MyData> {
  MyCubit() : super(MyData());
}
''',
      [lint(45, 6)],
    );
  }

  Future<void> test_cubitOnlyWithSubclasses() async {
    final blocPkg = newPackage('bloc');
    blocPkg.addFile('lib/cubit_only2.dart', r'''
class Cubit<State> {
  Cubit(State initialState);
}
''');

    await assertDiagnostics(
      r'''
import 'package:bloc/cubit_only2.dart';
class AppModel {}
class InitialModel extends AppModel {}
class MyCubit extends Cubit<AppModel> {
  MyCubit() : super(InitialModel());
}
''',
      [lint(46, 8), lint(64, 12)],
    );
  }
}
