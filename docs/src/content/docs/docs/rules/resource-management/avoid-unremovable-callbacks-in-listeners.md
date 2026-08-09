---
title: avoid_unremovable_callbacks_in_listeners
description: "Don't pass an inline closure to addListener"
sidebar:
  label: avoid_unremovable_callbacks_in_listeners
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Resource Management</span>

This rule flags a closure literal passed to `addListener`. `removeListener` matches by identity, and a closure creates a new object each time it is evaluated — so the listener can never be removed.

## Why use this rule

`removeListener(theClosure)` compares object identity. A closure literal written at the call site is a different object from any closure you could later pass, so the removal silently does nothing and the listener stays registered.

Two consequences follow. The listener holds its captured scope — usually the whole `State` — alive for as long as the notifier lives, which is a genuine leak. And it keeps firing after disposal, so a `setState` inside it runs against a disposed element.

This pairs with [`always_remove_listener`](/many_lints/docs/rules/resource-management/always-remove-listener/): that rule checks that a removal exists, this one checks that the removal can actually work.

**See also:** [Flutter: ChangeNotifier.removeListener](https://api.flutter.dev/flutter/foundation/ChangeNotifier/removeListener.html)

## Don't

```dart
controller.addListener(() => setState(() {}));   // can never be removed
```

## Do

Give the callback a stable identity:

```dart
void _onChange() => setState(() {});

@override
void initState() {
  super.initState();
  controller.addListener(_onChange);
}

@override
void dispose() {
  controller.removeListener(_onChange);
  super.dispose();
}
```

## Known limitations

Only `addListener` and `addStatusListener` are recognised by default; a project wrapper can be added with `additional_methods`.

A registration with more than one argument is skipped, since this rule is about the add/remove pair specifically.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unremovable_callbacks_in_listeners: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_unremovable_callbacks_in_listeners:
    additional_methods: [addObserver]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `additional_methods` | list of strings | `[]` | Extra registration methods whose counterpart removes by identity |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
