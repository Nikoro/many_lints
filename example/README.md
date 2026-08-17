# many_lints Examples

This directory contains example code demonstrating every lint rule provided by `many_lints`. Each file in `lib/` corresponds to one rule and marks the relevant bad and good cases. Most files trigger their named lint directly; the two path-based rules (`match_lib_folder_structure` and `prefer_correct_test_file_name`) use commented path examples because a flat `lib/` file cannot violate either rule. Since the broad example preset is enabled, `dart analyze example` can also show related diagnostics from other rules.

## Setup

Add to your `analysis_options.yaml`:

```yaml
plugins:
  many_lints: ^1.0.0
```

## Excluding paths per rule

[`many_lints.yaml`](many_lints.yaml) in this directory demonstrates per-rule `exclude`:

```yaml
rules:
  avoid_only_rethrow:
    exclude:
      - lib/excluded/**
```

[`lib/excluded/excluded_example.dart`](lib/excluded/excluded_example.dart) contains the
same redundant catch clauses as [`lib/avoid_only_rethrow_example.dart`](lib/avoid_only_rethrow_example.dart),
but reports nothing — that path is excluded for the rule. Delete `many_lints.yaml` and
run `dart analyze` again to see the two diagnostics come back.

Note that `avoid_commented_out_code` *does* still report in that file. Each `exclude`
sits under one rule and affects only that rule — excluding a path from
`avoid_only_rethrow` says nothing about the other rules. To skip a path for several
rules, give each of them its own `exclude`.

Paths are globs, but a plain path works too — `lib/generated/foo.dart` is a valid
pattern, and you can list as many entries as you like:

```yaml
rules:
  avoid_only_rethrow:
    exclude:
      - lib/legacy/parser.dart      # one specific file
      - lib/generated/**            # a whole directory tree
      - "**/*.g.dart"               # every generated file
```

The same `rules:` block can instead live under a top-level `many_lints:` key in
`analysis_options.yaml` — the two forms are equivalent.

## All Rules

