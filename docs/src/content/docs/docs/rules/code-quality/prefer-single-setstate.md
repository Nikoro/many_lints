---
title: prefer_single_setstate
description: "Merge multiple setState calls into a single call."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_single_setstate
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

Flags methods in `State` subclasses that contain multiple `setState()` calls at the same scope level. Each `setState()` call schedules a rebuild, so calling it multiple times in the same synchronous method triggers redundant rebuilds that can be avoided by merging all state mutations into a single call.

## Why use this rule

Multiple `setState()` calls in the same method cause Flutter to schedule multiple rebuilds in the same frame. While Flutter coalesces them into one actual rebuild, the pattern is misleading and fragile. Merging mutations into a single `setState()` makes the code clearer and avoids accidental intermediate states if the framework behavior changes.

**See also:** [State.setState()](https://api.flutter.dev/flutter/widgets/State/setState.html)

## Don't

```dart
class _BadState extends State<BadWidget> {
  String _a = '';
  String _b = '';

  void _update() {
    setState(() {
      _a = 'Hello';
    });
    setState(() {
      _b = 'World';
    });
  }

  // Even with code in between:
  void _updateWithGap() {
    setState(() {
      _a = 'Hello';
    });
    debugPrint('between');
    setState(() {
      _b = 'World';
    });
  }
}
```

## Do

```dart
class _GoodState extends State<GoodWidget> {
  String _a = '';
  String _b = '';

  void _update() {
    setState(() {
      _a = 'Hello';
      _b = 'World';
    });
  }
}

// setState in separate closures is fine (different scopes):
void _setup() {
  final callback1 = () {
    setState(() { _data = 'a'; });
  };
  final callback2 = () {
    setState(() { _data = 'b'; });
  };
}

// setState in different methods is fine:
void _update1() {
  setState(() { _data = 'Hello'; });
}
void _update2() {
  setState(() { _data = 'World'; });
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_single_setstate: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Projects with a state abstraction that does not extend Flutter's `State` can
opt that base class into this rule:

```yaml
rules:
  prefer_single_setstate:
    state_base_classes: [AppState]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state_base_classes` | list of strings | `[]` | Additional non-`State` base classes whose subclasses should be treated as state classes |
