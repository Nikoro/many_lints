---
title: always_remove_listener
description: "Ensure every addListener() has a matching removeListener() in dispose()."
sidebar:
  label: always_remove_listener
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Resource Management</span>

Flags `addListener()` calls in State lifecycle methods (`initState`, `didUpdateWidget`, `didChangeDependencies`) that do not have a matching `removeListener()` call in `dispose()`. Missing removal causes memory leaks when the Listenable outlives the widget.

## Why use this rule

Every `addListener()` on a `ChangeNotifier`, `ValueNotifier`, or `AnimationController` creates a strong reference to the callback. If the listener is not removed in `dispose()`, the callback (and everything it captures) stays in memory even after the widget is unmounted. This rule ensures every add has a matching remove with the same target and callback.

**See also:** [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) | [removeListener](https://api.flutter.dev/flutter/foundation/ChangeNotifier/removeListener.html)

## Don't

```dart
class _BadState extends State<BadWidget> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _counter.addListener(_onChanged); // No matching removeListener
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class _GoodState extends State<GoodWidget> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _counter.addListener(_onChanged);
  }

  @override
  void dispose() {
    _counter.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      always_remove_listener: false
```
