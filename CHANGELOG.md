# Changelog

## [Unreleased]

### Breaking

- Removed `prefer_contains`. The Dart SDK rule with the same name covers the
  same cases plus additional `indexOf` comparisons and provides its own quick
  fix. A removed-rule tombstone remains registered so existing configurations
  point users to the SDK rule instead of producing an unknown-rule warning.

- `use_bloc_suffix`, `use_cubit_suffix` and `use_notifier_suffix` are replaced by two general rules, `use_class_suffix` and `use_class_prefix`. The old rules enforced naming for exactly three hardcoded base types; the new ones work for any type, including one declared in your own package, so a project using `...Store`, `...Repository` or `...UseCase` can adopt them instead of forking.

  Both are entirely config-driven and report nothing until configured. To restore the previous behaviour:

  ```yaml
  # many_lints.yaml
  rules:
    use_class_suffix:
      entries:
        - type: Bloc
          package: bloc
          suffix: Bloc
        - type: Cubit
          package: bloc
          suffix: Cubit
        - type: Notifier
          package: riverpod
          suffix: Notifier
  ```

  Any `// ignore: many_lints/use_bloc_suffix` comment (or the `_cubit_`/`_notifier_` variants) must be renamed to the new rule, and `diagnostics:` entries likewise.

### Added

- `use_class_suffix` and `use_class_prefix`, each taking an `entries:` list of `{type, suffix|prefix, package?, ignore_private?}`. A base type matches whether it is reached by `extends`, `implements`, `with`, or an indirect ancestor, and `package:` is optional — omit it to match a type of that name from any library. Both ship a quick fix that renames the class and any same-named unnamed constructor.
- A rule-wide `ignore_private` option on both rules, overridable per entry.

### Fixed

- The suffix quick fix no longer eats a character when repairing a near-miss. It scanned candidate lengths longest-first and took the first match within two edits, so `CounterBlok` became `CounterBloc` by way of stripping `rBlok` — producing `CounteBloc`. It now ranks candidates by edit distance and prefers the length closest to the affix.
- `cleanup_methods: []` now genuinely replaces the built-in cleanup methods with an empty list for `dispose_fields` and `dispose_provided_instances`. It previously fell back to `[dispose, close, cancel]`, contradicting the documented replacement semantics.
- Added end-to-end `PluginServer` coverage for every previously untested
  rule-specific option, including Bloc wrappers, hook/widget exemptions,
  constructor class lists, collection strictness and widget thresholds.

### Documentation

- Documented the shared `state_base_classes` option on every rule that supports it, and corrected the example inventory so each rule page, example and quick-fix badge matches the plugin registry.

## [0.9.0] - 2026-08-08

### Added

- Per-rule configuration, read from a `many_lints.yaml` file at the package root and falling back to a top-level `many_lints:` section in `analysis_options.yaml`. The analyzer cannot carry per-rule configuration for a plugin — `RuleConfig` exposes only name, group and severity, and custom keys under `plugins:` are reported as unsupported options — so configuration lives in its own file. When both sources exist the dedicated file wins outright rather than merging, so a pattern always has one traceable origin.
- An `exclude` key on every one of the 133 rules, taking a list of glob patterns relative to the package root. Exclusion is per rule: silencing a noisy rule in generated or legacy code says nothing about the other 132, so a path can be skipped without weakening the rest of the suite.
- `avoid_only_rethrow` gains an `ignore_typed_catches` option, which stops it reporting a catch clause that narrows the caught type (`on FooException catch (e) { rethrow; }`).

## [0.8.0] - 2026-08-07

### Added

- `avoid_duplicate_collection_elements` now has a quick fix that removes the duplicate, keeping the first occurrence. It covers all three reported shapes: plain values, spreads and `if` elements.
- `avoid_shrink_wrap_in_lists` now has a quick fix that removes the `shrinkWrap: true` argument. The parameter defaults to `false`, so this is behaviour-preserving; a list that was shrink-wrapped because it nests inside another scrollable still needs the documented `CustomScrollView` restructuring, which the fix deliberately does not attempt.
- Quick fixes for the two widened rules that already had one now cover the newly reported shapes. `prefer_add_all` collapses a run of consecutive `add` calls into `addAll([...])` (it previously only rewrote loops, so the new shape was reported with no fix available), and `avoid_unnecessary_negations` rewrites `!true` and `!a == !b`.
- `test/plugin_fix_output_test.dart` asserts the text a quick fix actually produces, by driving `edit.getFixes` through the `PluginServer` harness and applying the returned edit. `analyzer_testing` still has no fix test API, so fix output previously went unverified.

### Fixed

