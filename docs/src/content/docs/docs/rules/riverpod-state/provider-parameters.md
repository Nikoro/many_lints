---
title: provider_parameters
description: "Family provider arguments must have stable equality, or the provider is recreated on every rebuild."
sidebar:
  label: provider_parameters
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags an argument passed to a family provider that has no stable equality — a non-const collection literal, a closure, or an instance of a class that does not override `==`.

## Why use this rule

Riverpod caches one provider instance per family argument, keyed by `==`. An argument that allocates a new object on every build never compares equal to the previous one, so Riverpod treats each rebuild as a brand-new provider: the old one is disposed, state is lost, and any network request behind it runs again. The symptom is an infinite rebuild loop or a widget that never keeps its data — both hard to trace back to the argument.

**See also:** [Riverpod families](https://riverpod.dev/docs/concepts2/family)

## Don't

### A collection literal as the argument

A filter screen passing the selected tags straight into a family. Every rebuild
allocates a fresh list, so Riverpod disposes the previous provider and refetches:

```dart
final searchProvider =
    FutureProvider.family<List<Product>, List<String>>((ref, tags) => search(tags));

class ResultsView extends ConsumerWidget {
  const ResultsView({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider(['sale', 'new'])); // LINT
    return Text('${results.valueOrNull?.length}');
  }
}
```

### A closure as the argument

Two closures with identical bodies are never equal, so this family is recreated
on every single build:

```dart
final sortedProvider =
    Provider.family<List<Product>, int Function(Product, Product)>(
      (ref, compare) => [...ref.watch(catalogProvider)]..sort(compare),
    );

class SortedList extends ConsumerWidget {
  const SortedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      sortedProvider((a, b) => a.price.compareTo(b.price)), // LINT
    );
    return Text('${items.length}');
  }
}
```

### A value class that forgot `==`

The most common one, because the code looks entirely reasonable:

```dart
class DateRange {
  DateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;
}

final reportProvider =
    FutureProvider.family<Report, DateRange>((ref, range) => loadReport(range));

class ReportView extends ConsumerWidget {
  const ReportView({super.key, required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(DateRange(from, to))); // LINT
    return Text('${report.valueOrNull?.total}');
  }
}
```

## Do

Pass something whose `==` is stable: a primitive, a `const` value, or a class
that implements equality.

```dart
// const collections and const instances are canonicalized
ref.watch(searchProvider(const ['sale', 'new']));

// primitives compare by value
ref.watch(productProvider(productId));
```

Give the parameter class real equality — by hand, or with a `@freezed` /
`Equatable` value type:

```dart
class DateRange {
  const DateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

final reportProvider =
    FutureProvider.family<Report, DateRange>((ref, range) => loadReport(range));

class ReportView extends ConsumerWidget {
  const ReportView({super.key, required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(DateRange(from, to)));
    return Text('${report.valueOrNull?.total}');
  }
}
```

When the parameter is a record, equality comes for free — records compare
structurally:

```dart
final reportProvider =
    FutureProvider.family<Report, ({DateTime from, DateTime to})>(
      (ref, range) => loadReport(range.from, range.to),
    );

// Stable: the record compares by field.
ref.watch(reportProvider((from: from, to: to)));
```

## Known limitations

Only a direct call on something typed as a family is checked —
`myProvider(arg)`. Declaring the family (`Provider.family<T, Arg>(...)`) is
never reported, since its argument is the create callback rather than a family
parameter.

The `==` check only asks whether an override exists, not whether it is correct.
A class that declares `operator ==` and compares by identity anyway passes.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`provider_parameters: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  provider_parameters: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`missing_provider_scope`](/many_lints/docs/rules/riverpod-state/missing-provider-scope/) — Flutter applications using Riverpod must have a ProviderScope at the root of the widget tree.
- [`async_value_nullable_pattern`](/many_lints/docs/rules/riverpod-state/async-value-nullable-pattern/) — Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
