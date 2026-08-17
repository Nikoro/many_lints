---
title: always_pass_global_key
description: "Don't create a GlobalKey inside build"
sidebar:
  label: always_pass_global_key
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags a `GlobalKey` constructed inside a `build` method. `build` runs on every rebuild, so the key gets a new identity each time and Flutter discards the entire subtree it identifies.

## Why use this rule

Flutter matches elements to widgets by key. A `GlobalKey` created in `build` is a different object on every rebuild, so the framework concludes the widget is new: it unmounts the old element, disposes its `State`, and builds a fresh one.

Everything held in that subtree goes with it — form contents, scroll position, animation controllers, focus. The symptom is a form that clears itself or a list that jumps to the top whenever anything unrelated triggers a rebuild. Nothing throws, so it reads as a mysterious UI bug rather than a lifetime mistake.

A `GlobalKey` is meant to be long-lived: created once, stored in a `State` field, and reused across rebuilds.

**See also:** [Flutter: GlobalKey](https://api.flutter.dev/flutter/widgets/GlobalKey-class.html), [When to use keys](https://docs.flutter.dev/development/ui/widgets-intro#keys)

## Don't

```dart
class MyForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<FormState>();   // new identity every rebuild
    return Form(key: key, child: ...);
  }
}
```

## Do

Hold the key in a `State` field so it survives rebuilds:

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey, child: ...);
  }
}
```

Note this also means the widget must be stateful — a `StatelessWidget` has nowhere to keep a key that outlives a rebuild.

## Known limitations

Only construction inside a method named `build` is reported. A `GlobalKey` created in a helper method that `build` calls is not detected, though it has the same problem.

`LocalKey` subclasses such as `ValueKey` and `ObjectKey` are not reported. They are compared by value, not identity, so creating one in `build` is normal and correct.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  always_pass_global_key: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`pass_existing_future_to_future_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-future-to-future-builder/) — Don't create a new Future inline inside FutureBuilder.
- [`pass_existing_stream_to_stream_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-stream-to-stream-builder/) — Don't create a new Stream inline inside StreamBuilder.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
