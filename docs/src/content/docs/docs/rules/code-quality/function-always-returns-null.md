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

A lookup whose real return was removed in a refactor and never put back:

```dart
class SessionStore {
  final Map<String, String> _tokens = {};

  String? tokenFor(String userId) {
    if (userId.isEmpty) return null;
    if (!_tokens.containsKey(userId)) return null;
    return null; // the read was lost; every caller null-checks for nothing
  }
}
```

## Do

Return the value the signature promises:

```dart
class SessionStore {
  final Map<String, String> _tokens = {};

  String? tokenFor(String userId) {
    if (userId.isEmpty) return null;
    return _tokens[userId];
  }
}
```

Or, if the function genuinely produces nothing, say so in the type:

```dart
class SessionStore {
  final Map<String, String> _tokens = {};

  void forget(String userId) {
    _tokens.remove(userId);
  }
}
```

### A bare `return;` counts as null

In a nullable-returning function `return;` yields `null`, so this reports too — the mix of styles is often what hid the problem:

```dart
class Draft {
  String? _title;

  String? titleOrNull() {
    if (_title == null) return;
    return null;
  }
}
```

## Known limitations

**`@override` methods are skipped.** An override must keep the inherited signature, so the author may have no freedom to change it.

**`async` and generator bodies are skipped.** Their declared type wraps the value — `Future<String?>` — so "every return is null" does not carry the same meaning, and a `Future<String?>` returning null is a normal "not found".

**The return type must be written out.** An omitted annotation is inferred as `Null`, which the analyzer surfaces on its own terms, so this rule only reads types the author typed.

**A function with no `return` at all is not reported.** The analyzer already covers that with `body_might_complete_normally_nullable`.

**Returns inside a nested closure belong to that closure**, not to the enclosing function.

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