- **27 quick fixes never fired at all.** They were registered and offered by name, but the IDE only ever showed the "Ignore …" suppression actions — selecting the fix did nothing. Each one type-tested the correction producer's `node` directly (`if (node is! ConstructorName) return;`, `node.parent`, …), which stopped matching after the analyzer 13 AST refactor: `nodeCovering` resolves the diagnostic range to the *deepest* node, so an unnamed `Foo(...)` yields `NamedType` rather than `ConstructorName`, and a `reportAtToken` on a class name yields a name-part wrapper rather than the `ClassDeclaration`. Every affected fix now walks up with `thisOrAncestorOfType` instead. Affected: `avoid_incomplete_copy_with`, `avoid_incorrect_image_opacity`, `avoid_unnecessary_consumer_widgets`, `avoid_unnecessary_gesture_detector`, `avoid_unnecessary_overrides`, `avoid_unnecessary_overrides_in_state`, `avoid_unnecessary_setstate`, `avoid_unnecessary_stateful_widgets`, `avoid_wrapping_in_padding`, `list_all_equatable_fields`, `prefer_abstract_final_static_class`, `prefer_align_over_container`, `prefer_center_over_align`, `prefer_constrained_box_over_container`, `prefer_container`, `prefer_multi_bloc_provider`, `prefer_overriding_parent_equality`, `prefer_padding_over_container`, `prefer_returning_shorthands`, `prefer_sized_box_square`, `prefer_switch_expression`, `prefer_text_rich`, `prefer_transform_over_container`, `prefer_type_over_var`, `use_closest_build_context`, `use_gap`, `use_sliver_prefix`.
- The three suffix fixes (`use_bloc_suffix`, `use_cubit_suffix`, `use_notifier_suffix`) had the same problem, and additionally renamed only the class — leaving `class FooBloc { Foo(); }`, which does not compile. They now rename any same-named constructor along with the class.
- `avoid_generics_shadowing` renamed the type parameter's declaration but left its usages behind (`void process<T>(Config c) {}` — not compilable). It located the declaring scope with a fixed `parent.parent` hop, which stopped reaching class and top-level-function declarations once analyzer 13 added intermediate nodes; it now walks up.
- `avoid_incomplete_copy_with` emitted `dynamic` for any parameter declared as a field formal (`required this.name`), since those carry no type annotation. It now falls back to the resolved element type, producing `String? surname`.
- `prefer_switch_expression` handled only pre-Dart-3 `SwitchCase` members. Dart 3 parses `case Status.active:` as a `SwitchPatternCase`, so the fix bailed on essentially every modern switch it was offered for.
- `prefer_expect_later` emitted two edits starting at the same offset (replacing `expect` and inserting `await ` before it). Overlapping edits raise `ConflictingEditException`, which `FixProcessor` catches and logs — silently discarding the entire fix. It now emits a single edit.
- `use_closest_build_context` ignored untyped closure parameters (`(_) { … }`), because it read only the type annotation while the rule itself falls back to the resolved element type. The two now agree, so the fix can act on every case the rule reports.
- `avoid_commented_out_code` no longer merges unrelated comments into one block. Comments were grouped by character distance (any gap under 150 characters), which reached across blank lines, closing braces, and whole class boundaries — the check for a blank line compared the same distance as the grouping condition, so it could never fire. A block of commented-out code followed by ordinary prose comments elsewhere in the file merged into a single group whose code-line ratio fell below the threshold, silencing the diagnostic for the entire file. Comments are now grouped only when they sit on directly consecutive lines with nothing but whitespace between them, and a comment trailing code (`foo(); // note`) starts its own group. This makes the rule report in files where it previously found nothing.

### Changed

Four rules were widened so that a rule name means here what it conventionally means. Each now covers everything it did before **plus** the shapes commonly reported elsewhere, so existing projects will see new diagnostics on code that previously passed.

- `prefer_add_all` now also reports consecutive `add` calls on the same collection (`values.add(a); values.add(b);`), not only an add-only `for-in` loop. A run is broken by any other statement, and the receiver must be a stable expression of a collection type, so `add` on an unrelated class is left alone.
- `avoid_duplicate_collection_elements` now reports repeated spreads (`[...items, ...items]`) and repeated `if` elements, and no longer stops analysing a literal at the first spread or `if` element — `[1, ...base, 1]` was previously missed. Spreads inside set and map literals are checked too; plain values there remain out of scope, since the analyzer reports those natively.
- `avoid_unnecessary_negations` now reports a negated boolean literal (`!true`) and negations on both sides of a comparison (`!a == !b`, `!a != !b`). A single negation in a comparison is still left alone, since removing it would change the result.
- `prefer_switch_with_enums` now counts comparisons joined by `||` toward its threshold, and reports a membership test over a literal collection of enum constants (`{E.a, E.b, E.c}.contains(value)`). A named collection is not reported — it is a reusable set rather than an inlined branch.

