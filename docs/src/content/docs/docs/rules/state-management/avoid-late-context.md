---
title: avoid_late_context
description: "Don't read BuildContext in a late field initializer"
sidebar:
  label: avoid_late_context
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">State Management</span>

This rule flags a `late` field inside a `State` whose initializer reads `context`. The value is computed once, at an unpredictable moment, and then never updates.

## Why use this rule

A `late` field initializes on first access. Inside a `State` that is usually during `build`, but nothing guarantees it — if the field is first touched from `initState`, the inherited-widget lookup runs before the element is mounted and throws.

The quieter problem is worse. A `late` field initializes exactly **once**. A value derived from `Theme.of(context)` or `MediaQuery.of(context)` freezes at whatever it was on first access and then ignores every later change: a theme switch, a rotation, a locale change, a parent rebuilding with new data. The UI keeps rendering stale values with nothing to indicate why.

Inherited widgets are designed to be read where they can be re-read — in `build`, or in `didChangeDependencies` when the value must be cached.

**See also:** [Flutter: BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html), [State.didChangeDependencies](https://api.flutter.dev/flutter/widgets/State/didChangeDependencies.html)

## Don't

```dart
class _MyState extends State<MyWidget> {
  late final theme = Theme.of(context);   // frozen after first access
}
```

## Do

Read it in `build`, where it re-reads on every rebuild:

```dart
class _MyState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text('hi', style: theme.textTheme.bodyMedium);
  }
}
```

When the value really must be cached, use `didChangeDependencies`, which Flutter calls again whenever an inherited dependency changes:

```dart
class _MyState extends State<MyWidget> {
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
  }
}
```

## Known limitations

Only fields inside a `State` are checked, since elsewhere `context` is not the ambient widget context this rule is about. Classes that act as state without extending `State` can be included with the shared [`state_base_classes`](/many_lints/docs/configuration/) option.

Static fields are skipped, and so are `late` fields with no initializer — those are assigned explicitly, where the author controls the timing.

The initializer must mention `context` by name and resolve to a `BuildContext`, so an unrelated local named `context` does not trigger the rule.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_late_context: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Projects with a state abstraction that does not extend Flutter's `State` can
opt that base class into this rule:

```yaml
rules:
  avoid_late_context:
    state_base_classes: [AppState]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state_base_classes` | list of strings | `[]` | Additional non-`State` base classes whose subclasses should be treated as state classes |
