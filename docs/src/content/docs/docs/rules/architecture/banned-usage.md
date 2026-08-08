---
title: banned_usage
description: "Ban specific members, such as DateTime.now, optionally scoped by directory"
sidebar:
  label: banned_usage
---

<span class="rule-badge rule-badge--version">Unreleased</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Architecture</span>

Flags uses of a member you ban — one method, getter or constructor of a type rather than the whole type. The common need is `DateTime.now()` and `Random()` in code that should take an injected clock or seed.

**This rule reports nothing until you configure it.**

## Why use this rule

`DateTime.now()` is a hidden input. A type that calls it cannot be tested at a chosen moment: you cannot check that a session expires at midnight without either waiting or mocking global state. The same is true of `Random()` — the test that fails once in fifty runs is usually a seed nobody controls.

Injecting a clock fixes both, and this rule is what keeps it fixed. Banning `DateTime.now` inside your domain layer while leaving it available in the composition root puts the constraint exactly where it belongs: the code that decides *when* is allowed to know the time; the code that decides *what* is not.

**See also:** [`package:clock`](https://pub.dev/packages/clock), [Flutter testing guidance](https://docs.flutter.dev/testing/overview)

## Don't

```dart
// in lib/domain/session.dart
//
// With an entry banning 'DateTime.now' in lib/domain/**:
class Session {
  const Session(this.expiresAt);

  final DateTime expiresAt;

  // LINT: cannot be tested without waiting for real time to pass.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

## Do

```dart
// in lib/domain/session.dart
abstract class Clock {
  DateTime now();
}

class Session {
  const Session({required this.expiresAt, required Clock clock})
      : _clock = clock;

  final DateTime expiresAt;
  final Clock _clock;

  bool get isExpired => _clock.now().isAfter(expiresAt);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      banned_usage: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  banned_usage:
    banned:
      - deny: ['DateTime.now', 'Random.new']
        in: ['lib/domain/**']
        message: 'Inject a clock or seed so this stays testable.'
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `banned` | list of maps | `[]` | The entries to enforce. With none, the rule reports nothing |

Each entry accepts:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `deny` | string or list | one of `deny` / `deny_pattern` | Members banned by **exact** match, written `Type.member` or as a bare `member` |
| `deny_pattern` | string or list | one of `deny` / `deny_pattern` | Regular expressions, anchored to the whole member name |
| `in` | list of globs | no | Paths, relative to the package root, where the entry applies. Omit to apply everywhere |
| `message` | string | no | A project-specific explanation appended to the diagnostic |

### Writing member names

`Type.member` matches on the type that **declares** the member, so a subclass cannot slip past: with `Iterable.first` banned, a `List` receiver still reports.

The unnamed constructor is spelled `new`, so `Random.new` bans `Random()` while leaving `Random.secure()` alone.

A bare `member` name bans it on every type. `deny: ['now']` catches `DateTime.now()` and anything else named `now` — prefer the qualified form unless that is really what you mean.

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.

## Related rules

- [`avoid_banned_types`](/many_lints/docs/rules/architecture/avoid-banned-types/) — bans a whole type rather than one of its members