| Rule | Description | Fix |
|------|-------------|-----|
| `always_remove_listener` | Listener added but never removed in `dispose()` | Yes |
| `always_pass_global_key` | `GlobalKey` created inside `build` loses subtree state | — |
| `async_value_nullable_pattern` | Matching `AsyncValue(:final value?)` on a nullable value hides a legitimate null result | Yes |
| `avoid_accessing_collections_by_constant_index` | Avoid accessing a collection by a constant index inside a loop | — |
| `avoid_banned_annotations` | Configured annotations, optionally scoped by path | — |
| `avoid_banned_exports` | Configured re-exports, optionally scoped by path | — |
| `avoid_banned_imports` | Configured imports, optionally scoped by path | — |
| `avoid_banned_names` | Configured declaration names, optionally scoped by path | — |
| `avoid_banned_types` | Configured types, optionally scoped by path | — |
| `avoid_bloc_public_methods` | Avoid declaring public members in Bloc classes | — |
| `avoid_border_all` | Prefer `Border.fromBorderSide` over `Border.all` | Yes |
| `avoid_build_context_in_providers` | Providers outlive widgets, so they should not receive a `BuildContext` | — |
| `avoid_cascade_after_if_null` | Cascade after if-null operator can produce unexpected results | Yes |
| `avoid_catch_error` | Use `try`/`catch` instead of `Future.catchError`, whose handler is unchecked | — |
| `avoid_collapsible_if` | Merge nested if statements with `&&` | Yes |
| `avoid_conditional_hooks` | Hooks called inside conditionals or loops | — |
| `avoid_collection_equality_checks` | Comparing collections with `==`/`!=` checks reference equality | — |
| `avoid_collection_methods_with_unrelated_types` | Collection method calls with arguments unrelated to the collection's type | — |
| `avoid_commented_out_code` | Detects comments that look like commented-out code | Yes |
| `avoid_constant_conditions` | Both sides of a comparison are constants | — |
| `avoid_constant_switches` | The switch expression is a constant | — |
| `avoid_contradictory_expressions` | Contradictory comparisons in `&&` chains | — |
| `avoid_default_tostring` | Don't interpolate objects that don't override `toString` | — |
| `avoid_duplicate_bloc_event_handlers` | Register each Bloc event type exactly once | — |
| `avoid_duplicate_cascades` | Duplicate cascade sections that indicate copy-paste errors | Yes |
| `avoid_duplicate_collection_elements` | Don't repeat the same element in a collection literal | Yes |
| `avoid_empty_setstate` | Don't call `setState` with an empty callback | — |
| `avoid_empty_spread` | Remove spreads of empty collection literals | Yes |
| `avoid_equal_expressions` | Both operands of a binary expression should not be identical | — |
| `avoid_self_compare` | A value compared against itself with `compareTo` is always 0 | — |
| `avoid_duplicate_mixins` | The same mixin applied twice in one `with` clause | — |
| `avoid_unnecessary_constructor` | An empty constructor identical to the default one | — |
| `member_ordering` | Class members declared out of the configured order | — |
| `prefer_boolean_prefixes` | Booleans should be named as questions | — |
| `prefer_correct_callback_field_name` | Callbacks should be named `on...` | — |
| `prefer_correct_future_return_type` | Async declarations should expose a non-nullable `Future` return type | Yes |
| `avoid_unnecessary_extends` | An explicit `extends Object` states the default | — |
| `avoid_unnecessary_enum_prefix` | An enum constant repeating its own enum name | — |
| `avoid_late_final_reassignment` | A `late final` field assigned twice on one path | — |
| `avoid_expanded_as_spacer` | Prefer `Spacer` over `Expanded` with empty child | Yes |
| `avoid_flexible_outside_flex` | `Flexible`/`Expanded` should only be inside `Row`/`Column`/`Flex` | — |
| `avoid_generics_shadowing` | Generic type parameter shadows a top-level declaration | Yes |
| `avoid_hooks_outside_build` | Only call hooks from a hook context | — |
| `avoid_incomplete_copy_with` | `copyWith` is missing constructor parameters | Yes |
| `avoid_incorrect_image_opacity` | Use `Image`'s `opacity` instead of wrapping in `Opacity` | Yes |
| `avoid_inherited_widget_in_initstate` | Don't look up inherited widgets inside `initState` | — |
| `avoid_inverted_boolean_checks` | Use the opposite operator instead of negating a comparison | Yes |
| `avoid_late_context` | `late` field initializer reads `context`, freezing the value | — |
| `avoid_map_keys_contains` | Use `containsKey()` instead of `.keys.contains()` | Yes |
| `avoid_missing_enum_constant_in_map` | Cover every enum constant in a map keyed by that enum | — |
| `avoid_missing_completer_stack_trace` | Pass the stack trace to `Completer.completeError` | — |
| `avoid_misused_hooks` | Don't call hooks inside loops | — |
| `avoid_misused_test_matchers` | Incompatible matcher usage with the actual value type | — |
| `avoid_mounted_in_setstate` | Checking `mounted` inside `setState` is too late | — |
| `avoid_nested_futures` | Don't declare `Future<Future<T>>` | — |
| `avoid_nested_shorthands` | A dot shorthand nested inside another leaves no type name | — |
| `avoid_non_null_assertion` | Don't assert away null with the `!` operator | — |
| `avoid_not_encodable_in_to_json` | `toJson` map holds a value `jsonEncode` cannot serialize | — |
| `avoid_notifier_constructors` | Avoid constructors with logic in Notifier classes | Yes |
| `avoid_only_rethrow` | Catch clause contains only a rethrow statement | Yes |
| `avoid_passing_async_when_sync_expected` | Async closure passed where a `void` function is expected | — |
| `avoid_passing_bloc_to_bloc` | Avoid passing a Bloc/Cubit to another Bloc/Cubit | — |
| `avoid_passing_build_context_to_blocs` | Avoid passing `BuildContext` to a Bloc/Cubit | — |
| `avoid_public_notifier_properties` | Public non-overridden properties in Notifier classes | — |
| `avoid_recursive_widget_calls` | Don't build a widget from inside its own `build` method | — |
| `avoid_redundant_else` | Drop the `else` when the `if` branch always exits | Yes |
| `avoid_ref_inside_state_dispose` | Avoid accessing `ref` inside `dispose()` | — |
| `avoid_ref_read_inside_build` | Avoid using `ref.read` inside the `build` method | Yes |
| `avoid_ref_watch_outside_build` | Use `ref.read` or `ref.listen` instead of `ref.watch` outside `build` | — |
| `avoid_returning_widgets` | Avoid returning widgets from functions/methods/getters | — |
| `avoid_shadowed_extension_methods` | Extension member the extended type already declares | — |
| `avoid_shrink_wrap_in_lists` | Avoid using `shrinkWrap` in `ListView` | Yes |
| `avoid_single_child_in_multi_child_widgets` | Single child in multi-child widgets | — |
| `avoid_single_field_destructuring` | Avoid single-field destructuring | Yes |
| `avoid_state_constructors` | Avoid constructors with logic in State classes | Yes |
| `avoid_throw_in_catch_block` | Avoid using `throw` inside a catch block | Yes |
| `avoid_unassigned_stream_subscriptions` | Stream subscription not assigned to a variable | — |
| `avoid_unmodified_loop_condition` | Loop condition the body can never change | — |
| `avoid_unnecessary_consumer_widgets` | `ConsumerWidget` does not use `WidgetRef` | Yes |
| `avoid_unnecessary_gesture_detector` | `GestureDetector` with no event handlers | Yes |
| `avoid_unnecessary_hook_widgets` | `HookWidget` does not use hooks | Yes |
| `avoid_unnecessary_negations` | Collapse unnecessary boolean negations | Yes |
| `avoid_unnecessary_continue` | A `continue` that ends a loop body changes nothing | Yes |
| `avoid_unnecessary_return` | A bare `return;` that ends a void function changes nothing | — |
| `no_equal_switch_case` | Two switch branches with identical bodies should share patterns | — |
| `no_equal_conditions` | An if/else-if chain repeating a condition | — |
| `function_always_returns_same_value` | Every return yields the same constant | — |
| `avoid_redundant_async` | `async` without any `await` | — |
| `avoid_unnecessary_call` | An explicit `.call()` on a function | — |
| `avoid_long_functions` | A function body over the configured line budget | — |
| `avoid_long_parameter_list` | More parameters than the configured budget | — |
| `avoid_complex_conditions` | A condition combining too many operands | — |
| `avoid_nested_conditional_expressions` | A conditional nested inside another | — |
| `prefer_returning_condition` | An if/return pair that is just the condition | — |
| `prefer_getter_over_method` | A no-argument value read should be a getter | — |
| `avoid_unnecessary_overrides` | Override only calls `super` without additional logic | Yes |
| `avoid_unnecessary_overrides_in_state` | State method override only calls `super` | Yes |
| `avoid_unnecessary_setstate` | Unnecessary call to `setState` | Yes |
| `avoid_unnecessary_stateful_widgets` | `StatefulWidget` with no mutable state | Yes |
| `avoid_unrelated_type_casts` | `as` cast or `is` check between unrelated types | — |
| `avoid_unremovable_callbacks_in_listeners` | Inline closure passed to `addListener` can never be removed | — |
| `avoid_unsafe_collection_methods` | Check for emptiness before using `first`, `last`, `single`, or `reduce` | — |
| `avoid_unused_after_null_check` | Variable null-checked but unused in the guarded branch | — |
| `avoid_wildcard_cases_with_enums` | Keep exhaustiveness checking by listing enum cases explicitly | — |
| `avoid_wrapping_in_padding` | Avoid wrapping a widget in `Padding` when it has padding support | Yes |
| `banned_usage` | Configured members such as `DateTime.now`, optionally scoped by path | — |
| `check_for_equals_in_render_object_setters` | `RenderObject` setter marks dirty without comparing first | — |
| `check_is_not_closed_after_async_gap` | Check `isClosed` before emitting state after an `await` | — |
| `dispose_fields` | Field not disposed in `dispose()` | Yes |
| `dispose_provided_instances` | Instance not disposed via `ref.onDispose()` | Yes |
| `emit_new_bloc_state_instances` | Emit a new state instance instead of the existing state object | — |
| `function_always_returns_null` | Nullable-returning function whose every path returns null | — |
| `handle_bloc_event_subclasses` | Sealed Bloc event subclass with no `on<E>` handler | — |
| `list_all_equatable_fields` | Equatable subclass missing fields in `props` | Yes |
| `missing_provider_scope` | Riverpod applications must have a `ProviderScope` at the root | Yes |
| `no_equal_then_else` | Both branches of a condition are identical | — |
| `notifier_build` | Classes annotated with `@riverpod` must define a `build` method | Yes |
| `never_discard_build_context` | Don't discard a `BuildContext` parameter with a wildcard | Yes |
| `pass_existing_future_to_future_builder` | Don't create a new `Future` inline inside `FutureBuilder` | — |
| `pass_existing_stream_to_stream_builder` | Don't create a new `Stream` inline inside `StreamBuilder` | — |
| `prefer_abstract_final_static_class` | Classes with only static members → `abstract final` | Yes |
| `prefer_add_all` | Replace an add-only loop or call sequence with `addAll` | Yes |
| `prefer_align_over_container` | Use `Align` instead of `Container` with only alignment | Yes |
| `prefer_any_or_every` | `.any()`/`.every()` over `.where().isEmpty/.isNotEmpty` | Yes |
| `prefer_async_callback` | Use `AsyncCallback` instead of `Future<void> Function()` | Yes |
| `prefer_bloc_extensions` | Use `context.read`/`context.watch` instead of `BlocProvider.of()` | Yes |
| `prefer_center_over_align` | `Center` over `Align` with center alignment | Yes |
| `prefer_class_destructuring` | Use class destructuring for repeated property accesses | Yes |
| `prefer_compute_over_isolate_run` | Use `compute()` instead of `Isolate.run()` | Yes |
| `prefer_const_border_radius` | Prefer `BorderRadius.all` over `BorderRadius.circular` | Yes |
| `prefer_correct_json_casts` | JSON value cast to a non-nullable type throws on a missing key | — |
| `prefer_constrained_box_over_container` | `ConstrainedBox` over `Container` with only constraints | Yes |
| `prefer_container` | Nested widgets → single `Container` | Yes |
| `prefer_correct_edge_insets_constructor` | Use a simpler `EdgeInsets` constructor | Yes |
| `prefer_enums_by_name` | `.byName()` instead of `.firstWhere()` for enum values | Yes |
| `prefer_equatable_mixin` | `EquatableMixin` instead of extending `Equatable` | Yes |
| `prefer_expect_later` | `expectLater` when testing Futures | Yes |
| `prefer_explicit_function_type` | Explicit return type over bare `Function` | Yes |
| `prefer_for_loop_in_children` | For-loop instead of functional list building | Yes |
| `prefer_immediate_return` | Return an expression directly instead of via a throwaway variable | Yes |
| `prefer_immutable_bloc_state` | Bloc state classes → `@immutable` | Yes |
| `prefer_immutable_state` | Classes named as state → `@immutable` | Yes |
| `prefer_iterable_of` | `.of()` instead of `.from()` for type safety | Yes |
| `prefer_moving_to_variable` | Compute a repeated property or invocation chain once into a variable | No |
| `prefer_multi_bloc_provider` | `MultiBlocProvider` instead of nested `BlocProvider`s | Yes |
| `prefer_overriding_parent_equality` | Parent overrides `==`/`hashCode` but subclass does not | Yes |
| `prefer_padding_over_container` | `Padding` over `Container` with only margin | Yes |
| `prefer_primary_constructors` | Final fields plus a field-assigning constructor could be a primary constructor | Yes |
| `prefer_private_named_parameters` | Prefer private named parameters over initializer-list boilerplate | Yes |
| `prefer_return_await` | Missing `await` on returned `Future` in `try-catch` | Yes |
| `prefer_returning_shorthands` | Dot shorthands when instance type matches return type | Yes |
| `prefer_shorthands_with_constructors` | Dot shorthands instead of explicit class instantiations | Yes |
| `prefer_shorthands_with_enums` | Dot shorthands instead of explicit enum prefixes | Yes |
| `prefer_shorthands_with_static_fields` | Dot shorthands instead of explicit class prefixes | Yes |
| `prefer_simpler_patterns_null_check` | Simpler null-check patterns | Yes |
| `prefer_single_setstate` | Merge multiple `setState` calls | Yes |
| `prefer_single_declaration_per_file` | One top-level declaration per file, with per-type budgets | — |
| `prefer_single_widget_per_file` | One public widget per file | — |
| `prefer_sized_box_square` | `SizedBox.square` instead of equal width/height | Yes |
| `prefer_spacing` | `spacing` argument instead of `SizedBox` | — |
| `prefer_switch_expression` | Switch expressions over switch statements | Yes |
| `prefer_switch_with_enums` | Use a switch instead of an if-else chain over enum constants | — |
| `prefer_test_matchers` | `Matcher` instead of literal value in `expect()` | — |
| `prefer_text_rich` | `Text.rich` instead of `RichText` | Yes |
| `prefer_theme_mode_getters` | Prefer `ThemeMode` getters over comparisons against enum constants | Yes |
| `prefer_transform_over_container` | `Transform` over `Container` with only transform | Yes |
| `prefer_type_over_var` | Explicit type annotation over `var` | Yes |
| `prefer_use_callback` | `useCallback` instead of inline closures in hooks | Yes |
| `prefer_use_prefix` | `use` prefix for custom hook functions | Yes |
| `prefer_void_callback` | `VoidCallback` instead of `void Function()` | Yes |
| `prefer_wildcard_pattern` | Wildcard pattern `_` instead of `Object()` | Yes |
| `proper_super_calls` | `super` calls placed correctly in lifecycle methods | Yes |
| `protected_notifier_properties` | Don't access a Notifier's `state`, `ref`, or `future` externally | — |
| `provider_parameters` | Family provider arguments must have stable equality | — |
| `require_atomic_async_updates` | Re-read shared state after an `await` instead of writing back a stale value | — |
| `use_class_prefix` | Configured name prefix for subtypes of a configured type | Yes |
| `use_class_suffix` | Configured name suffix for subtypes of a configured type | Yes |
| `use_closest_build_context` | Use closest available `BuildContext` | Yes |
| `use_dedicated_media_query_methods` | Dedicated `MediaQuery` methods | Yes |
| `use_existing_destructuring` | Use existing destructuring instead of direct access | Yes |
| `use_existing_variable` | Expression duplicates an existing variable's initializer | Yes |
| `use_gap` | `Gap` widget for spacing in multi-child widgets | Yes |
| `use_ref_and_state_synchronously` | Async gap before `ref`/`state` access | Yes |
| `use_ref_read_synchronously` | `ref.read` stored across async gaps | Yes |
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

