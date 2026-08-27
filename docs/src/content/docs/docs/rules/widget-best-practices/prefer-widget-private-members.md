---
title: prefer_widget_private_members
description: "A widget's public API is its constructor"
sidebar:
  label: prefer_widget_private_members
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a public **instance method or getter** declared on a widget class.

A widget's public surface is its constructor — the parameters a parent passes in. Everything else exists to serve `build`, and making it public invites a caller to reach in and drive part of the rendering out of band.

This matters more in Flutter than the general encapsulation argument suggests, because a widget instance is **rebuilt constantly**. A public method sits on an object the framework may discard on the next frame, so whatever a caller does with it cannot be relied upon.

This rule is in the **`pedantic`** preset: it imposes an architecture rather than catching a defect. No configuration.

**See also:** [Flutter: widget classes over helper methods](https://docs.flutter.dev/perf/best-practices)

## Enabling this rule

```yaml
# many_lints.yaml
rules:
  prefer_widget_private_members: true
```

## Don't

```dart
class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  // A caller can reach in and drive part of the rendering.
  void clear() {}

  String get query => '';

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

## Do

Make it private, and move anything a parent genuinely needs into the constructor:

```dart
class SearchBar extends StatelessWidget {
  const SearchBar({required this.query, required this.onClear, super.key});

  // Fields are the constructor's parameters — never reported.
  final String query;
  final VoidCallback onClear;

  void _handleSubmit() {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

### Statics are exempt

A static is not reachable on a widget *instance*, so the rebuild argument does not apply to it. `static Future<T> show(context)` is the documented way to open a dialog or a sheet — on a real app this accounted for 14 of 16 reports:

```dart
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key});

  // Not reported
  static Future<bool?> show(BuildContext context) =>
      showDialog<bool>(context: context, builder: (_) => const ConfirmDialog());

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

### Overrides and test seams are exempt

`@override` names belong to the supertype, and `@visibleForTesting` is a deliberate widening — neither is reported:

```dart
class Chip extends StatelessWidget {
  const Chip({super.key});

  @override
  String toStringShort() => 'Chip';        // not reported: the name is the supertype's

  @visibleForTesting
  int computeWidth() => 0;                 // not reported: a deliberate widening

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

## Known limitations

**Fields are never reported.** A widget's fields are its constructor parameters, and public `final` fields are the idiom the framework itself uses.

**State classes are not checked.** Only classes that are themselves widgets are examined — a `State` subclass and its `initState`/`dispose` are out of scope.

The framework's own hooks — `build`, `createState`, `createElement`, `debugFillProperties`, `debugDescribeChildren`, `toStringShort`, `toString`, `noSuchMethod` — cannot be private and are always exempt. Operators are skipped too.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  prefer_widget_private_members: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_recursive_widget_calls`](/many_lints/docs/rules/widget-best-practices/avoid-recursive-widget-calls/) — Don't build a widget from inside its own build method.
- [`prefer_single_widget_per_file`](/many_lints/docs/rules/widget-best-practices/prefer-single-widget-per-file/) — Keep one public widget per file for better organization.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
