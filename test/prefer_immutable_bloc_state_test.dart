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
}
