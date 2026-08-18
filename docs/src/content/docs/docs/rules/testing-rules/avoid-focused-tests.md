---
title: avoid_focused_tests
description: "Detect tests focused with solo:, which silences their siblings"
sidebar:
  label: avoid_focused_tests
---

<span class="rule-badge rule-badge--version">v1.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Testing Rules</span>

Warns when a test or group is focused with `solo:`. This is the mirror of
[`avoid_skipped_tests`](/many_lints/docs/rules/testing-rules/avoid-skipped-tests/)
and the more dangerous half.

## Why use this rule

A skipped test silences itself, and the runner's summary at least counts it. A
soloed test silences *every sibling in the file* — they are not reported as
skipped so much as never considered, and the run still exits zero. One word
turns a file of forty assertions into a file of one.

`solo` is a debugging aid: it is how you narrow a run while chasing a single
failure. The defect is committing it, and nobody intends to, which is exactly
why it needs a rule rather than a code-review habit. The diff looks like
nothing.

There is deliberately no option to permit it. Unlike a skip, a focus has no
documented-and-therefore-tolerable form — a reason string would not make the
other tests run.

**See also:** [package:test — running one test](https://pub.dev/packages/test#restricting-tests-to-certain-platforms) | [eslint-plugin-jest: no-focused-tests](https://github.com/jest-community/eslint-plugin-jest/blob/main/docs/rules/no-focused-tests.md)

## Don't

```dart
// Every other test in this file now silently does not run.
test('the one I am debugging', () {
  expect(parse(input), equals(expected));
}, solo: true);

// Same at group level.
group('upload', () {
  // ...
}, solo: true);
```

## Do

```dart
// Narrow the run from the command line instead — it leaves no trace in the
// source, so it cannot be committed by accident.
//
//   dart test --name 'the one I am debugging'
//   dart test test/upload_test.dart

test('the one I am debugging', () {
  expect(parse(input), equals(expected));
});
```

`solo: false` is never reported: it is the default written out, and suppresses
nothing.

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
