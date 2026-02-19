# many_lints Examples

This directory contains example code demonstrating each lint rule provided by `many_lints`. Each file in `lib/` corresponds to a single rule and contains code that triggers the lint.

## Setup

Add to your `analysis_options.yaml`:

```yaml
plugins:
  many_lints: ^0.3.0
```

## All Rules

| Rule | Description | Fix |
|------|-------------|-----|
| `always_remove_listener` | Listener added but never removed in `dispose()` | Yes |
| `avoid_accessing_collections_by_constant_index` | Avoid accessing a collection by a constant index inside a loop | — |
| `avoid_bloc_public_methods` | Avoid declaring public members in Bloc classes | — |
| `avoid_border_all` | Prefer `Border.fromBorderSide` over `Border.all` | Yes |
| `avoid_cascade_after_if_null` | Cascade after if-null operator can produce unexpected results | Yes |
| `avoid_collection_equality_checks` | Comparing collections with `==`/`!=` checks reference equality | — |
| `avoid_collection_methods_with_unrelated_types` | Collection method calls with arguments unrelated to the collection's type | — |
| `avoid_commented_out_code` | Detects comments that look like commented-out code | Yes |
| `avoid_constant_conditions` | Both sides of a comparison are constants | — |
| `avoid_constant_switches` | The switch expression is a constant | — |
| `avoid_contradictory_expressions` | Contradictory comparisons in `&&` chains | — |
| `avoid_duplicate_cascades` | Duplicate cascade sections that indicate copy-paste errors | Yes |
| `avoid_expanded_as_spacer` | Prefer `Spacer` over `Expanded` with empty child | Yes |
| `avoid_flexible_outside_flex` | `Flexible`/`Expanded` should only be inside `Row`/`Column`/`Flex` | — |
| `avoid_generics_shadowing` | Generic type parameter shadows a top-level declaration | Yes |
| `avoid_incomplete_copy_with` | `copyWith` is missing constructor parameters | Yes |
| `avoid_incorrect_image_opacity` | Use `Image`'s `opacity` instead of wrapping in `Opacity` | Yes |
| `avoid_map_keys_contains` | Use `containsKey()` instead of `.keys.contains()` | Yes |
| `avoid_misused_test_matchers` | Incompatible matcher usage with the actual value type | — |
| `avoid_mounted_in_setstate` | Checking `mounted` inside `setState` is too late | — |
| `avoid_notifier_constructors` | Avoid constructors with logic in Notifier classes | Yes |
| `avoid_only_rethrow` | Catch clause contains only a rethrow statement | Yes |
| `avoid_passing_bloc_to_bloc` | Avoid passing a Bloc/Cubit to another Bloc/Cubit | — |
| `avoid_passing_build_context_to_blocs` | Avoid passing `BuildContext` to a Bloc/Cubit | — |
| `avoid_ref_inside_state_dispose` | Avoid accessing `ref` inside `dispose()` | — |
| `avoid_ref_read_inside_build` | Avoid using `ref.read` inside the `build` method | Yes |
| `avoid_returning_widgets` | Avoid returning widgets from functions/methods/getters | — |
| `avoid_shrink_wrap_in_lists` | Avoid using `shrinkWrap` in `ListView` | — |
| `avoid_single_child_in_multi_child_widgets` | Single child in multi-child widgets | — |
| `avoid_single_field_destructuring` | Avoid single-field destructuring | Yes |
| `avoid_state_constructors` | Avoid constructors with logic in State classes | Yes |
| `avoid_throw_in_catch_block` | Avoid using `throw` inside a catch block | Yes |
| `avoid_unassigned_stream_subscriptions` | Stream subscription not assigned to a variable | — |
| `avoid_unnecessary_consumer_widgets` | `ConsumerWidget` does not use `WidgetRef` | Yes |
| `avoid_unnecessary_gesture_detector` | `GestureDetector` with no event handlers | Yes |
| `avoid_unnecessary_hook_widgets` | `HookWidget` does not use hooks | Yes |
| `avoid_unnecessary_overrides` | Override only calls `super` without additional logic | Yes |
| `avoid_unnecessary_overrides_in_state` | State method override only calls `super` | Yes |
| `avoid_unnecessary_setstate` | Unnecessary call to `setState` | Yes |
| `avoid_unnecessary_stateful_widgets` | `StatefulWidget` with no mutable state | Yes |
| `avoid_wrapping_in_padding` | Avoid wrapping a widget in `Padding` when it has padding support | Yes |
| `dispose_fields` | Field not disposed in `dispose()` | Yes |
| `dispose_provided_instances` | Instance not disposed via `ref.onDispose()` | Yes |
| `prefer_abstract_final_static_class` | Classes with only static members → `abstract final` | Yes |
| `prefer_align_over_container` | Use `Align` instead of `Container` with only alignment | Yes |
| `prefer_any_or_every` | `.any()`/`.every()` over `.where().isEmpty/.isNotEmpty` | Yes |
| `prefer_async_callback` | Use `AsyncCallback` instead of `Future<void> Function()` | Yes |
| `prefer_bloc_extensions` | Use `context.read`/`context.watch` instead of `BlocProvider.of()` | Yes |
| `prefer_center_over_align` | `Center` over `Align` with center alignment | Yes |
| `prefer_class_destructuring` | Use class destructuring for repeated property accesses | Yes |
| `prefer_compute_over_isolate_run` | Use `compute()` instead of `Isolate.run()` | Yes |
| `prefer_const_border_radius` | `BorderRadius.all(Radius.circular())` over `BorderRadius.circular()` | Yes |
| `prefer_constrained_box_over_container` | `ConstrainedBox` over `Container` with only constraints | Yes |
| `prefer_container` | Nested widgets → single `Container` | Yes |
| `prefer_contains` | `.contains()` instead of `.indexOf()` compared to `-1` | Yes |
| `prefer_correct_edge_insets_constructor` | Use a simpler `EdgeInsets` constructor | Yes |
| `prefer_enums_by_name` | `.byName()` instead of `.firstWhere()` for enum values | Yes |
| `prefer_expect_later` | `expectLater` when testing Futures | Yes |
| `prefer_explicit_function_type` | Explicit return type over bare `Function` | Yes |
| `prefer_for_loop_in_children` | For-loop instead of functional list building | Yes |
| `prefer_immutable_bloc_state` | Bloc state classes → `@immutable` | Yes |
| `prefer_iterable_of` | `.of()` instead of `.from()` for type safety | Yes |
| `prefer_multi_bloc_provider` | `MultiBlocProvider` instead of nested `BlocProvider`s | Yes |
| `prefer_overriding_parent_equality` | Parent overrides `==`/`hashCode` but subclass does not | Yes |
| `prefer_padding_over_container` | `Padding` over `Container` with only margin | Yes |
| `prefer_return_await` | Missing `await` on returned `Future` in `try-catch` | Yes |
| `prefer_returning_shorthands` | Dot shorthands when instance type matches return type | Yes |
| `prefer_shorthands_with_constructors` | Dot shorthands instead of explicit class instantiations | Yes |
| `prefer_shorthands_with_enums` | Dot shorthands instead of explicit enum prefixes | Yes |
| `prefer_shorthands_with_static_fields` | Dot shorthands instead of explicit class prefixes | Yes |
| `prefer_simpler_patterns_null_check` | Simpler null-check patterns | Yes |
| `prefer_single_setstate` | Merge multiple `setState` calls | Yes |
| `prefer_single_widget_per_file` | One public widget per file | — |
| `prefer_sized_box_square` | `SizedBox.square` instead of equal width/height | Yes |
| `prefer_spacing` | `spacing` argument instead of `SizedBox` | — |
| `prefer_switch_expression` | Switch expressions over switch statements | Yes |
| `prefer_test_matchers` | `Matcher` instead of literal value in `expect()` | — |
| `prefer_text_rich` | `Text.rich` instead of `RichText` | Yes |
| `prefer_transform_over_container` | `Transform` over `Container` with only transform | Yes |
| `prefer_type_over_var` | Explicit type annotation over `var` | Yes |
| `prefer_void_callback` | `VoidCallback` instead of `void Function()` | Yes |
| `prefer_wildcard_pattern` | Wildcard pattern `_` instead of `Object()` | Yes |
| `proper_super_calls` | `super` calls placed correctly in lifecycle methods | Yes |
| `use_bloc_suffix` | `Bloc` suffix for `Bloc` subclasses | Yes |
| `use_closest_build_context` | Use closest available `BuildContext` | Yes |
| `use_cubit_suffix` | `Cubit` suffix for `Cubit` subclasses | Yes |
| `use_dedicated_media_query_methods` | Dedicated `MediaQuery` methods | Yes |
| `use_existing_destructuring` | Use existing destructuring instead of direct access | Yes |
| `use_existing_variable` | Expression duplicates an existing variable's initializer | Yes |
| `use_gap` | `Gap` widget for spacing in multi-child widgets | Yes |
| `use_notifier_suffix` | `Notifier` suffix for `Notifier` subclasses | Yes |
| `use_sliver_prefix` | `Sliver` prefix for sliver-returning widgets | Yes |

