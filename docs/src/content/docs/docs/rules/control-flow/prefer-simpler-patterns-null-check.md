---
title: prefer_simpler_patterns_null_check
description: "Suggest simpler null-check patterns in if-case expressions"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_simpler_patterns_null_check
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an if-case pattern that spells a null check as `!= null && final x` where Dart has a shorter form that means the same thing.

Two shapes are reported:

- `!= null && final x` — the postfix `?` in `final x?` already binds only when the value is non-null.
- `!= null && final String x` — the type annotation is non-nullable, so the `!= null` was already implied.

**See also:** [Patterns](https://dart.dev/language/patterns)

## Don't

Reading a nullable field through an if-case, then testing it for null on the way in:

```dart
class Session {
  const Session(this.token);

  final String? token;
}

void authorize(Session session) {
  if (session.token case != null && final token) {
    print('Bearer $token');
  }
}
```

The typed form has the same redundancy — `String` already excludes null:

```dart
class Session {
  const Session(this.token);

  final String? token;
}

void authorize(Session session) {
  if (session.token case != null && final String token) {
    print('Bearer $token');
  }
}
```

## Do

The quick fix rewrites both. `final token?` binds only when the value is non-null:

```dart
class Session {
  const Session(this.token);

  final String? token;
}

void authorize(Session session) {
  if (session.token case final token?) {
    print('Bearer $token');
  }
}
```

And the typed form drops the check, keeping the annotation:

```dart
class Session {
  const Session(this.token);

  final String? token;
}

void authorize(Session session) {
  if (session.token case final String token) {
    print('Bearer $token');
  }
}
```

## Known limitations

Only `!= null && <binding>` is reported, and only when the right operand binds a
variable. These stay as they are:

```dart
class Session {
  const Session(this.token);

  final String? token;
}

void checks(Session session, int value) {
  // Nothing is bound, so there is no shorter form.
  if (session.token case != null) {
    print('signed in');
  }

  // An `||` is not the same test, and is left alone.
  if (session.token case != null || '') {
    print('either');
  }

  // No null check involved.
  if (value case > 0 && < 10) {
    print('in range');
  }
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_simpler_patterns_null_check: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_simpler_patterns_null_check: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_unused_after_null_check`](/many_lints/docs/rules/control-flow/avoid-unused-after-null-check/) — A variable null-checked but never used in the guarded branch.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
