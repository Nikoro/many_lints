---
title: prefer_single_widget_per_file
description: "Keep one public widget per file for better organization"
sidebar:
  label: prefer_single_widget_per_file
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule warns when a file contains more than one public widget class. The first public widget is fine, but the second and any subsequent ones trigger the lint. Private widgets (prefixed with `_`) and non-widget classes are not counted.

## Why use this rule

Having multiple public widgets in one file makes them harder to find, harder to test independently, and harder to reason about in code reviews. A one-widget-per-file convention keeps files focused, makes the file system a natural index of your widget library, and ensures that imports pull in exactly what is needed.

**See also:** [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)

## Don't

```dart
// Two public widgets in the same file
class FirstWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('First');
}

// This triggers the lint
class SecondWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('Second');
}
```

## Do

```dart
// first_widget.dart — one public widget per file
class FirstWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('First');
}

// Private helpers are fine in the same file
class _HelperWidget extends StatelessWidget {
  const _HelperWidget();

  @override
  Widget build(BuildContext context) => const Text('Helper');
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_single_widget_per_file: false
```
