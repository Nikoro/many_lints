import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/pass_existing_future_to_future_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PassExistingFutureToFutureBuilderTest),
  );
}

@reflectiveTest
class PassExistingFutureToFutureBuilderTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PassExistingFutureToFutureBuilder();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
import 'dart:async';

class Widget {}
class BuildContext {}
class StatefulWidget extends Widget {}
class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
}
class AsyncSnapshot<T> {}
typedef AsyncWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<T> snapshot,
);
class FutureBuilder<T> extends Widget {
  FutureBuilder({this.future, required this.builder});
  final Future<T>? future;
  final AsyncWidgetBuilder<T> builder;
}
class Text extends Widget {
  Text(this.data);
  final String data;
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_methodCallCreatesFuture() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Future<String> fetchData() async => 'data';

Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: fetchData(),
    builder: (context, snapshot) => Text('x'),
  );
}
''',
      [lint(166, 11)],
    );
  }

  Future<void> test_futureDelayedConstructor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: Future.delayed(Duration.zero, () => 'x'),
    builder: (context, snapshot) => Text('x'),
  );
}
''',
      [lint(121, 40)],
    );
  }

  Future<void> test_methodCallOnObject() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class Repository {
  Future<String> load() async => 'data';
}

final repository = Repository();

Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: repository.load(),
    builder: (context, snapshot) => Text('x'),
  );
}
''',
      [lint(218, 17)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_fieldReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  late final Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value('data');
  }

  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) => Text('x'),
    );
  }
}
''');
  }

  Future<void> test_localVariableReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext context, Future<String> existing) {
  return FutureBuilder<String>(
    future: existing,
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }

  Future<void> test_topLevelVariableReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final myFuture = Future.value('data');

Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: myFuture,
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }

  Future<void> test_noFutureArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext context) {
  return FutureBuilder<String>(
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }

  Future<void> test_methodCallOnNonFutureBuilder() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<String> fetchData() async => 'data';

class MyOwnBuilder extends Widget {
  MyOwnBuilder({this.future});
  final Future<String>? future;
}

Widget build(BuildContext context) {
  return MyOwnBuilder(future: fetchData());
}
''');
  }

  Future<void> test_propertyAccessReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Holder {
  final Future<String> future = Future.value('data');
}

final holder = Holder();

Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: holder.future,
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }
}
