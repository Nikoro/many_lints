<p align="center">
  <a href="https://pub.dev/packages/many_lints"><img src="https://raw.githubusercontent.com/nikoro/many_lints/main/logo/logo.webp" width="600"/></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/many_lints">
    <img alt="Pub Package" src="https://tinyurl.com/23wn29m7">
  </a>
  <a href="https://github.com/Nikoro/many_lints/actions">
    <img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/Nikoro/many_lints/ci.yaml?label=build">
  </a>
  <a href="https://github.com/Nikoro/many_lints/actions">
    <img src="https://img.shields.io/badge/coverage-90%25-brightgreen" alt="coverage 90%">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://tinyurl.com/3uf9tzpy">
  </a>
  <a href="https://pub.dev/packages/analyzer">
    <img src="https://img.shields.io/badge/analyzer-10.0.2-blue" alt="analyzer version 10.0.2">
  </a>
</p>

A useful collection of custom lints for Flutter & Dart projects. Uses the new `analysis_server_plugin` system for direct integration with `dart analyze` and IDEs.

## Features

This package provides a set of custom lints to help you write better Flutter code.

## Getting started

> **Requires Dart 3.10+ (Flutter 3.38+)**

Add `many_lints` to the **top-level** `plugins` section in your `analysis_options.yaml` file (NOT under `analyzer:`):

```yaml
plugins:
  many_lints: ^0.2.1
```

That's it — the analysis server will automatically download and resolve the plugin from [pub.dev](https://pub.dev/packages/many_lints). There is no need to add it to your `pubspec.yaml`.

### Local development

For local development or when using many_lints from a cloned repository, use the `path` option:

```sh
git clone https://github.com/Nikoro/many_lints.git /path/to/many_lints
```

```yaml
plugins:
  many_lints:
    path: /path/to/many_lints
```

> **Note**: Git dependencies are not directly supported by the plugin system. Clone the repository locally and use the `path` option instead.

> **Important**: After any change to the `plugins` section, you must restart the Dart Analysis Server.

### Configuring diagnostics

All rules are registered as warnings and enabled by default. You can enable or disable individual rules under the `diagnostics` key:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_center_over_align: true
      use_bloc_suffix: false
```

## Available Lints

All lints are enabled by default as warnings.

- **avoid_accessing_collections_by_constant_index**: Avoid accessing a collection by a constant index inside a loop.
- **avoid_cascade_after_if_null**: Cascade after if-null operator without parentheses can produce unexpected results.
- **avoid_collection_equality_checks**: Comparing collections with `==`/`!=` checks reference equality, not contents.
- **avoid_collection_methods_with_unrelated_types**: Detects collection method calls with arguments unrelated to the collection's type.
- **avoid_commented_out_code**: Detects comments that look like commented-out code.
- **avoid_single_child_in_multi_child_widgets**: Avoid using a single child in widgets that can accept multiple children (e.g., `Row`, `Column`, `Flex`).
- **avoid_unnecessary_consumer_widgets**: Ensures that a `ConsumerWidget` uses the `ref` parameter.
- **avoid_unnecessary_hook_widgets**: Ensures that a `HookWidget` uses hooks.
- **prefer_abstract_final_static_class**: Classes with only static members should be declared as `abstract final`.
- **prefer_align_over_container**: Enforces the use of `Align` over `Container` with only the alignment parameter.
- **prefer_any_or_every**: Prefer `.any()` or `.every()` over `.where().isEmpty/.isNotEmpty`.
- **prefer_center_over_align**: Prefer `Center` over `Align` with `alignment: Alignment.center`.
- **prefer_explicit_function_type**: Prefer explicit return type and parameter list over bare `Function` type.
- **prefer_iterable_of**: Prefer `.of()` instead of `.from()` for `List`, `Set`, and `Map` for compile-time type safety.
- **prefer_padding_over_container**: Enforces the use of `Padding` over `Container` with only margin.
- **prefer_returning_shorthands**: Prefer dot shorthands when the instance type matches the return type.
- **prefer_shorthands_with_constructors**: Prefer dot shorthands instead of explicit class instantiations.
- **prefer_shorthands_with_enums**: Prefer dot shorthands instead of explicit enum prefixes.
- **prefer_shorthands_with_static_fields**: Prefer dot shorthands instead of explicit class prefixes for static fields.
- **prefer_switch_expression**: Prefer switch expressions over switch statements when possible.
- **prefer_type_over_var**: Prefer an explicit type annotation over `var`.
- **use_bloc_suffix**: Enforces the use of the `Bloc` suffix for classes that extend `Bloc`.
- **use_cubit_suffix**: Enforces the use of the `Cubit` suffix for classes that extend `Cubit`.
- **use_dedicated_media_query_methods**: Enforces the use of dedicated `MediaQuery` methods instead of `MediaQuery.of(context)`.
- **use_gap**: Prefer `Gap` widget instead of `SizedBox` or `Padding` for spacing in multi-child widgets.
- **use_notifier_suffix**: Enforces the use of the `Notifier` suffix for classes that extend `Notifier`.

### Quick fixes

The following rules include auto-fixable quick fixes:

- `avoid_cascade_after_if_null`
- `avoid_commented_out_code`
- `avoid_unnecessary_consumer_widgets`
- `avoid_unnecessary_hook_widgets`
- `prefer_abstract_final_static_class`
- `prefer_align_over_container`
- `prefer_any_or_every`
- `prefer_center_over_align`
- `prefer_explicit_function_type`
- `prefer_iterable_of`
- `prefer_padding_over_container`
- `prefer_returning_shorthands`
- `prefer_shorthands_with_constructors`
- `prefer_shorthands_with_enums`
- `prefer_shorthands_with_static_fields`
- `prefer_switch_expression`
- `prefer_type_over_var`
- `use_bloc_suffix`
- `use_cubit_suffix`
- `use_dedicated_media_query_methods`
- `use_gap`
- `use_notifier_suffix`

## Available Assists

- **Convert to collection-for**: Converts `.map().toList()` or `.map().toSet()` to collection-for syntax.

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

## Example

See the [`example/`](example/) directory for a Flutter project that demonstrates every lint rule in action. Each file corresponds to a single rule and contains code that triggers the lint.

### `use_cubit_suffix`

**DO** use `Cubit` suffix for your cubit names.

**BAD:**

```dart
class MyClass extends Cubit<bool> {}
```

**GOOD:**

```dart
class MyClassCubit extends Cubit<bool> {}
```
