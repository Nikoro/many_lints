import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_add_all.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferAddAllTest));
}

@reflectiveTest
class PreferAddAllTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferAddAll();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_loopWithBlockBody() async {
    await assertDiagnostics(
      r'''
void copy(List<int> target, List<int> source) {
  for (final item in source) {
    target.add(item);
  }
}
''',
      [lint(50, 54)],
    );
  }

  Future<void> test_loopWithoutBraces() async {
    await assertDiagnostics(
      r'''
void copy(List<int> target, List<int> source) {
  for (final item in source) target.add(item);
}
''',
      [lint(50, 44)],
    );
  }

  Future<void> test_loopIntoField() async {
    await assertDiagnostics(
      r'''
class Holder {
  final List<int> items = [];

  void copy(List<int> source) {
    for (final item in source) {
      items.add(item);
    }
  }
}
''',
      [lint(82, 57)],
    );
  }

  // ---- Consecutive add() calls ----

  Future<void> test_twoConsecutiveAdds() async {
    await assertDiagnostics(
      r'''
void fill(List<String> values) {
  values.add('first');
  values.add('second');
}
''',
      [lint(58, 20)],
    );
  }

  Future<void> test_threeConsecutiveAddsReportedOnce() async {
    await assertDiagnostics(
      r'''
void fill(List<String> values) {
  values.add('a');
  values.add('b');
  values.add('c');
}
''',
      [lint(54, 15)],
    );
  }

  Future<void> test_consecutiveAddsOnField() async {
    await assertDiagnostics(
      r'''
class Holder {
  final List<int> items = [];

  void fill() {
    items.add(1);
    items.add(2);
  }
}
''',
      [lint(84, 12)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_singleAdd() async {
    await assertNoDiagnostics(r'''
void fill(List<String> values) {
  values.add('only');
}
''');
  }

  Future<void> test_addsOnDifferentReceivers() async {
    await assertNoDiagnostics(r'''
void fill(List<String> a, List<String> b) {
  a.add('x');
  b.add('y');
}
''');
  }

  Future<void> test_addsSeparatedByOtherStatement() async {
    await assertNoDiagnostics(r'''
void fill(List<String> values) {
  values.add('first');
  print('between');
  values.add('second');
}
''');
  }

  Future<void> test_addsOnNonCollection() async {
    await assertNoDiagnostics(r'''
class Sink {
  void add(String value) {}
}

void fill(Sink sink) {
  sink.add('a');
  sink.add('b');
}
''');
  }

  Future<void> test_loopWithTransformation() async {
    await assertNoDiagnostics(r'''
void copy(List<String> target, List<int> source) {
  for (final item in source) {
    target.add('$item');
  }
}
''');
  }

  Future<void> test_loopWithCondition() async {
    await assertNoDiagnostics(r'''
void copy(List<int> target, List<int> source) {
  for (final item in source) {
    if (item.isEven) target.add(item);
  }
}
''');
  }

  Future<void> test_loopWithExtraStatement() async {
    await assertNoDiagnostics(r'''
void copy(List<int> target, List<int> source) {
  for (final item in source) {
    target.add(item);
    print(item);
  }
}
''');
  }

  Future<void> test_indexedLoop() async {
    await assertNoDiagnostics(r'''
void copy(List<int> target, List<int> source) {
  for (var i = 0; i < source.length; i++) {
    target.add(source[i]);
  }
}
''');
  }

  Future<void> test_loopCallingOtherMethod() async {
    await assertNoDiagnostics(r'''
void copy(Set<int> target, List<int> source) {
  for (final item in source) {
    target.remove(item);
  }
}
''');
  }

  Future<void> test_alreadyAddAll() async {
    await assertNoDiagnostics(r'''
void copy(List<int> target, List<int> source) {
  target.addAll(source);
}
''');
  }
}
