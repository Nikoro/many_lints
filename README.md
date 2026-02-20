<p align="center">
  <a href="https://pub.dev/packages/many_lints"><img src="https://raw.githubusercontent.com/nikoro/many_lints/main/logo/logo.webp" width="800"/></a>
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
    <img src="https://img.shields.io/badge/analyzer-10.1.0-blue" alt="analyzer version 10.1.0">
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
  many_lints: ^0.3.0
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

All 100 lints are enabled by default as warnings.

- **always_remove_listener**: Listener added but never removed in `dispose()`.
- **avoid_accessing_collections_by_constant_index**: Avoid accessing a collection by a constant index inside a loop.
- **avoid_bloc_public_methods**: Avoid declaring public members in Bloc classes. Use events via `add` instead.
- **avoid_border_all**: Prefer `Border.fromBorderSide` over `Border.all`.
- **avoid_cascade_after_if_null**: Cascade after if-null operator without parentheses can produce unexpected results.
- **avoid_collection_equality_checks**: Comparing collections with `==`/`!=` checks reference equality, not contents.
- **avoid_collection_methods_with_unrelated_types**: Detects collection method calls with arguments unrelated to the collection's type.
- **avoid_commented_out_code**: Detects comments that look like commented-out code.
- **avoid_conditional_hooks**: Warns when hooks are called inside conditional branches.
- **avoid_constant_conditions**: Both sides of a comparison are constants, so the result is always the same.
- **avoid_constant_switches**: The switch expression is a constant, so the result is always the same.
- **avoid_contradictory_expressions**: Detects contradictory comparisons in `&&` chains that always evaluate to false.
- **avoid_duplicate_cascades**: Detects duplicate cascade sections that indicate copy-paste errors.
- **avoid_expanded_as_spacer**: Prefer replacing `Expanded` with an empty child with `Spacer`.
- **avoid_flexible_outside_flex**: `Flexible`/`Expanded` should only be used as a direct child of `Row`, `Column`, or `Flex`.
- **avoid_generics_shadowing**: Warns when a generic type parameter shadows a top-level declaration in the same file.
- **avoid_incomplete_copy_with**: `copyWith` is missing constructor parameters.
- **avoid_incorrect_image_opacity**: Use `Image`'s `opacity` parameter instead of wrapping it in an `Opacity` widget.
- **avoid_map_keys_contains**: Use `containsKey()` instead of `.keys.contains()`.
- **avoid_misused_test_matchers**: Detects incompatible matcher usage with the actual value type.
- **avoid_mounted_in_setstate**: Checking `mounted` inside `setState` is too late and can lead to an exception.
- **avoid_notifier_constructors**: Avoid constructors with logic in Notifier classes.
- **avoid_only_rethrow**: Catch clause contains only a rethrow statement.
- **avoid_passing_bloc_to_bloc**: Avoid passing a Bloc/Cubit to another Bloc/Cubit.
- **avoid_passing_build_context_to_blocs**: Avoid passing `BuildContext` to a Bloc/Cubit.
- **avoid_public_notifier_properties**: Avoid public properties on Notifier classes other than `state`.
- **avoid_ref_inside_state_dispose**: Avoid accessing `ref` inside the `dispose()` method.
- **avoid_ref_read_inside_build**: Avoid using `ref.read` inside the `build` method.
- **avoid_returning_widgets**: Avoid returning widgets from functions, methods, or getters.
- **avoid_shrink_wrap_in_lists**: Avoid using `shrinkWrap` in `ListView`.
- **avoid_single_child_in_multi_child_widgets**: Avoid using a single child in widgets that can accept multiple children (e.g., `Row`, `Column`, `Flex`).
- **avoid_single_field_destructuring**: Avoid single-field destructuring. Use direct property access instead.
- **avoid_state_constructors**: Avoid constructors with logic in State classes.
- **avoid_throw_in_catch_block**: Avoid using `throw` inside a catch block.
- **avoid_unassigned_stream_subscriptions**: Stream subscription is not assigned to a variable.
- **avoid_unnecessary_consumer_widgets**: Ensures that a `ConsumerWidget` uses the `ref` parameter.
- **avoid_unnecessary_gesture_detector**: Detects `GestureDetector` with no event handlers.
- **avoid_unnecessary_hook_widgets**: Ensures that a `HookWidget` uses hooks.
- **avoid_unnecessary_overrides**: Detects method overrides that only call `super` without additional logic.
- **avoid_unnecessary_overrides_in_state**: Detects State method overrides that only call `super` without additional logic.
- **avoid_unnecessary_setstate**: Detects unnecessary calls to `setState`.
- **avoid_unnecessary_stateful_widgets**: Detects `StatefulWidget` with no mutable state. Consider using `StatelessWidget`.
- **avoid_wrapping_in_padding**: Avoid wrapping a widget in a `Padding` widget when it already has padding support.
- **dispose_fields**: Detects fields that are not disposed in `dispose()`.
- **dispose_provided_instances**: Detects instances with a dispose method that are not disposed via `ref.onDispose()`.
- **prefer_abstract_final_static_class**: Classes with only static members should be declared as `abstract final`.
- **prefer_align_over_container**: Enforces the use of `Align` over `Container` with only the alignment parameter.
- **prefer_any_or_every**: Prefer `.any()` or `.every()` over `.where().isEmpty/.isNotEmpty`.
- **prefer_async_callback**: Use `AsyncCallback` instead of `Future<void> Function()`.
- **prefer_bloc_extensions**: Use `context.read`/`context.watch` instead of `BlocProvider.of()`.
- **prefer_center_over_align**: Prefer `Center` over `Align` with `alignment: Alignment.center`.
- **prefer_class_destructuring**: Suggests using class destructuring for repeated property accesses.
- **prefer_compute_over_isolate_run**: Use `compute()` instead of `Isolate.run()` for web platform compatibility.
- **prefer_const_border_radius**: Prefer `BorderRadius.all(Radius.circular())` over `BorderRadius.circular()`.
- **prefer_constrained_box_over_container**: Use `ConstrainedBox` instead of `Container` with only the constraints parameter.
- **prefer_container**: Detects sequences of nested widgets that can be replaced with a single `Container`.
- **prefer_contains**: Use `.contains()` instead of `.indexOf()` compared to `-1`.
- **prefer_correct_edge_insets_constructor**: Use a simpler `EdgeInsets` constructor.
- **prefer_enums_by_name**: Use `.byName()` instead of `.firstWhere()` to access enum values by name.
- **prefer_equatable_mixin**: Prefer using `EquatableMixin` instead of extending `Equatable`.
- **prefer_expect_later**: Prefer `expectLater` when testing Futures.
- **prefer_explicit_function_type**: Prefer explicit return type and parameter list over bare `Function` type.
- **prefer_for_loop_in_children**: Prefer using a for-loop instead of functional list building.
- **prefer_immutable_bloc_state**: Bloc state classes should be annotated with `@immutable`.
- **prefer_iterable_of**: Prefer `.of()` instead of `.from()` for `List`, `Set`, and `Map` for compile-time type safety.
- **list_all_equatable_fields**: Warns when an Equatable class does not list all instance fields in `props`.
- **prefer_multi_bloc_provider**: Prefer `MultiBlocProvider` instead of multiple nested `BlocProvider`s.
- **prefer_overriding_parent_equality**: Parent class overrides `==` and `hashCode` but this class does not.
- **prefer_padding_over_container**: Enforces the use of `Padding` over `Container` with only margin.
- **prefer_return_await**: Missing `await` on returned `Future` inside `try-catch` block.
- **prefer_returning_shorthands**: Prefer dot shorthands when the instance type matches the return type.
- **prefer_shorthands_with_constructors**: Prefer dot shorthands instead of explicit class instantiations.
- **prefer_shorthands_with_enums**: Prefer dot shorthands instead of explicit enum prefixes.
- **prefer_shorthands_with_static_fields**: Prefer dot shorthands instead of explicit class prefixes for static fields.
- **prefer_simpler_patterns_null_check**: Prefer simpler null-check patterns in if-case expressions.
- **prefer_single_setstate**: Multiple `setState` calls should be merged into a single call.
- **prefer_single_widget_per_file**: Only one public widget per file.
- **prefer_sized_box_square**: Use `SizedBox.square` instead of `SizedBox` with equal width and height.
- **prefer_spacing**: Prefer passing the `spacing` argument instead of using `SizedBox`.
- **prefer_switch_expression**: Prefer switch expressions over switch statements when possible.
- **prefer_test_matchers**: Prefer using a `Matcher` instead of a literal value in `expect()`.
- **prefer_text_rich**: Use `Text.rich` instead of `RichText` for better text scaling and accessibility.
- **prefer_use_callback**: Use `useCallback` instead of `useMemoized` for memoizing functions.
- **prefer_transform_over_container**: Use `Transform` instead of `Container` with only the transform parameter.
- **prefer_type_over_var**: Prefer an explicit type annotation over `var`.
- **prefer_use_prefix**: Custom hooks should start with the `use` prefix.
- **prefer_void_callback**: Use `VoidCallback` instead of `void Function()`.
- **prefer_wildcard_pattern**: Use the wildcard pattern `_` instead of `Object()`.
- **proper_super_calls**: Ensures `super` calls are placed correctly (first in `initState`, last in `dispose`).
- **use_bloc_suffix**: Enforces the use of the `Bloc` suffix for classes that extend `Bloc`.
- **use_closest_build_context**: Use the closest available `BuildContext` instead of the outer one.
- **use_cubit_suffix**: Enforces the use of the `Cubit` suffix for classes that extend `Cubit`.
- **use_dedicated_media_query_methods**: Enforces the use of dedicated `MediaQuery` methods instead of `MediaQuery.of(context)`.
- **use_existing_destructuring**: Use existing destructuring instead of accessing properties directly.
- **use_existing_variable**: Detects expressions that duplicate the initializer of an existing variable.
- **use_gap**: Prefer `Gap` widget instead of `SizedBox` or `Padding` for spacing in multi-child widgets.
- **use_notifier_suffix**: Enforces the use of the `Notifier` suffix for classes that extend `Notifier`.
- **use_ref_and_state_synchronously**: Don't use `ref` or `state` after an async gap without checking `ref.mounted`.
- **use_ref_read_synchronously**: Avoid calling `ref.read` after an await point without checking if the widget is mounted.
- **use_sliver_prefix**: Widget returns a sliver but its name does not start with `Sliver`.

