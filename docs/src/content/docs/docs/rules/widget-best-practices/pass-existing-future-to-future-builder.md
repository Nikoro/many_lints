---
title: pass_existing_future_to_future_builder
description: "Don't create a new Future inline inside FutureBuilder"
sidebar:
  label: pass_existing_future_to_future_builder
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags a `FutureBuilder` whose `future:` argument creates a new `Future` inline — a method call, a `Future` constructor, or an immediately invoked async closure.

## Why use this rule

`build()` can run many times per second: a parent rebuild, an inherited widget change, an animation tick. Every one of those runs re-evaluates the `future:` argument. If that argument *creates* a future, the `FutureBuilder` sees a brand new object, resets to `ConnectionState.waiting`, and starts over.

The visible symptom is a loading spinner that flickers forever. The invisible one is worse: the underlying work runs again each time, so a network request inside that future can fire on every frame.

The fix is to create the future once and hand the builder the same instance. In a `StatefulWidget` that means a field assigned in `initState`; with a state manager it means a provider or cached value.

**See also:** [FutureBuilder API docs](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)

## Don't

```dart
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    // A new Future on every rebuild — restarts constantly
    future: fetchUserData(),
    builder: (context, snapshot) => Text('${snapshot.data}'),
  );
}
```

## Do

```dart
class _MyWidgetState extends State<MyWidget> {
  late final Future<String> _userData;

  @override
  void initState() {
    super.initState();
    // Created once, survives every rebuild
    _userData = fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userData,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}
```

## Known limitations

The rule reports only expressions that certainly allocate: constructor calls, method invocations, and invoked closures. A bare identifier, a property access, or anything it cannot resolve is treated as an existing instance and left alone. That means a getter which secretly creates a new future on each access (`Future<String> get data => fetch();`) will not be flagged.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`pass_existing_future_to_future_builder: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  pass_existing_future_to_future_builder: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
