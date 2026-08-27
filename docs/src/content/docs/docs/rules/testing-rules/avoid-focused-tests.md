---
title: avoid_focused_tests
description: "Detect tests focused with solo:, which silences their siblings"
sidebar:
  label: avoid_focused_tests
---

<span class="rule-badge rule-badge--version">v1.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Warns when a test or group is focused with `solo: true`. A soloed test silences every sibling in the same file — they are not reported as skipped, they are never considered, and the run still exits zero.

`solo` is a debugging aid. The defect is committing it, and the diff looks like nothing.

## Don't

```dart
void main() {
  // Every other test in this file now silently does not run.
  test('the one I am debugging', () {
    expect(parse(input), equals(expected));
  }, solo: true);

  test('handles an empty manifest', () {
    expect(parse(''), isEmpty);
  });
}
```

A group focus does the same thing at group scope:

```dart
void main() {
  group('upload', () {
    test('retries once', () {});
  }, solo: true);

  group('download', () {
    // Never runs.
    test('streams to disk', () {});
  });
}
```

## Do

Narrow the run from the command line. It leaves no trace in the source, so it
cannot be committed by accident:

```dart
void main() {
  test('the one I am debugging', () {
    expect(parse(input), equals(expected));
  });

  test('handles an empty manifest', () {
    expect(parse(''), isEmpty);
  });
}
```

```bash
dart test --name 'the one I am debugging'
dart test test/upload_test.dart
flutter test --plain-name 'the one I am debugging'
```

### Never reported

`solo: false` is the default written out, and suppresses nothing:

```dart
void main() {
  test('runs like any other', () {}, solo: false);
}
```

There is deliberately no option to permit a focus. Unlike a skip, it has no
documented-and-therefore-tolerable form — a reason string would not make the
other tests run.

**See also:** [package:test](https://pub.dev/packages/test) | [eslint-plugin-jest: no-focused-tests](https://github.com/jest-community/eslint-plugin-jest/blob/main/docs/rules/no-focused-tests.md)

## Turning this rule off

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended`, `preset: opinionated` or `preset: pedantic`. Add it to
`preset: core` with `avoid_focused_tests: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_focused_tests: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_skipped_tests`](/many_lints/docs/rules/testing-rules/avoid-skipped-tests/) — Detect tests, groups and libraries switched off in place.
- [`avoid_misused_test_matchers`](/many_lints/docs/rules/testing-rules/avoid-misused-test-matchers/) — Detect test matchers used with incompatible value types.
- [`format_test_name`](/many_lints/docs/rules/testing-rules/format-test-name/) — Hold test descriptions to a house pattern.
- [`prefer_correct_test_file_name`](/many_lints/docs/rules/testing-rules/prefer-correct-test-file-name/) — Name test files so the runner actually runs them.
