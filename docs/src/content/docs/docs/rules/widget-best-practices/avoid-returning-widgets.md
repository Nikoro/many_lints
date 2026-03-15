---
title: avoid_returning_widgets
description: "Extract widget helper methods into separate widget classes"
sidebar:
  label: avoid_returning_widgets
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule warns when a function, method, or getter returns a `Widget`. Building widgets inside helper methods is a common Flutter anti-pattern because the framework cannot optimize rebuilds for code that lives outside of a proper widget class.

## Why use this rule

When you extract UI into a `_buildHeader()` method instead of a `_Header` widget class, Flutter treats the entire parent widget as a single unit. It cannot skip rebuilding the header when only something else changed. Proper widget classes give Flutter the information it needs to do fine-grained rebuilds, which directly improves performance in complex UIs.

**See also:** [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)

## Don't

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildHeader(), _body]);
  }

  // Helper method returning a widget
  Widget _buildHeader() => const Text('Header');

  // Getter returning a widget
  Widget get _body => const Text('Body');
}
```

## Do

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(children: [_Header(), _Body()]);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => const Text('Header');
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) => const Text('Body');
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_returning_widgets: false
```
