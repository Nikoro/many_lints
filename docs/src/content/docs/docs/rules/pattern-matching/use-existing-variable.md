---
title: use_existing_variable
description: "Use an existing variable instead of repeating its initializer expression."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_existing_variable
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

When an expression duplicates the initializer of an existing `final` or `const` variable in the same scope, you should reference the variable instead. Repeating the expression creates a maintenance risk where only one copy gets updated during refactoring.

## Why use this rule

Duplicated expressions are easy to introduce and hard to spot during code review. If the expression changes, you need to update every occurrence. Using the existing variable avoids this inconsistency and makes refactoring safer.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
// Repeating an expression that is already stored in a variable
void badPropertyAccess(String value) {
  final isOdd = value.length.isOdd;
  print(value.length.isOdd);
}

// Repeating a method call
void badMethodCall(List<int> list) {
  final copy = list.toList();
  print(list.toList());
}

// Duplicate in a second variable initializer
void badSecondVariable(String value) {
  final a = value.length.isOdd;
  final b = value.length.isOdd;
  print(b);
}
```

## Do

```dart
// Using the existing variable
void goodReuse(String value) {
  final isOdd = value.length.isOdd;
  print(isOdd);
}

// No variable exists for the expression (no lint)
void goodNoVariable(String value) {
  print(value.length.isOdd);
  print(value.length.isOdd);
}

// Different expression (isEven vs isOdd) — no lint
void goodDifferentExpression(String value) {
  final isOdd = value.length.isOdd;
  print(value.length.isEven);
}

// Non-final variable — value may have changed
void goodNonFinal(String value) {
  var isOdd = value.length.isOdd;
  print(value.length.isOdd);
  isOdd = false;
}

// Expression appears before the variable declaration
void goodBeforeDeclaration(String value) {
  print(value.length.isOdd);
  final isOdd = value.length.isOdd;
  print(isOdd);
}

// Inside a nested function (different execution context)
void goodNestedFunction(String value) {
  final isOdd = value.length.isOdd;
  void inner() {
    print(value.length.isOdd);
  }
  inner();
}

// Trivial expressions (literals, identifiers) are not flagged
void goodTrivial() {
  final x = 42;
  print(42);
}

// Re-allocating a resource on purpose — no lint
void goodReallocation(String file) async {
  final old = Database(file);
  await old.close();
  final upgraded = Database(file);
  print(upgraded);
}

// Re-running async work — no lint
void goodRepeatedAwait() async {
  final first = await fetchValue();
  final second = await fetchValue();
  print(first + second);
}
```

## Expressions that are never flagged

Source-text equality cannot distinguish "this value was already computed" from
"this deliberately produces a fresh one", so the rule skips expressions whose
re-evaluation is observable:

| Expression | Why it is skipped |
|------------|-------------------|
| Constructor calls (`Database(file)`, `List<int>.filled(10, 0)`) | Each evaluation allocates a new instance. Reusing the variable could hand back a closed or already-consumed resource. |
| `await` expressions | Re-running async work is a separate operation, and the earlier result may be single-use. |
| Cascades (`[]..add(1)`) | Each evaluation builds and mutates a distinct object. |

This matters most in tests that acquire, release, then re-acquire a resource —
suggesting reuse there would be semantically wrong, not merely noisy.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  use_existing_variable: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  use_existing_variable: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
