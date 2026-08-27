---
title: function_always_returns_same_value
description: "Flag a function whose every return yields the same constant"
sidebar:
  label: function_always_returns_same_value
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a function where every `return` yields the same constant, so the branching around them decides nothing.

## Why use this rule

Whatever the caller passes, the answer is fixed. Either a branch was meant to return something else and does not — the usual case, and a silent one — or the function should be a constant and its parameters dropped.

## Don't

A permission check where one branch was never filled in:

```dart
class Document {
  const Document({required this.ownerId, required this.isPublic});

  final String ownerId;
  final bool isPublic;
}

bool canEdit(Document document, String userId) {
  if (document.ownerId == userId) return true;
  if (document.isPublic) return true;
  return true; // meant to be false — every caller is now an editor
}
```

## Do

```dart
bool canEdit(Document document, String userId) {
  if (document.ownerId == userId) return true;
  if (document.isPublic) return true;
  return false;
}
```

## Known limitations

**Only literal constants are compared.** `true`, `3`, `'draft'`, `null` and doubles. A function whose returns are variables, calls or `const` names is not reported, even when they happen to be equal.

**At least two returns are needed.** One return of a constant is an ordinary function.

**A bare `return;` silences it.** So does any return the rule cannot read as a literal — either means it cannot prove one fixed answer. Returns inside a nested closure belong to that closure, not to the enclosing function.

**Expression bodies are not checked.** `bool canEdit(...) => true;` has one obvious answer already; only block bodies are visited.

**`@override` methods are skipped.** A one-value implementation is a normal way to satisfy an interface.

**Protocol callbacks are skipped.** Some callbacks are *supposed* to return the same value everywhere, because the value is a signal to a framework rather than an answer — `onNotification` must return `false` throughout to let a notification keep bubbling. Never reported: `onNotification`, `shouldRepaint`, `shouldRebuild`, `shouldReclip`, `moveTo`, `visitChildren`, any `on...` method, and any method taking a parameter whose type name ends in `Notification`:

```dart
class ScrollLogger {
  // Not reported: the constant false is the contract.
  bool onScroll(ScrollNotification notification) {
    if (notification.depth == 0) return false;
    return false;
  }
}
```

## Turning this rule off

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  function_always_returns_same_value: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`function_always_returns_null`](/many_lints/docs/rules/code-quality/function-always-returns-null/) — A nullable-returning function whose every path returns null.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
