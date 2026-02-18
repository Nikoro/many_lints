import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/dispose_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(DisposeFieldsTest));
}

@reflectiveTest
class DisposeFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisposeFields();

    final flutter = newPackage('flutter');
    flutter.addFile('lib/widgets.dart', r'''
class Widget {}
class StatelessWidget extends Widget {
  Widget build() => throw UnimplementedError();
}
class StatefulWidget extends Widget {
  State createState() => throw UnimplementedError();
}
abstract class State<T extends StatefulWidget> {
  void initState() {}
  void didUpdateWidget(T oldWidget) {}
  void didChangeDependencies() {}
  void dispose() {}
  Widget build();
  void setState(void Function() fn) {}
}
class ChangeNotifier {
  void addListener(void Function() listener) {}
  void removeListener(void Function() listener) {}
  void dispose() {}
}
class TextEditingController extends ChangeNotifier {}
class ScrollController extends ChangeNotifier {}
class FocusNode extends ChangeNotifier {}
class AnimationController extends ChangeNotifier {}
class TabController extends ChangeNotifier {}
class PageController extends ScrollController {}
''');

    final dartAsync = newPackage('dart_async_mock');
    dartAsync.addFile('lib/dart_async_mock.dart', r'''
class StreamController<T> {
  void add(T event) {}
  Future<void> close() => Future.value();
}
class StreamSubscription<T> {
  Future<void> cancel() => Future.value();
}
class Timer {
  Timer(Duration duration, void Function() callback);
  Timer.periodic(Duration duration, void Function(Timer) callback);
  void cancel() {}
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_textEditingControllerNotDisposed() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  Widget build() => Widget();
}
''',
      [lint(203, 11)],
    );
  }

  Future<void> test_multipleControllersNotDisposed() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build() => Widget();
}
''',
      [lint(203, 15), lint(254, 17)],
    );
  }

  Future<void> test_focusNodeNotDisposed() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _focusNode = FocusNode();

  @override
  Widget build() => Widget();
}
''',
      [lint(203, 10)],
    );
  }

  Future<void> test_disposeExistsButFieldNotDisposed() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''',
      [lint(203, 11)],
    );
  }

  Future<void> test_streamControllerNotClosed() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:dart_async_mock/dart_async_mock.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _streamController = StreamController<int>();

  @override
  Widget build() => Widget();
}
''',
      [lint(258, 17)],
    );
  }

  Future<void> test_streamSubscriptionNotCancelled() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:dart_async_mock/dart_async_mock.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription<int> _subscription;

  @override
  Widget build() => Widget();
}
''',
      [lint(281, 13)],
    );
  }

  Future<void> test_timerNotCancelled() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:dart_async_mock/dart_async_mock.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late Timer _timer;

  @override
  Widget build() => Widget();
}
''',
      [lint(263, 6)],
    );
  }

  Future<void> test_lateFieldNotDisposed() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController();
  }

  @override
  Widget build() => Widget();
}
''',
      [lint(228, 11)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_controllerProperlyDisposed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_multipleControllersAllDisposed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_streamControllerProperlyClosed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:dart_async_mock/dart_async_mock.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _streamController = StreamController<int>();

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_streamSubscriptionProperlyCancelled() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:dart_async_mock/dart_async_mock.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription<int> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_disposedWithThisPrefix() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class SomeClass {
  final _controller = TextEditingController();
}
''');
  }

  Future<void> test_staticFieldNotChecked() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  static final _sharedController = TextEditingController();

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_nonDisposableFieldIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _counter = 0;
  String _label = '';
  final List<int> _items = [];

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_statelessWidgetIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final _controller = TextEditingController();

  @override
  Widget build() => Widget();
}
''');
  }
}
