---
title: pass_existing_future_to_future_builder
description: "Don't create a new Future inline inside FutureBuilder"
sidebar:
  label: pass_existing_future_to_future_builder
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `FutureBuilder` whose `future:` argument creates a new `Future` — a method call, a `Future` constructor, or an immediately invoked async closure.

`build()` can run many times per second: a parent rebuild, an inherited widget change, an animation tick. Every one re-evaluates the `future:` argument. If that argument *creates* a future, the builder sees a brand new object, resets to `ConnectionState.waiting`, and starts over.

The visible symptom is a spinner that flickers forever. The invisible one is worse: the underlying work runs again each time, so a network request inside that future can fire on every frame.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended` and every preset above it. No configuration.

**See also:** [FutureBuilder API docs](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)

## Don't

```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    // A new Future on every rebuild — restarts, and re-fetches, constantly
    future: fetchUserData(),
    builder: (context, snapshot) => Text('${snapshot.data}'),
  );
}
```

## Do

Create it once in `initState` and hand the builder the same instance:

```dart
class _ProfilePageState extends State<ProfilePage> {
  late final Future<String> _userData;

  @override
  void initState() {
    super.initState();
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

### When the future depends on a widget property

`initState` runs once, so a future keyed to a property has to be rebuilt when that property changes — which is exactly what `didUpdateWidget` is for:

```dart
class _ProfilePageState extends State<ProfilePage> {
  late Future<String> _userData;

  @override
  void initState() {
    super.initState();
    _userData = fetchUserData(widget.userId);
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _userData = fetchUserData(widget.userId);
    }
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

### The other shapes that allocate

All three of these are reported, for the same reason:

```dart
// Don't
FutureBuilder<void>(
  future: Future.delayed(const Duration(seconds: 1)),
  builder: (context, snapshot) => const SizedBox(),
);

FutureBuilder<int>(
  future: (() async => 1)(),
  builder: (context, snapshot) => const SizedBox(),
);
```

Parentheses and a `!` do not hide the call: `future: (fetchUserData())!` is still reported.

## Known limitations

Only expressions that certainly allocate are reported: constructor calls, method invocations, and invoked closures. A bare identifier, a property access, a ternary, or anything unresolved is treated as an existing instance and left alone.

That means a getter which secretly creates a new future on each access is **not** flagged, even though it has the same problem:

```dart
// Not reported, but restarts on every rebuild all the same
Future<String> get data => fetchUserData();

Widget build(BuildContext context) => FutureBuilder<String>(
      future: data,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
```

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  pass_existing_future_to_future_builder: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`pass_existing_stream_to_stream_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-stream-to-stream-builder/) — Don't create a new Stream inline inside StreamBuilder.
- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
