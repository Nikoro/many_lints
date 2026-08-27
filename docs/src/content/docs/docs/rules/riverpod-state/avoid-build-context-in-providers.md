---
title: avoid_build_context_in_providers
description: "Providers outlive widgets, so they should not receive a BuildContext."
sidebar:
  label: avoid_build_context_in_providers
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags a `BuildContext` parameter on a `@riverpod` provider — either a functional provider or a method of a `@riverpod` class.

## Why use this rule

Providers outlive the widgets that read them. A `BuildContext` held by a provider can easily refer to a widget that has already been unmounted, and using it then throws `dependOnInheritedWidgetOfExactType was called on a defunct widget` — or quietly reads stale inherited data. Passing the *value* you need instead keeps the provider independent of the widget tree, which is also what makes it testable without pumping a widget.

**See also:** [Riverpod families](https://riverpod.dev/docs/concepts2/family)

## Don't

A provider that takes the context so it can read the locale itself. The context
it captured belongs to a widget that may already be gone by the time the
provider rebuilds:

```dart
@riverpod
Future<List<Article>> articles(Ref ref, BuildContext context) { // LINT
  final locale = Localizations.localeOf(context);
  return api.fetchArticles(locale.languageCode);
}
```

Every method of a `@riverpod` class is checked, not just `build` — an action
method that takes a context to show a snackbar afterwards is the same problem:

```dart
@riverpod
class Checkout extends _$Checkout {
  @override
  CheckoutState build() => const CheckoutState.idle();

  Future<void> submit(BuildContext context) async { // LINT
    await api.submit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed')),
    );
  }
}
```

## Do

Pass the *value* the provider needs, and let the family key on it:

```dart
@riverpod
Future<List<Article>> articles(Ref ref, String languageCode) =>
    api.fetchArticles(languageCode);

// At the call site, where a context is legitimately in scope:
class ArticleList extends ConsumerWidget {
  const ArticleList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final articles = ref.watch(articlesProvider(locale.languageCode));
    return Text('${articles.valueOrNull?.length}');
  }
}
```

Let the notifier report the outcome through its state, and let the widget do
the UI work:

```dart
@riverpod
class Checkout extends _$Checkout {
  @override
  CheckoutState build() => const CheckoutState.idle();

  Future<void> submit() async {
    state = const CheckoutState.submitting();
    await api.submit();
    state = const CheckoutState.placed();
  }
}

class CheckoutButton extends ConsumerWidget {
  const CheckoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(checkoutProvider, (previous, next) {
      if (next is CheckoutPlaced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed')),
        );
      }
    });

    return ElevatedButton(
      onPressed: () => ref.read(checkoutProvider.notifier).submit(),
      child: const Text('Place order'),
    );
  }
}
```

## Known limitations

Only `@riverpod` declarations are checked. An ordinary function or class taking
a `BuildContext` is left alone:

```dart
Locale readLocale(BuildContext context) => Localizations.localeOf(context);
```

The parameter type must resolve to exactly `BuildContext`. A subtype, or a
context wrapped in some project-specific holder, is not reported.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_build_context_in_providers: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_build_context_in_providers: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/) — Prevent passing BuildContext to Bloc or Cubit classes.
- [`never_discard_build_context`](/many_lints/docs/rules/widget-best-practices/never-discard-build-context/) — Don't discard a BuildContext parameter with a wildcard.
- [`use_closest_build_context`](/many_lints/docs/rules/widget-best-practices/use-closest-build-context/) — Use the inner BuildContext from builder callbacks, not the outer one.
- [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/) — Subscribe in build; do not read once.
