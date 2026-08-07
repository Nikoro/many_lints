import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/pass_existing_stream_to_stream_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PassExistingStreamToStreamBuilderTest),
  );
}

@reflectiveTest
class PassExistingStreamToStreamBuilderTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PassExistingStreamToStreamBuilder();
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
class StreamBuilder<T> extends Widget {
  StreamBuilder({this.stream, required this.builder});
  final Stream<T>? stream;
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

  Future<void> test_methodCallCreatesStream() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Stream<String> watchData() async* { yield 'data'; }

Widget build(BuildContext context) {
  return StreamBuilder<String>(
    stream: watchData(),
    builder: (context, snapshot) => Text('x'),
  );
}
''',
      [lint(174, 11)],
    );
  }

  Future<void> test_streamFromIterableConstructor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext context) {
  return StreamBuilder<int>(
    stream: Stream.fromIterable([1, 2, 3]),
    builder: (context, snapshot) => Text('x'),
  );
}
''',
      [lint(118, 30)],
    );
  }

  Future<void> test_methodCallOnObject() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class Repository {
  Stream<String> watch() async* { yield 'data'; }
}

final repository = Repository();

Widget build(BuildContext context) {
  return StreamBuilder<String>(
    stream: repository.watch(),
    builder: (context, snapshot) => Text('x'),
  );
}
''',
      [lint(227, 18)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_fieldReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  late final Stream<String> _stream;

  @override
  void initState() {
    super.initState();
    _stream = Stream.value('data');
  }

  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _stream,
      builder: (context, snapshot) => Text('x'),
    );
  }
}
''');
  }

  Future<void> test_parameterReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext context, Stream<String> existing) {
  return StreamBuilder<String>(
    stream: existing,
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }

  Future<void> test_topLevelVariableReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final myStream = Stream.value('data');

Widget build(BuildContext context) {
  return StreamBuilder<String>(
    stream: myStream,
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }

  Future<void> test_noStreamArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(BuildContext context) {
  return StreamBuilder<String>(
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }

  Future<void> test_methodCallOnNonStreamBuilder() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Stream<String> watchData() async* { yield 'data'; }

class MyOwnBuilder extends Widget {
  MyOwnBuilder({this.stream});
  final Stream<String>? stream;
}

Widget build(BuildContext context) {
  return MyOwnBuilder(stream: watchData());
}
''');
  }

  Future<void> test_propertyAccessReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Holder {
  final Stream<String> stream = Stream.value('data');
}

final holder = Holder();

Widget build(BuildContext context) {
  return StreamBuilder<String>(
    stream: holder.stream,
    builder: (context, snapshot) => Text('x'),
  );
}
''');
  }
}
