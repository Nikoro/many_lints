---
title: prefer_use_prefix
description: "Custom hooks should start with the 'use' prefix."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_use_prefix
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Hook Rules</span>

Flags functions and methods that call hooks internally but do not follow the `use` prefix naming convention. Custom hooks must start with `use` (or `_use` for private functions) so that the hooks framework and other lint rules can identify them as hooks.

## Why use this rule

The `use` prefix is a critical convention in the hooks ecosystem. Without it, lint rules like `avoid_conditional_hooks` cannot detect that a function is a hook, leading to missed warnings. Consistent naming also helps developers immediately recognize hook functions in code review.

**See also:** [flutter_hooks - Custom hooks](https://pub.dev/packages/flutter_hooks#custom-hooks)

## Don't

```dart
// Top-level function calling hooks without 'use' prefix
String myCustomHook() {
  return useMemoized(() => 'hello');
}

// Private function without '_use' prefix
int _myPrivateHook() {
  return useState(0);
}

class BadWidget extends HookWidget {
  int _fetchData() {
    return useState(42);
  }

  @override
  Widget build(BuildContext context) {
    final data = _fetchData();
    return Text('$data');
  }
}
```

## Do

```dart
// Top-level function with 'use' prefix
String useCustomHook() {
  return useMemoized(() => 'hello');
}

// Private function with '_use' prefix
int _usePrivateHook() {
  return useState(0);
}

class GoodWidget extends HookWidget {
  int _useData() {
    return useState(42);
  }

  @override
  Widget build(BuildContext context) {
    final data = _useData();
    return Text('$data');
  }
}

// Regular functions that don't call hooks need no prefix:
int regularFunction() => 42;
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_use_prefix: false
```
