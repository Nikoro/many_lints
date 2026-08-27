---
title: use_existing_destructuring
description: "Add properties to an existing destructuring instead of accessing them directly."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_existing_destructuring
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

This rule flags `user.email` when a destructuring of `user` already exists earlier in the same scope. The property belongs in that pattern; the quick fix adds it there and rewrites the access to the new variable.

## Why use this rule

Once a destructuring exists, it is the place a reader looks to see what this function uses from the object. A property read that bypasses it hides one field from that list, and the next person adding a field has to decide, for no reason, which of the two styles to follow.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
class Session {
  const Session({
    required this.userId,
    required this.token,
    required this.expiresAt,
  });

  final String userId;
  final String token;
  final DateTime expiresAt;
}

void audit(Session session) {
  final Session(:userId) = session;

  print(userId);
  print(session.token);        // LINT: add :token to the destructuring
  print(session.expiresAt);    // LINT: add :expiresAt too
}
```

## Do

```dart
void audit(Session session) {
  final Session(:userId, :token, :expiresAt) = session;

  print(userId);
  print(token);
  print(expiresAt);
}
```

## Records too

The same applies to a record destructuring:

```dart
// Don't
void describe(({int width, int height}) size) {
  final (:width) = size;
  print('$width x ${size.height}');    // LINT
}

// Do
void describe(({int width, int height}) size) {
  final (:width, :height) = size;
  print('$width x $height');
}
```

## Known limitations

The rule reports only where adding the field to the pattern would be a
behaviour-preserving edit. It stays silent when:

**No destructuring exists.** Plain `session.token` in a function that never destructures `session` is fine — this rule does not ask you to start.

**The access comes first.** A read *above* the destructuring cannot use a variable that is not bound yet.

**It is a method call, not a property.** `session.refresh()` is a call; patterns bind fields and getters, not invocations.

**It is an assignment target.** `session.token = 'x'` writes through the object, which a destructured copy cannot do.

**The receiver is not a local variable.** A top-level or field object (`globalSession.token`), or a call result (`currentSession().token`), is left alone.

**The access is inside a closure.** A property read inside a `() { ... }` runs later, so the rule treats it as a separate context.

**A different variable is being read.** `final Session(:userId) = a; print(b.token);` touches two objects and is not reported.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  use_existing_destructuring: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  use_existing_destructuring: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_single_field_destructuring`](/many_lints/docs/rules/pattern-matching/avoid-single-field-destructuring/) — Avoid destructuring a single field when direct property access is simpler.
- [`use_existing_variable`](/many_lints/docs/rules/pattern-matching/use-existing-variable/) — Use an existing variable instead of repeating its initializer expression.
- [`avoid_wildcard_cases_with_enums`](/many_lints/docs/rules/pattern-matching/avoid-wildcard-cases-with-enums/) — Keep exhaustiveness checking by listing enum cases explicitly.
- [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) — Use a switch instead of an if-else chain over enum constants.
