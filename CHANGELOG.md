# Changelog

## [Unreleased]

## [1.2.0] - 2026-08-27

### Added

- Five assists narrowing a `flatMap` to the combinator that says what it does,
  offered on the `flatMap` under the cursor. Four are exact — fpdart declares
  the narrower combinator *as* the `flatMap` they replace:
  **`andThen`** (callback ignores its argument), **`map`** (callback only
  re-wraps), **`filterOrElse`** (a `right`/`left` ternary, negating the
  predicate when the branches are reversed) and **`sequenceListSeq`** (a
  `reduce` chaining tasks onto an accumulator; always the `Seq` variant, since
  the fold is sequential and `sequenceList` is concurrent). The fifth,
  **`chainFirst`**, is not exact: fpdart's version swallows the effect's
  failure where the hand-written form propagates it, so the lightbulb names the
  difference rather than hiding it. Each resolves the receiver's type, so an
  unrelated class with a `flatMap` is never offered an fpdart combinator.
- An **`Expand to 'flatMap'`** assist, the inverse of the three exact
  narrowings: `andThen`, `map` and `filterOrElse` expand back into the
  `flatMap` each is defined as, for when the next step needs the value the
  narrow form hides. The wrapper is read from what the call returns, so a `map`
  that changes the value type still names the right constructor, and `.of`
  exists on every fpdart type. `chainFirst` and `sequenceListSeq` are
  deliberately not offered: expanding the first honestly needs its `orElse`
  (and the short form people expect silently drops the failure-swallowing),
  and the second would produce a hand-rolled fold needing an empty-list guard.
- `prefer_and_then` (**opinionated**) — reports `flatMap` whose callback never
  reads the value it is handed, which is what `andThen` expresses. Not a
  behaviour change: `andThen` is declared as exactly `flatMap((_) => then())`.
  The check is by element rather than by the `_` spelling, so a named-but-unused
  parameter reports and a used one does not. Ships with a fix.

- `match_pattern` (**no preset**, config-only) — reports code matching a
  pattern the project supplies, and offers the project's own replacement as a
  quick fix. Conventions like "use our `Clock` seam, not `DateTime.now()`" or
  "use our trailing `.unawaited()`" live in a pre-commit `grep` today, with no
  fix, no IDE integration and no `// ignore:` support; this gives them the
  ergonomics of a built-in lint. The pattern matches the source text of one AST
  node — `methodInvocation` or `propertyAccess` — so it cannot run past the
  expression it was written for. `replace:` is optional and omitting it reports
  only; a replacement is offered as a fix only when the result parses, and is
  `singleLocation` so `dart fix --apply` cannot sweep a hand-written regex
  across a project.

- `prefer_overriding_parent_equality` gains `ignored_types`, defaulting to
  `[Widget, Mock, Fake]`. A widget's identity is its `runtimeType` and `key` — that is what
  `Widget ==` compares and what element reuse depends on — so the override this
  rule asked for is one no widget should have. Matching is by supertype, so a
  project's own widget bases are covered without naming each one. Use
  `additional_ignored_types` to extend the default set, or `ignored_types` to
  replace it. Previously the only way out was a path glob over the whole
  presentation layer, standing in for a fact about types.

  `Mock` and `Fake` are exempt for the same reason: a mock's identity is the
  instance, which is what `verify()` matches on, and a `Fake` implements an
  interface it holds no data for. Excluding `test/**` instead would be strictly
  weaker — it also drops a real equality bug in a test helper that is neither.
  Each default is pinned to its declaring package (`flutter`, `mocktail` /
  `mockito`, `test_api`), so a project class named `Mock` or `Fake` — ordinary
  English words — cannot silently switch the rule off for its subtree.
- `avoid_dst_unsafe_date_arithmetic` now follows a `Duration` through constants,
  local variables and getters declared in the analyzed library. Calendar-day
  shifts hidden behind names such as `leadTime.offsetFromEvent` are therefore
  checked just like an inline `Duration(days: ...)`; unresolved or dependency
  getters stay silent rather than being guessed at.

### Fixed

