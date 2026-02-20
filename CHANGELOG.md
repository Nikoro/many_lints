# Changelog

## [0.4.0] - 2026-02-20

### Added

#### Dart & Code Quality Rules
- `avoid_constant_conditions` rule to warn when both sides of a comparison are constants
- `avoid_constant_switches` rule to warn when a switch expression is a constant
- `avoid_contradictory_expressions` rule to detect contradictory comparisons in `&&` chains
- `avoid_duplicate_cascades` rule to detect duplicate cascade sections with quick fix
- `avoid_generics_shadowing` rule to warn when a generic type parameter shadows a top-level declaration with quick fix
- `avoid_incomplete_copy_with` rule to detect `copyWith` methods missing constructor parameters with quick fix
- `avoid_map_keys_contains` rule to prefer `containsKey()` over `.keys.contains()` with quick fix
- `avoid_misused_test_matchers` rule to detect incompatible matcher usage
- `avoid_only_rethrow` rule to flag catch clauses that only rethrow with quick fix
- `avoid_single_field_destructuring` rule to avoid single-field destructuring with quick fix
- `avoid_throw_in_catch_block` rule to avoid `throw` inside catch blocks with quick fix
- `avoid_unassigned_stream_subscriptions` rule to detect unassigned stream subscriptions
- `list_all_equatable_fields` rule to detect Equatable subclasses with missing fields in `props` with quick fix
- `prefer_class_destructuring` rule to suggest class destructuring for repeated property accesses with quick fix
- `prefer_contains` rule to prefer `.contains()` over `.indexOf()` compared to `-1` with quick fix
- `prefer_enums_by_name` rule to prefer `.byName()` over `.firstWhere()` with quick fix
- `prefer_equatable_mixin` rule to prefer `EquatableMixin` over extending `Equatable` with quick fix
- `prefer_expect_later` rule to prefer `expectLater` when testing Futures with quick fix
- `prefer_overriding_parent_equality` rule to detect missing `==`/`hashCode` overrides with quick fix
- `prefer_return_await` rule to detect missing `await` in `try-catch` with quick fix
- `prefer_simpler_patterns_null_check` rule to prefer simpler null-check patterns in if-case expressions with quick fix
- `prefer_single_widget_per_file` rule to enforce one public widget per file
- `prefer_test_matchers` rule to prefer matchers over literals in `expect()`
- `prefer_wildcard_pattern` rule to prefer `_` over `Object()` with quick fix
- `proper_super_calls` rule to enforce correct super call placement with quick fix
- `use_closest_build_context` rule to use the closest available `BuildContext` with quick fix
- `use_existing_destructuring` rule to use existing destructuring instead of direct access with quick fix
- `use_existing_variable` rule to detect duplicate initializer expressions with quick fix

#### Flutter Widget Rules
- `always_remove_listener` rule to detect listeners not removed in `dispose()` with quick fix
- `avoid_border_all` rule to prefer `Border.fromBorderSide` over `Border.all` with quick fix
- `avoid_conditional_hooks` rule to detect hooks called inside conditionals or loops
- `avoid_expanded_as_spacer` rule to prefer `Spacer` over `Expanded` with empty child with quick fix
- `avoid_flexible_outside_flex` rule to flag `Flexible`/`Expanded` outside `Row`/`Column`/`Flex`
- `avoid_incorrect_image_opacity` rule to use `Image`'s `opacity` parameter with quick fix
- `avoid_mounted_in_setstate` rule to detect `mounted` check inside `setState`
- `avoid_returning_widgets` rule to avoid returning widgets from functions/methods
- `avoid_shrink_wrap_in_lists` rule to avoid `shrinkWrap` in `ListView`
- `avoid_unnecessary_gesture_detector` rule to flag `GestureDetector` with no handlers with quick fix
- `avoid_unnecessary_overrides` rule to detect overrides that only call `super` with quick fix
- `avoid_unnecessary_overrides_in_state` rule to detect State overrides that only call `super` with quick fix
- `avoid_unnecessary_setstate` rule to detect unnecessary `setState` calls with quick fix
- `avoid_unnecessary_stateful_widgets` rule to detect `StatefulWidget` with no mutable state with quick fix
- `avoid_wrapping_in_padding` rule to avoid wrapping in `Padding` when widget has padding support with quick fix
- `dispose_fields` rule to detect undisposed fields with quick fix
- `prefer_async_callback` rule to prefer `AsyncCallback` over `Future<void> Function()` with quick fix
- `prefer_compute_over_isolate_run` rule for web platform compatibility with quick fix
- `prefer_const_border_radius` rule to prefer `BorderRadius.all(Radius.circular())` with quick fix
- `prefer_constrained_box_over_container` rule to prefer `ConstrainedBox` over `Container` with quick fix
- `prefer_container` rule to merge nested widgets into a single `Container` with quick fix
- `prefer_correct_edge_insets_constructor` rule to use simpler `EdgeInsets` constructors with quick fix
- `prefer_for_loop_in_children` rule to prefer for-loops over functional list building with quick fix
- `prefer_single_setstate` rule to merge multiple `setState` calls with quick fix
- `prefer_sized_box_square` rule to prefer `SizedBox.square` with quick fix
- `prefer_spacing` rule to prefer the `spacing` argument over `SizedBox`
- `prefer_text_rich` rule to prefer `Text.rich` over `RichText` with quick fix
- `prefer_transform_over_container` rule to prefer `Transform` over `Container` with quick fix
- `prefer_use_callback` rule to prefer `useCallback` over inline closures with quick fix
- `prefer_use_prefix` rule to prefer `use` prefix for custom hook functions with quick fix
- `prefer_void_callback` rule to prefer `VoidCallback` over `void Function()` with quick fix
- `use_sliver_prefix` rule to enforce `Sliver` prefix for sliver-returning widgets with quick fix

