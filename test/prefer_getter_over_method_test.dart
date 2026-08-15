import 'package:many_lints/src/rules/prefer_getter_over_method.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferGetterOverMethodTest),
  );
}

@reflectiveTest
class PreferGetterOverMethodTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferGetterOverMethod();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_noArgumentExpressionMethod() async {
    await assertDiagnostics(
      r'''
class Order {
  final int amount = 0;
  int total() => amount * 2;
}
''',
      [lint(44, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_alreadyAGetter() async {
    await assertNoDiagnostics(r'''
class Order {
  final int amount = 0;
  int get total => amount * 2;
}
''');
  }

  Future<void> test_takesParameters() async {
    await assertNoDiagnostics(r'''
class Order {
  int totalWith(int extra) => extra;
}
''');
  }

  Future<void> test_voidMethodIsCalledForItsEffect() async {
    await assertNoDiagnostics(r'''
class Order {
  void submit() => print('sent');
}
''');
  }

  Future<void> test_blockBodyMayDoRealWork() async {
    await assertNoDiagnostics(r'''
class Order {
  int total() {
    final base = 1;
    return base * 2;
  }
}
''');
  }

  Future<void> test_overrideKeepsTheInheritedShape() async {
    // Only the base declaration is reported; an override cannot change to a
    // getter on its own, so flagging it would demand an impossible fix.
    await assertDiagnostics(
      r'''
class Base {
  int total() => 0;
}

class Order extends Base {
  @override
  int total() => 1;
}
''',
      [lint(19, 5)],
    );
  }

  // ---- Edge cases ----

  Future<void> test_asyncReadsAsWork() async {
    await assertNoDiagnostics(r'''
class Order {
  Future<int> total() async => 1;
}
''');
  }

  Future<void> test_bodyThatCallsSomethingIsNotAPlainRead() async {
    // `now()` and `sixDigitCode()` answer differently on each call, and a
    // getter promises a stable property — the parentheses are correct here.
    await assertNoDiagnostics(r'''
class Clock {
  const Clock(this._now);

  final DateTime Function() _now;

  DateTime now() => _now();
}

class Generator {
  final int Function() _source = _one;
  int code() => _source();
}

int _one() => 1;
''');
  }

  Future<void> test_conventionalMethodNamesKeepTheirParentheses() async {
    // `toJson` is what every serialiser looks for and `call` is the
    // invocation operator in all but name — neither is a free choice.
    await assertNoDiagnostics(r'''
class Payload {
  final int id = 0;

  Map<String, Object?> toJson() => {'id': id};
  int call() => id;
  Payload copyWith() => this;
}
''');
  }

  Future<void> test_streamIsSubscribedToNotRead() async {
    await assertNoDiagnostics(r'''
class Store {
  Store(this._values);

  final Stream<int> _values;

  Stream<int> watchValues() => _values;
}
''');
  }

  Future<void> test_genericMethodTakesTypeArguments() async {
    // A getter cannot be invoked with type arguments.
    await assertNoDiagnostics(r'''
class Box {
  T? valueOf<T>() => null;
}
''');
  }
}
