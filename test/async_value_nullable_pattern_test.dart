import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/async_value_nullable_pattern.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AsyncValueNullablePatternTest),
  );
}

@reflectiveTest
class AsyncValueNullablePatternTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AsyncValueNullablePattern();

    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class AsyncValue<T> {
  const AsyncValue();
  T? get value => throw UnimplementedError();
  bool get hasValue => throw UnimplementedError();
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData();
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError();
}
''');

    super.setUp();
  }

  Future<void> test_nullableValueType() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}
''',
      [lint(126, 12)],
    );
  }

  Future<void> test_dynamicValueType() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<dynamic> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}
''',
      [lint(129, 12)],
    );
  }

  Future<void> test_asyncLoadingWithNullableValue() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncLoading(:final value?):
      print(value);
    default:
      break;
  }
}
''',
      [lint(128, 12)],
    );
  }

  Future<void> test_nonNullableValueType() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<int> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}
''');
  }

  Future<void> test_asyncDataNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncData(:final value?):
      print(value);
    default:
      break;
  }
}
''');
  }

  Future<void> test_hasValuePatternNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value, hasValue: true):
      print(value);
    default:
      break;
  }
}
''');
  }

  Future<void> test_otherFieldNotFlagged() async {
    await assertNoDiagnostics(r'''
class Box {
  int? get other => null;
}

void fn(Box box) {
  switch (box) {
    case Box(:final other?):
      print(other);
    default:
      break;
  }
}
''');
  }
}
