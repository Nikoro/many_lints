---
title: function_always_returns_null
description: "A nullable-returning function whose every path returns null"
sidebar:
  label: function_always_returns_null
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a function declared with a nullable return type whose every `return` yields `null`. No caller can ever receive a value, yet every caller is forced to null-check.

## Why use this rule

A function typed `String?` promises that a `String` is sometimes possible. When every path returns `null`, that promise is false: the nullable type is pure overhead, spreading null checks through the callers for a value that never arrives.

In practice this is almost always a leftover — an unfinished implementation, or a refactor that removed the real return and left the signature behind. Either way the declaration and the body disagree, and the body is the one telling the truth.

**See also:** [Dart: understanding null safety](https://dart.dev/null-safety/understanding-null-safety)

## Don't

```dart
String? lookup(String key) {
  if (key.isEmpty) return null;
  return null;              // nothing can ever come back
}
```

## Do

Return the value the signature promises:

```dart
String? lookup(String key) {
  if (key.isEmpty) return null;
  return _cache[key];
}
```

Or, if the function genuinely produces nothing, say so in the type:

```dart
void record(String key) {
  _log.add(key);
}
```

## Known limitations

`@override` methods are skipped: an override must keep the inherited signature, so the author may have no freedom to change it.

`async` and generator bodies are skipped too. Their declared type wraps the value — `Future<String?>` — so "every return is null" does not carry the same meaning.

A function with no `return` at all is not this rule's concern; the analyzer already reports `body_might_complete_normally_nullable` for it. Nor is a bare `return;`, which the analyzer flags as `return_without_value`. Returns inside a nested closure are attributed to that closure, not the enclosing function.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  function_always_returns_null: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`function_always_returns_same_value`](/many_lints/docs/rules/code-quality/function-always-returns-same-value/) — Flag a function whose every return yields the same constant.
- [`avoid_non_null_assertion`](/many_lints/docs/rules/code-quality/avoid-non-null-assertion/) — Don't assert away null with the ! operator.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