`avoid_misused_hooks` and `avoid_shrink_wrap_in_lists` were reviewed and left unchanged: hooks called outside a hook context are already covered by `avoid_hooks_outside_build`, and `avoid_shrink_wrap_in_lists` already reports every `shrinkWrap: true` rather than only nested ones.

### Documentation

- Example files and rule pages for the four widened rules now show the added shapes.
- Rewrote the code examples for 17 rules that had drifted into reproducing third-party documentation verbatim (shared class names, method names, and literal values). Behaviour is unchanged.
- `use_notifier_suffix` no longer claims to cover `AsyncNotifier`; it checks `Notifier` only, and the two are unrelated hierarchies in Riverpod.
- `prefer_shorthands_with_constructors` documents that it does not resolve the destination parameter's declared type, so a `dynamic` parameter is still reported.
- Fixed a type error in the `prefer_use_prefix` example (`useState` returns `ValueNotifier<T>`, not `T`) and an undeclared class in the `avoid_passing_bloc_to_bloc` example.
- Moved `prefer_compute_over_isolate_run` out of the "Testing Rules" category; it is about web platform compatibility.

## [0.7.1] - 2026-08-03

### Fixed

- `avoid_unnecessary_stateful_widgets` no longer fires when a mixin applied to the `State` carries the state. A mixin `on State<T>` can hold the mutable fields, the lifecycle overrides or the `setState` calls on behalf of the class that applies it, which left the `State` body looking empty while the widget was genuinely stateful. Computed getters on such a mixin still do not count as state.
- `avoid_unnecessary_consumer_widgets` now reports `ConsumerStatefulWidget`. The rule matched it but then looked for a `build` with a `ref` parameter on the widget itself, which a `ConsumerStatefulWidget` never has — its `ref` is a getter on the companion `ConsumerState` — so that half of the rule never reported anything. The widget is now correlated with its state class, and any `ref` use in that class counts, not only one inside `build`.
- `avoid_unnecessary_consumer_widgets` no longer fires when a mixin uses the `ref` on the class's behalf. A mixin `on ConsumerState<T>` is a normal way to share provider access, and it left the state body looking ref-free while the widget genuinely needed the container. A mixin carrying no `ref` use still does not suppress the diagnostic.

### Documentation

- Documented that suppression comments for plugin lints require the plugin-name prefix (`// ignore: many_lints/<rule>`). A bare `// ignore: <rule>` has no effect, which is easy to mistake for the rule ignoring suppression altogether. Type-based suppression needs the `type=` form (`// ignore: type=lint`).

## [0.7.0] - 2026-07-15

### Added

- `prefer_private_named_parameters` rule with quick fix — suggests Dart 3.12 private named parameters (`this._field`) over `_field = field` initializer-list boilerplate; only active in libraries with language version 3.12+
- `prefer_theme_mode_getters` rule with quick fix — suggests the `ThemeMode.isDark`/`isLight`/`isSystem` getters (Flutter 3.44+) over `==`/`!=` comparisons against `ThemeMode` constants; only active when the getters exist in the project's Flutter version

## [0.6.0] - 2026-07-15

### Changed

- Bump `analyzer` constraint to `^14.1.0` (support for the latest Dart/Flutter SDKs)
- Bump `analyzer_plugin` constraint to `^0.14.14`
- Bump `analysis_server_plugin` constraint to `^0.3.20`
- Bump `analyzer_testing` constraint to `^0.3.4`

## [0.5.0] - 2026-07-15

### Changed

- Bump `analyzer` constraint to `^13.3.0` (support for the latest Dart/Flutter SDKs)
- Bump `analyzer_plugin` constraint to `^0.14.12`
- Bump `analysis_server_plugin` constraint to `^0.3.18`
- Bump `analyzer_testing` constraint to `^0.3.2`
- Migrate all rules and quick fixes to the analyzer 13 AST API (`NamedArgument`, `Argument`, `RegularFormalParameter`)

## [0.4.4] - 2026-06-18

### Fixed

- `prefer_shorthands_with_enums` now infers enum shorthand context correctly for named arguments.

## [0.4.3] - 2026-05-08

### Fixed

- Diagnostics configuration now works correctly when `many_lints` is loaded through the legacy plugin server constructor.

## [0.4.2] - 2026-05-08

### Fixed

- Respect `diagnostics` configuration so individual `many_lints` rules can be disabled from `analysis_options.yaml`.

## [0.4.1] - 2026-05-07

### Changed

- Bump `analyzer` constraint to `^12.1.0`
- Bump `analyzer_plugin` constraint to `^0.14.8`
- Bump `analysis_server_plugin` constraint to `^0.3.14`
- Bump `analyzer_testing` constraint to `^0.2.5`
- Bump `test` constraint to `^1.31.1`
- Drop the `analyzer` `dependency_overrides` block (no longer needed once `test 1.31.1` lifted its analyzer upper bound)

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
