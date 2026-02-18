import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/always_remove_listener.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AlwaysRemoveListenerTest));
}

@reflectiveTest
class AlwaysRemoveListenerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AlwaysRemoveListener();

    final flutter = newPackage('flutter');
    flutter.addFile('lib/widgets.dart', r'''
class Widget {}
class StatelessWidget extends Widget {}
class StatefulWidget extends Widget {
  State createState() => throw UnimplementedError();
}
abstract class State<T extends StatefulWidget> {
  void initState() {}
  void didUpdateWidget(T oldWidget) {}
  void didChangeDependencies() {}
  void dispose() {}
  Widget build();
}
''');
    flutter.addFile('lib/foundation.dart', r'''
typedef VoidCallback = void Function();

abstract class Listenable {
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

class ChangeNotifier implements Listenable {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class ValueNotifier<T> extends ChangeNotifier {
  T value;
  ValueNotifier(this.value);
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_addListenerInInitState_noDispose() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''',
      [lint(355, 33)],
    );
  }

  Future<void> test_addListenerInInitState_disposeWithoutRemove() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''',
      [lint(355, 33)],
    );
  }

  Future<void> test_addListenerInDidUpdateWidget_noRemove() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''',
      [lint(394, 33)],
    );
  }

  Future<void> test_addListenerInDidChangeDependencies_noRemove() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''',
      [lint(379, 33)],
    );
  }

  Future<void> test_multipleListeners_oneNotRemoved() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _a = ValueNotifier(0);
  final ValueNotifier<int> _b = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _a.addListener(_onA);
    _b.addListener(_onB);
  }

  @override
  void dispose() {
    _a.removeListener(_onA);
    super.dispose();
  }

  void _onA() {}
  void _onB() {}

  @override
  Widget build() => Widget();
}
''',
      [lint(424, 20)],
    );
  }

  Future<void> test_wrongListenerRemovedInDispose() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    _notifier.removeListener(_wrongListener);
    super.dispose();
  }

  void _onChanged() {}
  void _wrongListener() {}

  @override
  Widget build() => Widget();
}
''',
      [lint(355, 33)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_matchingRemoveListenerInDispose() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_multipleListenersAllRemoved() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _a = ValueNotifier(0);
  final ValueNotifier<int> _b = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _a.addListener(_onA);
    _b.addListener(_onB);
  }

  @override
  void dispose() {
    _a.removeListener(_onA);
    _b.removeListener(_onB);
    super.dispose();
  }

  void _onA() {}
  void _onB() {}

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_noListenersAdded() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';

class SomeClass {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  void init() {
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}
}
''');
  }

  Future<void> test_addListenerOutsideLifecycleMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  void someOtherMethod() {
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''');
  }

  Future<void> test_addListenerWithStoredCallback_matchingRemove() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {};
    _notifier.addListener(_listener);
  }

  @override
  void dispose() {
    _notifier.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''');
  }
}
