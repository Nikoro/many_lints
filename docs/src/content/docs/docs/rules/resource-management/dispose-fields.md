---
title: dispose_fields
description: "Ensure State fields with disposal methods are cleaned up in dispose()."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: dispose_fields
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Resource Management</span>

Flags instance fields in `State` subclasses whose type has a `dispose()`, `close()`, or `cancel()` method but the field is not cleaned up in the widget's `dispose()` method. Common types include `TextEditingController`, `FocusNode`, `AnimationController`, `StreamController`, `StreamSubscription`, and `Timer`.

## Why use this rule

Disposable resources that are not cleaned up cause memory leaks. A `TextEditingController` that is never disposed keeps its listeners and internal state alive indefinitely. This rule checks that every field with a cleanup method has a matching call in `dispose()`, catching missing or incomplete cleanup.

**See also:** [State.dispose()](https://api.flutter.dev/flutter/widgets/State/dispose.html) | [Dart lint: cancel_subscriptions](https://dart.dev/tools/linter-rules/cancel_subscriptions) | [Dart lint: close_sinks](https://dart.dev/tools/linter-rules/close_sinks)

## Don't

```dart
class _BadState extends State<BadWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _streamController = StreamController<int>();

  // No dispose() method -- all fields leak

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _IncompleteState extends State<IncompleteWidget> {
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();

  @override
  void dispose() {
    _controller1.dispose();
    // _controller2 is missing!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class _GoodState extends State<GoodWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _StreamState extends State<StreamWidget> {
  final _streamController = StreamController<int>();

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

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
      dispose_fields: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  dispose_fields:
    additional_cleanup_methods: [release, shutdown]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cleanup_methods` | list of strings | `[dispose, close, cancel]` | **Replaces** the cleanup method names the rule looks for |
| `additional_cleanup_methods` | list of strings | `[]` | **Extends** whichever list applies |

Order matters: it is the priority used when a type declares more than one
cleanup method. Names added via `additional_cleanup_methods` are appended, so a
project's own `release()` is only chosen when the type declares no standard
cleanup method.

Both options apply to detection *and* recognition — a method listed here counts
both as "this field needs cleaning up" and as "this call cleans it up".

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