#### BLoC Rules
- `avoid_bloc_public_methods` rule to avoid public members in Bloc classes
- `avoid_passing_bloc_to_bloc` rule to avoid passing Bloc/Cubit to another Bloc/Cubit
- `avoid_passing_build_context_to_blocs` rule to avoid passing `BuildContext` to Bloc/Cubit
- `prefer_bloc_extensions` rule to prefer `context.read`/`context.watch` with quick fix
- `prefer_immutable_bloc_state` rule to annotate Bloc state with `@immutable` with quick fix
- `prefer_multi_bloc_provider` rule to prefer `MultiBlocProvider` with quick fix

#### Riverpod Rules
- `avoid_notifier_constructors` rule to avoid constructors with logic in Notifier classes with quick fix
- `avoid_public_notifier_properties` rule to avoid public non-overridden properties in Notifier classes
- `avoid_ref_inside_state_dispose` rule to avoid accessing `ref` inside `dispose()`
- `avoid_ref_read_inside_build` rule to avoid `ref.read` inside `build` with quick fix
- `avoid_state_constructors` rule to avoid constructors with logic in State classes with quick fix
- `dispose_provided_instances` rule to detect instances not disposed via `ref.onDispose()` with quick fix
- `use_ref_and_state_synchronously` rule to detect async gaps before `ref`/`state` access with quick fix
- `use_ref_read_synchronously` rule to detect `ref.read` stored across async gaps with quick fix

### Changed

- Extracted shared utility `lib/src/constant_expression.dart` for constant expression checking
- Updated README and example README to document all 100 rules and 78 quick fixes

## [0.3.0] - 2026-02-14

### Added

- `prefer_shorthands_with_enums` rule to detect enum values replaceable with shorthand constructors
- `prefer_shorthands_with_constructors` rule to detect constructors replaceable with shorthand syntax
- `prefer_shorthands_with_static_fields` rule to detect static fields replaceable with shorthand syntax
- `prefer_returning_shorthands` rule to detect return statements replaceable with shorthand syntax
- `prefer_switch_expression` rule to suggest using switch expressions over switch statements
- `prefer_explicit_function_type` rule to prefer explicit function types over `Function`
- `prefer_type_over_var` rule to prefer explicit type annotations over `var`
- `prefer_abstract_final_static_class` rule to flag utility classes that should be abstract final
- `prefer_iterable_of` rule to prefer `Iterable.of` over `Iterable.from` for same-type conversions
- `avoid_accessing_collections_by_constant_index` rule to flag hardcoded index access on collections
- `avoid_cascade_after_if_null` rule to detect cascades after if-null operators
- `avoid_collection_equality_checks` rule to flag equality checks on collections
- `avoid_collection_methods_with_unrelated_types` rule to flag collection method calls with unrelated types
- `avoid_commented_out_code` rule to detect commented-out code blocks

### Changed

- Extracted shared utilities, renamed helpers, and refactored suffix rules

## [0.2.1] - 2026-02-05

### Fixed

- Fix invalid dartdoc reference syntax causing pub.dev scoring issues
- Skip example directory in CI workflow

### Added

- README.md for pub.dev Example tab

## [0.2.0] - 2026-02-05

### Added

- `use_gap` rule to prefer `Gap` widget over `SizedBox` or `Padding` for spacing
- Quick fixes for suffix rules (`use_bloc_suffix`, `use_cubit_suffix`, `use_notifier_suffix`)
- Quick fix for `avoid_unnecessary_consumer_widgets` rule
- Example project demonstrating all lint rules
- Dartdoc comments to public APIs

### Changed

- Renamed test methods to snake_case for consistency
- Applied recommended lints from `lints` package

## [0.1.2] - 2026-02-04

### Fixed

- Add `lib/main.dart` re-export for proper `analysis_server_plugin` discovery
- Replace deprecated analyzer API usages with new equivalents

## [0.1.1] - 2026-02-04

### Fixed

- Allow passing arguments to the format command

## [0.1.0] - 2026-02-04

### Added

- `avoid_single_child_in_multi_child_widgets` - detect single-child usage in multi-child widgets
- `avoid_unnecessary_consumer_widgets` - flag unnecessary Riverpod consumer widgets
- `avoid_unnecessary_hook_widgets` - flag unnecessary hook widgets with quick fix
- `prefer_align_over_container` - prefer `Align` over `Container` for alignment only
- `prefer_any_or_every` - prefer `any`/`every` over manual iteration with quick fix
- `prefer_center_over_align` - prefer `Center` over `Align` for centering with quick fix
- `prefer_padding_over_container` - prefer `Padding` over `Container` for padding only with quick fix
- `use_bloc_suffix` - enforce `Bloc` suffix on bloc classes
- `use_cubit_suffix` - enforce `Cubit` suffix on cubit classes
- `use_dedicated_media_query_methods` - prefer dedicated `MediaQuery` methods with quick fix
- `use_notifier_suffix` - enforce `Notifier` suffix on notifier classes
- `convert_iterable_map_to_collection_for` assist