- `use_setstate_synchronously` no longer reports two correctly guarded shapes.
  `if (mounted) setState(...)` — the wrapper form, written when there is
  nothing to do after the guard so an early return would be noise — is now
  recognised alongside `if (!mounted) return;`. A disjunction in the
  early-return form (`if (!mounted || failed) return;`) is recognised too: the
  return fires whenever `mounted` is false, so reaching the line below proves
  it. The overshoot cases still report — an `else` branch, an `await` inside
  the guard, `if (mounted || other)`, and `if (!mounted && other) return;`.
  `use_ref_read_synchronously` and `use_ref_and_state_synchronously` share the
  widened early-return guard.
- `prefer_immutable_state` no longer reports classes that already inherit
  `@immutable`. Widget names ending in `State` are idiomatic Flutter —
  `EmptyState`, `ErrorState`, `LoadingState` describe what is rendered — and
  `StatelessWidget` inherits the annotation from `Widget`, so the rule was
  asking for something the class already had. Any project base class annotated
  `@immutable` passes it down the same way.
- `require_atomic_async_updates` no longer treats a field named inside the
  callback being installed as a dependency on the pre-await read. The shape
  `_timer?.cancel(); _timer = Timer(d, () { _timer?.cancel(); });` is ordinary
  and correct: the callback runs later, on its own timeline, and is not part of
  the value being written.

## [1.1.0] - 2026-08-19

### Added

- `avoid_skipped_tests` (**recommended**) — reports `skip:` on a test, group or
  lifecycle hook and `@Skip(...)` on a library. A skipped test still counts as a
  test, so CI, a mirror-test check and a coverage gate all stay satisfied while
  the assertion no longer runs. Set `allow_reason: true` to permit the
  documented form.
- `avoid_focused_tests` (**recommended**) — reports `solo:`, which silences
  every sibling in the file. Takes no option, since a focus has no
  documented-and-tolerable form.
- `avoid_exit_outside_entrypoint` (**recommended**) — reports `dart:io`'s
  `exit()` outside `bin/**`, which makes the test process disappear
  mid-assertion. Resolves the element, so `Terminal().exit(3)` and a local
  function named `exit` are never reported. Configure with `allow_in`.
- `prefer_typed_exceptions` (**recommended**) — reports a throw that names no
  type a caller could catch selectively. A superset of the SDK's
  `only_throw_errors`, which is satisfied by `Exception(...)`. Extend the
  allowed set with `additional_allow`.
- `avoid_empty_catch` (**recommended**) — reports a catch clause that discards
  the failure. A superset of the SDK's `empty_catches`, which permits
  `catch (_) {}` and comment-only bodies; `allow_with_comment` restores the SDK
  policy.
- `avoid_dst_unsafe_date_arithmetic` (**recommended**) — reports calendar day
  arithmetic on a local `DateTime` performed through a `Duration`. A calendar
  day is 23 or 25 hours long across a DST transition, so the result lands on the
  wrong wall-clock time; the bug never reproduces in UTC, so a CI machine
  running in UTC stays green. Includes a quick fix that rewrites onto the
  `DateTime` constructor.
- `avoid_todo_comments` (**opinionated**) — reports a TODO/FIXME/HACK/XXX
  marker naming no tracked issue. Orthogonal to `flutter_style_todos`, which
  enforces the shape but has no opinion on whether the marker should exist.
  Configure with `markers`, `require_reference` and `reference_pattern`.
- `require_mirror_test` (**enabled by name only**) — reports a library under
  `lib/` with no matching test file. Skips generated files, barrels (detected
  from the AST, not the filename) and files declaring nothing public.
  Configure with `test_dir`, `suffix` and `fallback_anywhere`.

### Fixed

- The documentation and example verification tools now pass on a clean
  checkout: a library-annotation snippet that could not parse as a library, and
  example files tripping `dead_code`, `unused_element` and cross-rule
  diagnostics on the behaviour they demonstrate.

## [1.0.0] - 2026-08-18

### Breaking

- **The `core` and `recommended` presets are now bug-focused.** Six
  likely-but-not-certain findings moved from `core` to `recommended`; rules
  that only prefer an equivalent spelling, API shape, or functional style
  moved from `recommended` to `opinionated`. `match_getter_setter_field_names`,
  `prefer_correct_test_file_name`, and `use_setstate_synchronously` moved into
  `recommended` because they identify concrete mismatches or stale-state
  risks. Existing `opinionated` preferences remain enabled.

