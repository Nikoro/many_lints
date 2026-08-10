// ignore_for_file: unused_local_variable, unused_element
// ignore_for_file: many_lints/function_always_returns_null
// ignore_for_file: many_lints/avoid_commented_out_code
// ignore_for_file: many_lints/prefer_type_over_var
// ignore_for_file: many_lints/avoid_single_field_destructuring

// avoid_non_null_assertion
//
// Warns on every use of the null-assertion operator `!`. It is an unchecked
// assertion, not a check: it throws a TypeError at runtime when the value
// really is null, instead of handling that case.

class _Config {
  const _Config(this.timeout, this.child);
  final Duration? timeout;
  final _Config? child;

  String? describe() => null;
}

// ❌ Bad: asserting null away instead of handling it
class BadExamples {
  void propertyAccess(_Config config) {
    // LINT: throws if `timeout` is null.
    print(config.timeout!.inSeconds);
  }

  void methodInvocation(_Config config) {
    // LINT: throws if `child` is null.
    config.child!.describe();
  }

  void chained(_Config config) {
    // LINT (twice): each bang in the chain can throw independently.
    print(config.child!.timeout!.inSeconds);
  }

  void localVariable(int? value) {
    // LINT: nothing narrowed `value` first.
    print(value!);
  }

  void listIndex(List<String?> values) {
    // LINT: unlike Map, List's index operator is only nullable because the
    // element type is — a null here means the data is wrong, not missing.
    print(values[0]!.length);
  }
}

// ✅ Good: handle the null case
class GoodExamples {
  void nullAware(_Config config) {
    print(config.timeout?.inSeconds);
  }

  void fallback(_Config config) {
    final seconds = config.timeout?.inSeconds ?? 0;
    print(seconds);
  }

  void guarded(_Config config) {
    final timeout = config.timeout;
    if (timeout != null) {
      print(timeout.inSeconds);
    }
  }

  void patternMatch(_Config config) {
    if (config.timeout case final timeout?) {
      print(timeout.inSeconds);
    }
  }
}

// ⚠️ Edge cases where the lint intentionally does NOT trigger
class EdgeCases {
  // `Map.operator []` is declared nullable whatever the map holds, so `!` is
  // the idiomatic way to read an entry you know is present.
  void mapIndex(Map<String, String> translations) {
    print(translations['title']!.toUpperCase());
  }

  // `!=` is a comparison operator, not the null-assertion operator.
  void notEquals(int a, int b) {
    if (a != b) print(a);
  }

  // `!` prefixed is boolean negation.
  void negation(bool enabled) {
    if (!enabled) print('off');
  }

  // Postfix `++`/`--` are also PostfixExpressions, but not null assertions.
  void increment() {
    var i = 0;
    i++;
    print(i);
  }

  // A `!` inside a pattern is a NullAssertPattern, not the postfix operator.
  void nullAssertPattern((int?,) record) {
    var (x!,) = record;
    print(x);
  }
}
