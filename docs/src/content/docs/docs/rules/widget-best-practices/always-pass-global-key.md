---
title: always_pass_global_key
description: "Don't create a GlobalKey inside build"
sidebar:
  label: always_pass_global_key
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `GlobalKey` constructed inside a `build` method.

`build` runs on every rebuild, so the key gets a new identity each time. Flutter matches elements by key, concludes the widget is new, and discards the whole subtree it identifies — form contents, scroll position, animation controllers, focus. Nothing throws; the symptom is a form that clears itself when something unrelated rebuilds.

This rule is in the **`core`** preset, so it is on with `preset: core` and every preset above it. No configuration.

**See also:** [Flutter: GlobalKey](https://api.flutter.dev/flutter/widgets/GlobalKey-class.html)

## Don't

```dart
class MyForm extends StatelessWidget {
  const MyForm({super.key});

  @override
  Widget build(BuildContext context) {
    // New identity every rebuild — the Form's state is thrown away
    final formKey = GlobalKey<FormState>();
    return Form(key: formKey, child: const SizedBox());
  }
}
```

## Do

Hold the key in a `State` field, so it is created once and survives rebuilds. This also means the widget has to be stateful — a `StatelessWidget` has nowhere to keep a key that outlives a rebuild.

```dart
class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey, child: const SizedBox());
  }
}
```

### Local keys are fine

`ValueKey`, `ObjectKey` and the other `LocalKey` subclasses are compared by value, not identity, so creating one in `build` is normal and never reported:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      for (final item in items) Text(item, key: ValueKey(item)),
    ],
  );
}
```

## Known limitations

Only construction inside a method literally named `build` is reported. A `GlobalKey` created in a helper that `build` calls has the same problem and is not detected:

```dart
// Not reported, but just as broken
Widget _field() => Form(key: GlobalKey<FormState>(), child: const SizedBox());
```

## Turning this rule off

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