## Detailed Examples

### avoid_single_child_in_multi_child_widgets

Multi-child widgets like `Column`, `Row`, `Wrap` should not be used with only a single child.

❌ **Bad:**
```dart
Column(
  children: [Text('Only child')],
)
```

✅ **Good:**
```dart
Text('Only child')
```

---

### avoid_unnecessary_consumer_widgets

`ConsumerWidget` should only be used when the `WidgetRef` is actually used.

❌ **Bad:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref is never used
    return Text('Hello');
  }
}
```

✅ **Good:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

---

### avoid_unnecessary_hook_widgets

`HookWidget` should only be used when hooks are actually called.

❌ **Bad:**
```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // No hooks called
    return Text('Hello');
  }
}
```

✅ **Good:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

---

### prefer_align_over_container

Use `Align` widget instead of `Container` when only alignment is set.

❌ **Bad:**
```dart
Container(
  alignment: Alignment.topLeft,
  child: Text('Hello'),
)
```

✅ **Good:**
```dart
Align(
  alignment: Alignment.topLeft,
  child: Text('Hello'),
)
```

---

### prefer_any_or_every

Use `.any()` instead of `.where().isNotEmpty` and `.every()` instead of `.where().isEmpty`.

❌ **Bad:**
```dart
final hasEven = numbers.where((n) => n.isEven).isNotEmpty;
final allPositive = numbers.where((n) => n < 0).isEmpty;
```

✅ **Good:**
```dart
final hasEven = numbers.any((n) => n.isEven);
final allPositive = numbers.every((n) => n >= 0);
```

---

### prefer_center_over_align

Use `Center` widget instead of `Align` when alignment is center.

❌ **Bad:**
```dart
Align(
  alignment: Alignment.center,
  child: Text('Hello'),
)
```

✅ **Good:**
```dart
Center(
  child: Text('Hello'),
)
```

---

### prefer_padding_over_container

Use `Padding` widget instead of `Container` when only margin is set.

❌ **Bad:**
```dart
Container(
  margin: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

✅ **Good:**
```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

---

### use_bloc_suffix

Classes extending `Bloc` should have the `Bloc` suffix.

❌ **Bad:**
```dart
class CounterManager extends Bloc<CounterEvent, int> {}
```

✅ **Good:**
```dart
class CounterBloc extends Bloc<CounterEvent, int> {}
```

---

### use_cubit_suffix

Classes extending `Cubit` should have the `Cubit` suffix.

❌ **Bad:**
```dart
class Counter extends Cubit<int> {}
```

✅ **Good:**
```dart
class CounterCubit extends Cubit<int> {}
```

---

### use_dedicated_media_query_methods

Use dedicated `MediaQuery` methods to avoid unnecessary rebuilds.

❌ **Bad:**
```dart
final size = MediaQuery.of(context).size;
final padding = MediaQuery.of(context).padding;
final orientation = MediaQuery.of(context).orientation;
```

✅ **Good:**
```dart
final size = MediaQuery.sizeOf(context);
final padding = MediaQuery.paddingOf(context);
final orientation = MediaQuery.orientationOf(context);
```

---

### use_gap

Use `Gap` widget instead of `SizedBox` or `Padding` for spacing in multi-child widgets.

❌ **Bad:**
```dart
Column(
  children: [
    Text('First'),
    SizedBox(height: 16),
    Text('Second'),
  ],
)
```

✅ **Good:**
```dart
Column(
  children: [
    Text('First'),
    Gap(16),
    Text('Second'),
  ],
)
```

---

### use_notifier_suffix

Classes extending `Notifier` should have the `Notifier` suffix.

❌ **Bad:**
```dart
class CounterManager extends Notifier<int> {}
```

✅ **Good:**
```dart
class CounterNotifier extends Notifier<int> {}
```

---

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

## More Information

See the individual example files in `lib/` for complete, runnable code samples.
