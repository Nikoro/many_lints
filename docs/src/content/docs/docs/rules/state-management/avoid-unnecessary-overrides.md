---
title: avoid_unnecessary_overrides
description: "Detect overrides that only delegate to super"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_overrides
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">State Management</span>

Warns when a class or mixin overrides a method, getter, or setter without adding any logic beyond calling `super`. This includes pass-through methods that forward all arguments unchanged, getters that only return `super.getter`, setters that only assign `super.setter`, and abstract redeclarations.

:::note[Overlaps with an SDK rule]
The SDK rule [`unnecessary_overrides`](https://dart.dev/tools/linter-rules/unnecessary_overrides) covers the **method** case. This rule extends it to getters, setters, operator overrides, and abstract redeclarations, which the SDK rule does not check.

It applies the same exemptions as the SDK rule, so an override is **not** reported when it adds a documentation comment, an annotation other than `@override` (such as `@protected` or `@Deprecated`), or a `covariant` parameter — and `noSuchMethod` is never reported. These are legitimate reasons to override a member without changing its body.

Enabling both rules means the method case is reported twice. If that bothers you, disable the SDK rule and keep this one for the wider coverage:

```yaml
# analysis_options.yaml
linter:
  rules:
    unnecessary_overrides: false
```
:::

## Why use this rule

Overrides that only delegate to `super` add visual noise without changing behavior. They make classes harder to scan and can mislead readers into thinking the override does something meaningful. Removing them keeps the codebase lean and makes intentional overrides stand out.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage) | [Dart lint: unnecessary_overrides](https://dart.dev/tools/linter-rules/unnecessary_overrides)

## Don't

Overrides left behind after the body that justified them was removed. Each one
reads like it does something:

```dart
class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('Cart');
}
```

### Getters and setters

The SDK's `unnecessary_overrides` stops at methods. This rule also reports the
accessor forms, which is where they tend to accumulate:

```dart
class TimestampedRepository extends BaseRepository {
  @override
  String get name => super.name;

  @override
  set name(String value) => super.name = value;
}
```

### Abstract redeclarations

Restating an inherited abstract member adds nothing — the subclass already has
to implement it:

```dart
abstract class BaseRepository {
  Future<void> refresh();
}

abstract class CachedRepository extends BaseRepository {
  @override
  Future<void> refresh(); // adds nothing
}
```

## Do

Delete the pass-throughs. Keep an override only when it changes something:

```dart
class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) => const Text('Cart');
}
```

```dart
class TimestampedRepository extends BaseRepository {
  // Adds behaviour — kept.
  @override
  String get name => super.name.toUpperCase();

  @override
  Future<void> refresh() async {
    _lastRefresh = DateTime.now();
    await super.refresh();
  }

  DateTime? _lastRefresh;
}
```

An override with an intentionally empty body is **not** a pass-through — it
suppresses the inherited behaviour, and is left alone:

```dart
class SilentRepository extends BaseRepository {
  // Deliberately does nothing — no super call.
  @override
  Future<void> refresh() async {}
}
```

## Known limitations

The same exemptions the SDK rule applies hold here: an override is **not**
reported when it carries a documentation comment, an annotation other than
`@override` (`@protected`, `@Deprecated`), or a `covariant` parameter — and
`noSuchMethod` is never reported. Those are legitimate reasons to override a
member without changing its body.

A forwarding override only counts as a pass-through when the arguments go
through unchanged. `super.bar(x + 1, y)` is a real override.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_overrides: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_overrides: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_empty_setstate`](/many_lints/docs/rules/state-management/avoid-empty-setstate/) — Don't call setState with an empty callback.
- [`avoid_inherited_widget_in_initstate`](/many_lints/docs/rules/state-management/avoid-inherited-widget-in-initstate/) — Don't look up inherited widgets inside initState.
- [`avoid_late_context`](/many_lints/docs/rules/state-management/avoid-late-context/) — Don't read BuildContext in a late field initializer.
- [`avoid_mounted_in_setstate`](/many_lints/docs/rules/state-management/avoid-mounted-in-setstate/) — Detect mounted checks inside setState callbacks.
