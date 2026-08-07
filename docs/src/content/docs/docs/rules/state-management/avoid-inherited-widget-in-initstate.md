---
title: avoid_inherited_widget_in_initstate
description: "Don't look up inherited widgets inside initState"
sidebar:
  label: avoid_inherited_widget_in_initstate
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">State Management</span>

This rule flags `SomeInheritedWidget.of(context)` and `.maybeOf(context)` calls inside a `State`'s `initState` method — including `Theme.of`, `MediaQuery.of`, `Navigator.of`, and any custom `InheritedWidget`.

## Why use this rule

Those lookups are backed by `dependOnInheritedWidgetOfExactType`, which is not valid during `initState`. At that point the element is not fully mounted, so the call either throws outright or silently registers a dependency that never delivers updates. Either way the widget will not rebuild when the theme, media query, or locale changes.

`didChangeDependencies` exists exactly for this: it runs once immediately after `initState`, and again every time an inherited dependency changes.

**See also:** [State.initState docs](https://api.flutter.dev/flutter/widgets/State/initState.html) | [State.didChangeDependencies docs](https://api.flutter.dev/flutter/widgets/State/didChangeDependencies.html)

## Don't

```dart
class _MyWidgetState extends State<MyWidget> {
  late final Color _color;

  @override
  void initState() {
    super.initState();
    // Not valid here — throws or never updates
    _color = Theme.of(context).primaryColor;
  }
}
```

## Do

```dart
class _MyWidgetState extends State<MyWidget> {
  late Color _color;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Valid here, and re-runs when the theme changes
    _color = Theme.of(context).primaryColor;
  }
}
```

## Known limitations

The check descends into closures declared inside `initState`, because a closure invoked synchronously fails the same way. A lookup inside a closure that deliberately escapes `initState` — for example one passed to `WidgetsBinding.instance.addPostFrameCallback` — runs after mounting and is therefore safe, but will still be reported. Suppress those with `// ignore: many_lints/avoid_inherited_widget_in_initstate`.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_inherited_widget_in_initstate: false
```