### The `banned` family

`avoid_banned_imports`, `avoid_banned_exports`, `avoid_banned_types`,
`avoid_banned_names`, `avoid_banned_annotations` and `banned_usage` all read
the same `banned:` entry shape and report nothing until configured — they
enforce *your* policy, not a built-in one. See `many_lints.yaml`.

```yaml
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:io']              # exact match
        in: ['lib/domain/**']          # optional glob scope; omit for everywhere
        message: 'Keep the domain layer platform-independent.'
      - deny_pattern: ['package:legacy_.*']   # anchored to the whole value
```

Each entry takes `deny` and/or `deny_pattern`, plus optional `in` and
`message`. `deny` matches **exactly** — banning `async` does not ban
`dart:async` — so patterns are always opt-in.

❌ **Bad:**
```dart
// in lib/domain/user_repository.dart
import 'dart:io';
```

✅ **Good:**
```dart
// in lib/domain/user_repository.dart
abstract class ConfigSource {
  Future<String> read();
}
```

---

### use_class_prefix

Requires a configured name prefix for classes deriving from a configured type.
Reports nothing until configured — see `many_lints.yaml`.

```yaml
rules:
  use_class_prefix:
    entries:
      - type: Repository
        prefix: Db
```

❌ **Bad:**
```dart
class UserRepository implements Repository {}
```

✅ **Good:**
```dart
class DbUserRepository implements Repository {}
```

---

### use_class_suffix

Requires a configured name suffix for classes deriving from a configured type.
Matches through `extends`, `implements`, `with`, or an indirect ancestor.

```yaml
rules:
  use_class_suffix:
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
```

❌ **Bad:**
```dart
class CounterManager extends Bloc<CounterEvent, int> {}
```

✅ **Good:**
```dart
class CounterBloc extends Bloc<CounterEvent, int> {}
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


---

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_class_suffix
```

The `many_lints/` prefix is **required**. Unlike SDK lints, a plugin diagnostic is only silenced when the rule name is prefixed with the plugin name, so a bare `// ignore: prefer_center_over_align` has no effect. The prefix is the key used under `plugins:` in `analysis_options.yaml`.

Suppressing by type is also possible via `// ignore: type=lint` (the `type=` form is required, and it silences every lint on that line, SDK ones included).

## More Information

See the individual example files in `lib/` for complete, runnable code samples.