### Quick fixes

The following rules include auto-fixable quick fixes (78 total):

- `always_remove_listener`
- `avoid_border_all`
- `avoid_cascade_after_if_null`
- `avoid_commented_out_code`
- `avoid_duplicate_cascades`
- `avoid_expanded_as_spacer`
- `avoid_generics_shadowing`
- `avoid_incomplete_copy_with`
- `avoid_incorrect_image_opacity`
- `avoid_map_keys_contains`
- `avoid_notifier_constructors`
- `avoid_only_rethrow`
- `avoid_ref_read_inside_build`
- `avoid_single_field_destructuring`
- `avoid_state_constructors`
- `avoid_throw_in_catch_block`
- `avoid_unnecessary_consumer_widgets`
- `avoid_unnecessary_gesture_detector`
- `avoid_unnecessary_hook_widgets`
- `avoid_unnecessary_overrides`
- `avoid_unnecessary_overrides_in_state`
- `avoid_unnecessary_setstate`
- `avoid_unnecessary_stateful_widgets`
- `avoid_wrapping_in_padding`
- `dispose_fields`
- `dispose_provided_instances`
- `prefer_abstract_final_static_class`
- `prefer_align_over_container`
- `prefer_any_or_every`
- `prefer_async_callback`
- `prefer_bloc_extensions`
- `prefer_center_over_align`
- `prefer_class_destructuring`
- `prefer_compute_over_isolate_run`
- `prefer_const_border_radius`
- `prefer_constrained_box_over_container`
- `prefer_container`
- `prefer_contains`
- `prefer_correct_edge_insets_constructor`
- `prefer_enums_by_name`
- `prefer_equatable_mixin`
- `prefer_expect_later`
- `prefer_explicit_function_type`
- `prefer_for_loop_in_children`
- `prefer_immutable_bloc_state`
- `prefer_iterable_of`
- `list_all_equatable_fields`
- `prefer_multi_bloc_provider`
- `prefer_overriding_parent_equality`
- `prefer_padding_over_container`
- `prefer_return_await`
- `prefer_returning_shorthands`
- `prefer_shorthands_with_constructors`
- `prefer_shorthands_with_enums`
- `prefer_shorthands_with_static_fields`
- `prefer_simpler_patterns_null_check`
- `prefer_single_setstate`
- `prefer_sized_box_square`
- `prefer_switch_expression`
- `prefer_text_rich`
- `prefer_use_callback`
- `prefer_transform_over_container`
- `prefer_type_over_var`
- `prefer_use_prefix`
- `prefer_void_callback`
- `prefer_wildcard_pattern`
- `proper_super_calls`
- `use_bloc_suffix`
- `use_closest_build_context`
- `use_cubit_suffix`
- `use_dedicated_media_query_methods`
- `use_existing_destructuring`
- `use_existing_variable`
- `use_gap`
- `use_notifier_suffix`
- `use_ref_and_state_synchronously`
- `use_ref_read_synchronously`
- `use_sliver_prefix`

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
