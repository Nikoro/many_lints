---
title: prefer_widget_private_members
description: "A widget's public API is its constructor"
sidebar:
  label: prefer_widget_private_members
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags a public method or getter declared on a widget class.

This rule is in **no preset**: it imposes an architecture rather than catching a defect.

## Why use this rule

A widget's public surface is its constructor — the parameters a parent passes in. Everything else exists to serve `build`, and making it public invites a caller to reach into the widget and invoke part of its rendering out of band, which is exactly the coupling a widget class prevents.

This matters more in Flutter than the general encapsulation argument suggests, because a widget instance is **rebuilt constantly**. A public method sits on an object the framework may discard on the next frame, so whatever a caller does with it cannot be relied upon.

Three things are deliberately not reported:

- **Fields.** A widget's fields are its constructor parameters, and public `final` fields are the idiom the framework itself uses.
- **Static members.** A static is not reachable on a widget instance, so the rebuild argument does not apply. `static Future<T> show(context)` is the documented way to open a dialog or a sheet — on a real app this accounted for 14 of 16 reports.
- **`@override` and `@visibleForTesting`.** The first belongs to the supertype; the second is a deliberate widening.

**See also:** [Flutter: widget classes over helper methods](https://docs.flutter.dev/perf/best-practices)

## Don't

```dart
class BadWidget extends StatelessWidget {
  const BadWidget({super.key});

  // A caller can reach in and drive part of the rendering.
  void refresh() {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

## Do

```dart
class GoodWidget extends StatelessWidget {
  const GoodWidget({required this.title, super.key});

  // Fields are the constructor's parameters — never reported.
  final String title;

  void _refresh() {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class GoodDialog extends StatelessWidget {
  const GoodDialog({super.key});

  // A static entry point is exempt.
  static Future<void> show(BuildContext context) async {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_widget_private_members: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
