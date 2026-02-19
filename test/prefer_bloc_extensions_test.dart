import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_bloc_extensions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferBlocExtensionsTest));
}

@reflectiveTest
class PreferBlocExtensionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferBlocExtensions();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class BlocBase<State> {
  BlocBase(State initialState);
}
class Bloc<Event, State> extends BlocBase<State> {
  Bloc(super.initialState);
}
class Cubit<State> extends BlocBase<State> {
  Cubit(super.initialState);
}
''');
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
''');
    newPackage('flutter_bloc').addFile('lib/flutter_bloc.dart', r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

class BlocProvider<T extends BlocBase> {
  static T of<T extends BlocBase>(BuildContext context, {bool listen = false}) {
    throw UnimplementedError();
  }
}

class RepositoryProvider<T> {
  static T of<T>(BuildContext context, {bool listen = false}) {
    throw UnimplementedError();
  }
}

extension ReadContext on BuildContext {
  T read<T>() => throw UnimplementedError();
}

extension WatchContext on BuildContext {
  T watch<T>() => throw UnimplementedError();
}
''');
    super.setUp();
  }

  Future<void> test_blocProviderOfWithTypeArg() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  final bloc = BlocProvider.of<MyCubit>(context);
}
''',
      [lint(226, 33)],
    );
  }

  Future<void> test_blocProviderOfWithoutTypeArg() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  BlocProvider.of(context);
}
''',
      [lint(213, 24)],
    );
  }

  Future<void> test_blocProviderOfWithListenTrue() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  BlocProvider.of<MyCubit>(context, listen: true);
}
''',
      [lint(213, 47)],
    );
  }

  Future<void> test_blocProviderOfWithListenFalse() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  BlocProvider.of<MyCubit>(context, listen: false);
}
''',
      [lint(213, 48)],
    );
  }

  Future<void> test_repositoryProviderOf() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class MyRepo {}
void f(BuildContext context) {
  final repo = RepositoryProvider.of<MyRepo>(context);
}
''',
      [lint(150, 38)],
    );
  }

  Future<void> test_contextRead_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  context.read<MyCubit>();
}
''');
  }

  Future<void> test_contextWatch_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  context.watch<MyCubit>();
}
''');
  }

  Future<void> test_nonBlocProviderOf_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class MyProvider {
  static int of(dynamic context) => 42;
}
void f() {
  MyProvider.of('context');
}
''');
  }

  Future<void> test_unrelatedMethodInvocation_noDiagnostic() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  list.indexOf(2);
}
''');
  }
}