- **`avoid_ref_read_inside_build` and `avoid_ref_watch_outside_build` now cover `package:provider` as well as Riverpod.** Both rules previously only fired inside a Riverpod consumer, so a project using `package:provider` got nothing from them. They now also report `context.read<T>()` inside `build` and `context.watch<T>()` outside it.

  Listed as breaking because `avoid_ref_read_inside_build` is in the **`recommended`** preset: a provider-based codebase that upgrades will see diagnostics it did not see before. They are true positives — the mistake is identical in both ecosystems, and the provider half of `avoid_ref_watch_outside_build` catches an outright **crash**, since `context.watch<T>()` throws when called from `initState`.

  The receiver is matched on its **resolved type**, not its name: Riverpod's `ref` is a `WidgetRef`/`Ref`, and provider's extensions hang off `BuildContext`. So `widgetContext.read<T>()` is caught under any receiver name, while a field of an unrelated class you happened to call `ref` is not. That last part is a regression this change had to fix rather than a hypothetical — covering provider means admitting every widget class to the rules, and until the receiver was type-checked, a plain widget holding some other package's `Ref` reported.

  The quick fix's label changed from `Replace with 'ref.watch'` to `Replace with 'watch'`, since a `FixKind` is constant and the old wording named an API a provider user does not have.

- **`prefer_immutable_bloc_state` no longer matches on class name.** It recognised state classes two ways: through the `Bloc<E, S>` / `Cubit<S>` type argument, and through a bare `RegExp(r'State$')` over class names. In a project without the `bloc` package only the second ever matched, so the rule degenerated into "every class named `...State` must be `@immutable`" — reported under a message naming a package the project does not use. One Riverpod-only app saw 27 classes flagged, none of them Bloc state.

  The name-based half moved to the new `prefer_immutable_state`, which says what it checks and carries the `name_pattern` option. To keep the old behaviour, enable both rules; a project that never used Bloc wants only the new one.

  This also fixes a latent bug the split exposed: `Cubit` is itself a `Bloc`, and the Bloc branch was tested first, so a `Cubit<State>` was matched as a Bloc and then searched for a second type argument it does not have. Cubit state was only ever reported by the name heuristic, and went unreported once that was removed.

- **Every rule is now off by default, and rules are selected with a preset.** In
  v0.9.0 all 133 rules were enabled the moment the plugin was installed, which
  meant adopting the package on an existing codebase produced thousands of
  warnings before any of them could be judged useful.

  Installing the plugin now reports nothing until a preset is chosen:

  ```yaml
  # many_lints.yaml
  preset: recommended
  ```

  Five presets are available, each active tier building on the previous one:

  | Preset | Rules | Contents |
  |--------|-------|----------|
  | `none` | 0 | Nothing. The default. |
  | `core` | 35 | Near-certain bugs only — dead conditions, impossible casts, leaked resources. |
  | `recommended` | 91 | `core` plus likely defects and concrete runtime risks. |
  | `opinionated` | 177 | `recommended` plus this package's own style preferences. |
  | `pedantic` | 234 | `opinionated` plus strict naming, structure, complexity, and ordering. |

  `core` and `recommended` are deliberately conservative: a rule that imposes an architecture, a naming scheme, or a contested style choice is in neither, and rules that do nothing until configured (the `banned_*` family, `use_class_prefix`/`use_class_suffix`) are in no preset at all.

  There is deliberately no preset that enables every rule: some rules contradict
  one another, and config-only rules have no meaningful built-in policy.

  A preset can be tuned in either direction without restating its contents, using `enabled:`:

  ```yaml
  preset: recommended
  rules:
    prefer_type_over_var:
      enabled: true      # add a rule the preset omits
    avoid_only_rethrow:
      enabled: false     # drop one it includes
  ```

  The terse `rule_name: true` / `rule_name: false` spelling works too. Configuring a rule by name — giving it an `exclude:`, an `include:`, a `message:` or an option — also opts it in, so an existing `rules:` block keeps working without an added `enabled: true`.

  `preset:` is read from the same two places as the rest of this package's configuration: `many_lints.yaml` at the package root, or a top-level `many_lints:` section in `analysis_options.yaml`. Presets cannot be distributed as includable YAML the way `package:lints` does, because the analyzer replaces a plugin's configuration wholesale across `include:` rather than merging it, and the `diagnostics:` key accepts only severity values.

