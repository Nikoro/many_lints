---
title: avoid_ref_watch_outside_build
description: "Subscribe only in build; read once everywhere else"
sidebar:
  label: avoid_ref_watch_outside_build
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

This rule flags a **subscribing provider read** outside a `build()` method — for example in `initState`, `dispose`, a helper method, or an event handler callback.

It covers both ecosystems, because the mistake is identical in each:

| | Subscribing (flagged outside `build`) | One-off (correct outside `build`) |
|---|---|---|
| **Riverpod** | `ref.watch(...)` | `ref.read(...)` |
| **package:provider** | `context.watch<T>()` | `context.read<T>()` |

## Why use this rule

A subscribing read ties a listener to the lifecycle of a build. Called anywhere else it creates a subscription the framework does not manage: it can fire after the widget is gone, rebuild at surprising moments, or simply leak.

With **package:provider this is not a smell but a crash** — `context.watch<T>()` throws outright when called from `initState`, so the rule catches a runtime failure rather than a style problem.

The correct alternative depends on intent. For a one-off read in a callback, use `ref.read` / `context.read<T>()`. To react to provider changes with a side effect (navigation, a snackbar), use `ref.listen` inside `build`.

This rule is the counterpart to [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/): together they express the rule that subscribing belongs in `build` and reading once belongs outside it.

**See also:** [Riverpod refs](https://riverpod.dev/docs/concepts2/refs), [provider: read vs watch](https://pub.dev/packages/provider)

## Don't

Seeding a text field from a provider in `initState`. `watch` here registers a
subscription no build owns, so it fires at times the widget cannot handle — and
under `package:provider` it does not even get that far, because
`context.watch<T>()` throws when called from `initState`:

```dart
final userNameProvider = StateProvider<String>((ref) => '');

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.watch(userNameProvider); // LINT
  }

  @override
  Widget build(BuildContext context) => TextField(controller: _controller);
}
```

A handler that subscribes is the same mistake, one lifecycle later:

```dart
class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  void _onPayPressed() {
    final total = ref.watch(cartTotalProvider); // LINT
    Navigator.of(context).pushNamed('/pay', arguments: total);
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _onPayPressed,
    child: const Text('Pay'),
  );
}
```

## Do

Read once where you want the value now, and subscribe in `build`:

```dart
final userNameProvider = StateProvider<String>((ref) => '');

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(userNameProvider);
  }

  @override
  Widget build(BuildContext context) => TextField(controller: _controller);
}
```

```dart
class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  void _onPayPressed() {
    final total = ref.read(cartTotalProvider);
    Navigator.of(context).pushNamed('/pay', arguments: total);
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _onPayPressed,
    child: const Text('Pay'),
  );
}
```

### Reacting to a change with a side effect

When you wanted the *change*, not the value, `ref.listen` is what you were
reaching for — and it belongs in `build`:

```dart
class _OrderPageState extends ConsumerState<OrderPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen(orderStatusProvider, (previous, next) {
      if (next == OrderStatus.shipped) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your order has shipped')),
        );
      }
    });

    return const SizedBox();
  }
}
```

## Known limitations

The check descends into closures declared outside `build`, since a closure
written in `initState` subscribes just as wrongly. A closure declared *inside*
`build` — `onPressed: () => ref.watch(...)` — is under the build method and is
not reported by this rule.

The two ecosystems are told apart by the **receiver's resolved type**, not its
name, so `widgetContext.watch<T>()` is caught under any receiver name while a
field of some unrelated class you happened to call `ref` is not.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_ref_watch_outside_build: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_ref_watch_outside_build: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/) — Subscribe in build; do not read once.
- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