- Removed `prefer_contains`. The Dart SDK rule with the same name covers the
  same cases plus additional `indexOf` comparisons and provides its own quick
  fix. A removed-rule tombstone remains registered so existing configurations
  point users to the SDK rule instead of producing an unknown-rule warning.

- Removed `prefer_named_boolean_parameters` in favor of the Dart SDK's
  [`avoid_positional_boolean_parameters`](https://dart.dev/tools/linter-rules/avoid_positional_boolean_parameters),
  which covers the same intent and also diagnoses a single positional boolean
  parameter by default.

- Removed `avoid_unnecessary_overrides_in_state` in favor of the Dart SDK's
  [`unnecessary_overrides`](https://dart.dev/tools/linter-rules/unnecessary_overrides).
  The SDK rule covers the State lifecycle cases, preserves legitimate override
  exemptions, and provides a fix. A removed-rule tombstone points existing
  configurations to the SDK rule.

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

This release adds 123 rules. The complete inventory, grouped by documentation
category, is below; the following entries call out the rules whose behaviour or
design needs additional migration context.

- **Architecture:** `avoid_banned_annotations`, `avoid_banned_exports`, `avoid_banned_imports`, `avoid_banned_names`, `avoid_banned_types`, `banned_usage`
- **Async safety:** `avoid_catch_error`, `avoid_future_ignore`, `avoid_missing_completer_stack_trace`, `avoid_passing_async_when_sync_expected`, `avoid_redundant_async`, `prefer_correct_future_return_type`, `require_atomic_async_updates`, `use_setstate_synchronously`
- **Bloc / Riverpod:** `emit_new_bloc_state_instances`, `handle_bloc_event_subclasses`
- **Class naming:** `avoid_unnecessary_enum_prefix`, `match_class_name_pattern`, `prefer_boolean_prefixes`, `prefer_correct_callback_field_name`, `prefer_correct_error_name`, `prefer_correct_handler_name`, `prefer_correct_identifier_length`, `prefer_correct_setter_parameter_name`, `prefer_correct_type_name`, `prefer_prefixed_global_constants`, `use_class_prefix`, `use_class_suffix`
- **Code organization:** `arguments_ordering`, `avoid_duplicate_mixins`, `avoid_unnecessary_constructor`, `avoid_unnecessary_extends`, `enum_constants_ordering`, `initializers_ordering`, `map_keys_ordering`, `match_lib_folder_structure`, `member_ordering`, `parameters_ordering`, `pattern_fields_ordering`, `prefer_match_file_name`, `prefer_single_declaration_per_file`, `record_fields_ordering`
- **Code quality:** `avoid_accessing_other_classes_private_members`, `avoid_complex_conditions`, `avoid_deep_nesting`, `avoid_high_cyclomatic_complexity`, `avoid_long_files`, `avoid_long_functions`, `avoid_long_parameter_list`, `avoid_non_null_assertion`, `avoid_self_compare`, `avoid_shadowed_extension_methods`, `avoid_too_many_methods`, `avoid_unnecessary_call`, `function_always_returns_null`, `function_always_returns_same_value`, `match_getter_setter_field_names`, `max_imports`, `max_statements`, `no_magic_number`, `no_magic_string`, `prefer_declaring_const_constructor`, `prefer_getter_over_method`, `prefer_moving_to_variable`, `prefer_named_parameters`, `prefer_primary_constructors`
- **Collections and types:** `avoid_not_encodable_in_to_json`, `avoid_unrelated_type_casts`, `prefer_correct_json_casts`
- **Control flow:** `avoid_negated_conditions`, `avoid_nested_conditional_expressions`, `avoid_unmodified_loop_condition`, `avoid_unnecessary_continue`, `avoid_unnecessary_return`, `avoid_unused_after_null_check`, `no_equal_conditions`, `no_equal_switch_case`, `no_equal_then_else`, `prefer_conditional_expressions`, `prefer_early_return`, `prefer_returning_condition`
- **Formatting:** `avoid_inconsistent_digit_separators`, `double_literal_format`, `format_comment`
- **fpdart:** `avoid_ad_hoc_left_type`, `avoid_bare_await_in_do`, `avoid_dollar_outside_do_frame`, `avoid_either_of_future`, `avoid_future_of_either`, `avoid_future_of_option`, `avoid_get_or_else_swallowing_failure`, `avoid_nested_do_notation`, `avoid_removed_fpdart_api`, `avoid_throw_in_fp_callback`, `avoid_unnecessary_option`, `avoid_unrun_task`, `avoid_untyped_safe_cast`, `prefer_chain_either`, `prefer_chaining_over_intermediate_run`, `prefer_do_notation`, `prefer_from_nullable`, `prefer_from_predicate`, `prefer_safe_collection_access`, `prefer_string_parse_extensions`, `prefer_task_either_over_try_catch`, `prefer_unit_over_void`
- **Resource management:** `avoid_late_final_reassignment`, `avoid_unremovable_callbacks_in_listeners`
- **Shorthand patterns:** `avoid_nested_shorthands`
- **State management:** `avoid_late_context`, `prefer_immutable_state`
- **Testing:** `format_test_name`, `prefer_correct_test_file_name`
- **Type annotations:** `prefer_explicit_parameter_names`, `prefer_explicit_type_arguments`, `prefer_typedefs_for_callbacks`
- **Widget best practices:** `always_pass_global_key`, `avoid_deep_widget_nesting`, `avoid_too_many_widgets_per_build`, `check_for_equals_in_render_object_setters`, `never_discard_build_context`, `prefer_extracting_callbacks`, `prefer_widget_private_members`

- Added `prefer_correct_future_return_type` to the `opinionated` preset, with
  diagnostics and a quick fix for async declarations whose return type hides
  their non-nullable `Future` result.

- `prefer_returning_condition` warns when an `if` returns `true` with a following `return false` — the condition itself, spelled out in three lines. In the `opinionated` preset.

- `avoid_nested_conditional_expressions` warns when a conditional is nested inside another, packing a decision tree onto one line. The outermost carries the diagnostic, so one chain reports once. Configurable through `max_depth` (default `1`). In the `opinionated` preset.

- `avoid_complex_conditions` warns when a condition combines more `&&`/`||` operands than `max_operands` (default 3). A hand-written `operator ==` is never reported: it is one `&&` per field by construction, and splitting it would scatter a check that reads as a unit. In the **`pedantic`** preset.

- `avoid_long_parameter_list` warns when a function takes more parameters than the budget. Positional and named are counted separately (defaults 4 and 10), since named parameters are labelled at the call site and do not depend on order. In the **`pedantic`** preset.

- `prefer_getter_over_method` warns when a no-argument method only reads a value. Three exclusions keep it off members whose parentheses are fixed: a body that calls anything (`Clock.now()` answers differently each time), a conventional name (`toJson`, `call`, `copyWith`), and a `Stream`/`Future` return. In the **`pedantic`** preset.

- `no_equal_conditions` warns when an `if`/`else if` chain tests the same condition twice, making the later branch unreachable and letting the case it was meant to handle fall through to `else`. Two independent `if`s are not compared, since the first may have changed the state the second reads. In the `recommended` preset.

- `function_always_returns_same_value` warns when every `return` in a function yields the same constant, so the branching around them decides nothing. Protocol callbacks are excluded both by name (`onNotification`, `shouldRepaint`, any `on...`) and by shape — a parameter typed `...Notification` marks a listener whose `bool` is a "handled" signal rather than an answer. In the `recommended` preset.

- `avoid_redundant_async` warns only when a function has no `await` or `throw`
  and every explicit return already produces a compatible `Future`. Raw-value,
  mixed-return, fall-through, `async*`, and `@override` bodies are left alone,
  so removing `async` never creates an invalid return. In the `opinionated`
  preset.

- `avoid_unnecessary_call` warns when a function is invoked through an explicit `.call()`. A null-aware invocation is left alone (`callback?()` does not parse), as is a class defining `call` as a real method — the receiver's type tells the two apart. In the `opinionated` preset.

- `avoid_long_functions` warns when a function body exceeds `max_lines` (default 50), counted between the braces so the signature and doc comment do not count. In the **`pedantic`** preset: a budget is a house style, and measured against a production Flutter app the default reported 187 functions with a median of 98 lines, all genuinely long and none of them a bug. Test files usually want `exclude: [test/**]` rather than a higher budget.

- `prefer_correct_callback_field_name` warns when a callback field or parameter is named `somethingCallback` or `somethingHandler` rather than `onSomething`, the spelling Flutter uses throughout its API. A function named for what it computes (`builder`, `comparator`) is never reported, nor is a bare framework noun: a parameter named exactly `handler` is the request handler in dart_frog, not a callback for an event. In the **`pedantic`** preset, like the other strict naming rules.

- `prefer_boolean_prefixes` warns when a boolean field, getter or method is not named as a yes-or-no question. The verb does not have to lead — `localeIsDefault` asks the same question as `isDefaultLocale` — and a bare third-person verb (`involves`, `matches`) is already one. Overrides, setters, and a private field backing an accessor are never reported, since none of them can be renamed independently. In the **`pedantic`** preset: naming is where codebases disagree most, and a predicate like `screen.atLeast(Breakpoint.tablet)` reads fine without a question verb.

- `member_ordering` warns when a class member is declared before one the configured order puts earlier. The order is declared through `order:`, and the default puts the constructor first, then fields, then behaviour — the shape modern Dart and Flutter code already has. `==` / `hashCode` / `toString`, operators, and a Riverpod `Notifier.build` are never reported, because each is a member whose position is fixed by something other than taste. In the **`pedantic`** preset: against a production Flutter app already following a consistent style it still reported 227 members, every one a real deviation and none of them a bug.

- `prefer_immutable_state` warns when a class whose name marks it as state lacks `@immutable`. It owns the name-based half that `prefer_immutable_bloc_state` used to carry, including the `name_pattern` option, and is deliberately state-management-agnostic: it covers Riverpod notifier state, a hand-rolled store, or any plain `...State` value object. Flutter `State<T>` subclasses are excluded by type, since holding mutable fields is their entire job. In the `opinionated` preset.

- `avoid_late_final_reassignment` warns when a `late final` field is assigned twice on one straight-line path. `late final` promises one assignment and Dart enforces it, but at run time by throwing `LateInitializationError` — so a second write the analyzer can see is a guaranteed crash rather than a possibility. Branches are not followed: two writes in opposite arms of an `if` are how a `late final` is meant to be initialised. In the `core` preset.

- `avoid_unnecessary_constructor` warns when a class declares an empty unnamed constructor identical to the one Dart provides when none is written. A `const`, named, documented or annotated constructor each does something the implicit one cannot and is left alone — as is any class with a second constructor, where declaring the unnamed one is what keeps it available. In the `opinionated` preset.

- `avoid_unnecessary_extends` warns when a class explicitly extends `Object`, which every class does anyway. A user-declared `Object` shadowing `dart:core`'s is a real choice and is left alone. In the `opinionated` preset.

- `avoid_unnecessary_return` warns when a bare `return;` is the last statement of a function returning `void` or `Future<void>`, where control leaves the function without it. An early `return;` that skips later statements is left alone, as is an omitted return type, which means `dynamic` rather than `void`. In the `opinionated` preset.

- `avoid_unnecessary_enum_prefix` warns when an enum constant repeats its own enum's name, which every call site already carries — `Status.statusActive` rather than `Status.active`. The prefix has to end at a word boundary, so `statusable` is not a match, and a constant named exactly like its enum is the whole word rather than a prefix. In the `opinionated` preset.

- `no_equal_switch_case` warns when two branches of a `switch` produce identical bodies, where sharing the patterns with `||` would say it once. Three shapes are excluded because none can be merged: a guarded case (each `when` belongs to its own pattern), the catch-all (it has to stay last), and an empty body (that is a fallthrough). In the **`pedantic`** preset — whether two independent enum branches that agree today should be merged is a genuine judgement call.

- `avoid_duplicate_mixins` warns when a `with` clause applies the same mixin more than once. Every application after the first contributes nothing, but a reader counting the behaviours mixed in sees one more than exists. Resolved types are compared rather than source text, so an aliased import counts as one mixin while a different generic instantiation does not. Re-applying a mixin a superclass already has is left alone, since that does change the linearization order. In the `recommended` preset.

- `avoid_self_compare` warns when a value is passed to its own `compareTo`, which always answers `0` — so a sort built on it leaves the list untouched, and a conditional guarded by it always takes the same branch. Only receivers and arguments that are safe to evaluate twice are compared: a repeated call, and a hand-written getter that can report a moving value, are both left alone. The operator form (`a == a`) stays with `avoid_equal_expressions`, so the two never report the same line. In the `core` preset.

- `avoid_unnecessary_continue` warns when a `continue` is the last statement of a loop body, where control reaches the next iteration without it. It is usually a leftover from a change that moved or deleted the statements it once guarded, and it reads as though something below is being skipped. A labelled `continue`, and one ending a `then` branch to skip an `else`, are both doing real work and are left alone. Ships with a quick fix. In the `opinionated` preset.

- `prefer_moving_to_variable` warns when the same property-access or invocation chain is repeated inside one block, and could be computed once into a variable. Reported at the first occurrence, which is where the variable belongs. In the `pedantic` preset.

  Four options, two of them beyond the usual scope of this rule: `max_extra_occurrences` (how many extra repetitions to tolerate, default `0`; the original `allowed_duplicated_chains` spelling remains as a deprecated alias), `min_chain_length` (the shortest pure-property chain worth naming, default `2`, so `a.b` twice is left alone), `ignored_invocations` and `ignored_targets`.

  A chain containing an invocation ignores `min_chain_length`: repeating `Theme.of(context)` repeats the work, where repeating a field read only repeats the text. Calls made for their effect (`print(x)`), anything that allocates or awaits, chains inside a closure, and assignment targets are all left alone, since re-evaluating those is either the point or not a value at all. When a chain and its own prefix repeat equally often, only the longest is reported.

- `avoid_catch_error` warns on `Future.catchError`. Its handler is an untyped `Function`, so a wrong signature compiles cleanly and throws only on the error path, and a `test` callback returning `false` leaves the error unhandled while reading as though it was caught. `try`/`catch` gets both checked at compile time.
- `never_discard_build_context` warns when a `BuildContext` parameter is named with a wildcard (`_`, `__`). Discarding it does not remove the need for a context — the body falls back to an outer one, which sits higher in the tree, so `Theme.of`/`MediaQuery.of`/`Navigator.of` resolve against a different subtree. Ships a quick fix that names the parameter `context`, withheld when that name is already in scope and renaming would shadow it.
- `use_class_suffix` and `use_class_prefix`, each taking an `entries:` list of `{type, suffix|prefix, package?, ignore_private?}`. A base type matches whether it is reached by `extends`, `implements`, `with`, or an indirect ancestor, and `package:` is optional — omit it to match a type of that name from any library. Both ship a quick fix that renames the class and any same-named unnamed constructor.
- A rule-wide `ignore_private` option on both rules, overridable per entry.
- `prefer_single_declaration_per_file` warns when a file declares more than one top-level declaration. Classes, mixins, enums, extensions and extension types count; private declarations are skipped by default. In the `pedantic` preset — it imposes a strict file-organization convention.

  Configurable along two axes. `kinds:` picks which declaration kinds count, and `types:` narrows to subtypes of named base types, which turns the rule into the type-specific convention:

  ```yaml
  # many_lints.yaml
  rules:
    prefer_single_declaration_per_file:
      types: [Notifier, AsyncNotifier]
  ```

  `groups:` goes further and gives each group its own one-per-file budget, so several conventions coexist without interfering — a file holding one bloc *and* one notifier satisfies both:

  ```yaml
  rules:
    prefer_single_declaration_per_file:
      groups:
        - types: [Bloc, Cubit]
          message: 'One bloc per file.'
        - types: [Notifier]
          message: 'One notifier per file.'
  ```

  Each group also accepts `kinds`, `ignore_private`, `ignore_visible_for_testing` and its own `message`; any written at the top level become the groups' defaults. A declaration matching several groups is counted by the first one only.

### Changed

- `avoid_returning_widgets` moves from `opinionated` to `recommended`, and gains the two exemptions that kept it out. Returning a widget from a helper is a performance defect with a mechanism — the helper denies Flutter the element identity it needs to skip the subtree, so the parent rebuilds wholesale — rather than the style preference `opinionated` is for, and it is [documented by Flutter](https://docs.flutter.dev/perf/best-practices).

  Two shapes are no longer reported:

  - **A declaration passed as a callback** rather than called, such as `Builder(builder: _row)`. The framework invokes it at its own point in the tree, so it does not collapse a subtree into the caller's rebuild, which is the cost the rule exists to prevent. A declaration that is *called* to build inline is still reported. Getters are excluded from this exemption — `=> _body` reads the getter rather than tearing it off, so a bare reference to one is the inline build the rule targets.
  - **Functions annotated for a functional-widget generator.** `ignored_annotations` now defaults to `[FunctionalWidget, swidget, hwidget, hcwidget]` instead of an empty list, so a `functional_widget` user no longer gets a diagnostic on every generated widget. The option keeps its replace semantics; the new `additional_ignored_annotations` extends the defaults instead of restating them.

### Fixed

- Switched the example package to the `pedantic` preset so every preset-backed
  rule is exercised by the example verifier, including pedantic-only rules.
- Replaced obsolete `plugins.many_lints.diagnostics` snippets across rule pages
  with the supported per-rule configuration and added a documentation check to
  prevent that syntax from returning.

- The suffix quick fix no longer eats a character when repairing a near-miss. It scanned candidate lengths longest-first and took the first match within two edits, so `CounterBlok` became `CounterBloc` by way of stripping `rBlok` — producing `CounteBloc`. It now ranks candidates by edit distance and prefers the length closest to the affix.
- `cleanup_methods: []` now genuinely replaces the built-in cleanup methods with an empty list for `dispose_fields` and `dispose_provided_instances`. It previously fell back to `[dispose, close, cancel]`, contradicting the documented replacement semantics.
- Added end-to-end `PluginServer` coverage for every previously untested
  rule-specific option, including Bloc wrappers, hook/widget exemptions,
  constructor class lists, collection strictness and widget thresholds.

### Documentation

- Added a generated, category-grouped index of all rules, repaired README
  category links, and corrected stale Dart, Flutter, Riverpod, and test API
  references.
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

- **26 quick fixes never fired at all.** They were registered and offered by name, but the IDE only ever showed the "Ignore …" suppression actions — selecting the fix did nothing. Each one type-tested the correction producer's `node` directly (`if (node is! ConstructorName) return;`, `node.parent`, …), which stopped matching after the analyzer 13 AST refactor: `nodeCovering` resolves the diagnostic range to the *deepest* node, so an unnamed `Foo(...)` yields `NamedType` rather than `ConstructorName`, and a `reportAtToken` on a class name yields a name-part wrapper rather than the `ClassDeclaration`. Every affected fix now walks up with `thisOrAncestorOfType` instead. Affected: `avoid_incomplete_copy_with`, `avoid_incorrect_image_opacity`, `avoid_unnecessary_consumer_widgets`, `avoid_unnecessary_gesture_detector`, `avoid_unnecessary_overrides`, `avoid_unnecessary_setstate`, `avoid_unnecessary_stateful_widgets`, `avoid_wrapping_in_padding`, `list_all_equatable_fields`, `prefer_abstract_final_static_class`, `prefer_align_over_container`, `prefer_center_over_align`, `prefer_constrained_box_over_container`, `prefer_container`, `prefer_multi_bloc_provider`, `prefer_overriding_parent_equality`, `prefer_padding_over_container`, `prefer_returning_shorthands`, `prefer_sized_box_square`, `prefer_switch_expression`, `prefer_text_rich`, `prefer_transform_over_container`, `prefer_type_over_var`, `use_closest_build_context`, `use_gap`, `use_sliver_prefix`.
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
