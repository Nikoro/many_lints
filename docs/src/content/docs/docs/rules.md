---
title: Rules
description: Browse all Many Lints rules by category.
sidebar:
  order: 5
---

Many Lints provides 259 opt-in rules. Choose a category below, or use
the site search when you already know the API or pattern you want to check.

<a id="architecture"></a>

## Architecture (6)

- [`avoid_banned_annotations`](/many_lints/docs/rules/architecture/avoid-banned-annotations/) — Ban specific annotations, optionally scoped by directory.
- [`avoid_banned_exports`](/many_lints/docs/rules/architecture/avoid-banned-exports/) — Ban re-exports of specific libraries, optionally scoped by directory.
- [`avoid_banned_imports`](/many_lints/docs/rules/architecture/avoid-banned-imports/) — Ban imports of specific libraries, optionally scoped by directory.
- [`avoid_banned_names`](/many_lints/docs/rules/architecture/avoid-banned-names/) — Ban specific identifiers from being used as declaration names.
- [`avoid_banned_types`](/many_lints/docs/rules/architecture/avoid-banned-types/) — Ban specific types from being named, optionally scoped by directory.
- [`banned_usage`](/many_lints/docs/rules/architecture/banned-usage/) — Ban specific members, such as DateTime.now, optionally scoped by directory.

<a id="async-safety"></a>

## Async safety (12)

- [`avoid_catch_error`](/many_lints/docs/rules/async-safety/avoid-catch-error/) — Use try/catch instead of Future.catchError.
- [`avoid_future_ignore`](/many_lints/docs/rules/async-safety/avoid-future-ignore/) — Do not silently suppress Future errors with an unexplained ignore call.
- [`avoid_missing_completer_stack_trace`](/many_lints/docs/rules/async-safety/avoid-missing-completer-stack-trace/) — Pass the stack trace to Completer.completeError.
- [`avoid_nested_futures`](/many_lints/docs/rules/async-safety/avoid-nested-futures/) — Don't declare Future&lt;Future&lt;T&gt;&gt;.
- [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/) — Don't pass an async closure where a void-returning function is expected.
- [`avoid_redundant_async`](/many_lints/docs/rules/async-safety/avoid-redundant-async/) — Flag an async function that never awaits.
- [`check_is_not_closed_after_async_gap`](/many_lints/docs/rules/async-safety/check-is-not-closed-after-async-gap/) — Check isClosed before emitting state after an await.
- [`prefer_correct_future_return_type`](/many_lints/docs/rules/async-safety/prefer-correct-future-return-type/) — Expose async results as non-nullable Future values.
- [`require_atomic_async_updates`](/many_lints/docs/rules/async-safety/require-atomic-async-updates/) — Re-read shared state after an await instead of writing back a stale value.
- [`use_ref_and_state_synchronously`](/many_lints/docs/rules/async-safety/use-ref-and-state-synchronously/) — Check ref.mounted before using ref or state after an await.
- [`use_ref_read_synchronously`](/many_lints/docs/rules/async-safety/use-ref-read-synchronously/) — Add a mounted guard before calling ref.read after an await.
- [`use_setstate_synchronously`](/many_lints/docs/rules/async-safety/use-setstate-synchronously/) — Guard setState after an await with a mounted check.

<a id="bloc-riverpod"></a>

## Bloc / Riverpod (12)

- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`avoid_notifier_constructors`](/many_lints/docs/rules/bloc-riverpod/avoid-notifier-constructors/) — Prevent initialization logic in Notifier constructors.
- [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/) — Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances.
- [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/) — Prevent passing BuildContext to Bloc or Cubit classes.
- [`avoid_public_notifier_properties`](/many_lints/docs/rules/bloc-riverpod/avoid-public-notifier-properties/) — Prevent public fields, getters, and setters on Notifier classes.
- [`dispose_provided_instances`](/many_lints/docs/rules/bloc-riverpod/dispose-provided-instances/) — Ensure disposable instances in Riverpod providers are cleaned up with ref.onDispose.
- [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) — Emit a new state instance instead of the existing state object.
- [`handle_bloc_event_subclasses`](/many_lints/docs/rules/bloc-riverpod/handle-bloc-event-subclasses/) — Register a handler for every Bloc event subclass.
- [`prefer_bloc_extensions`](/many_lints/docs/rules/bloc-riverpod/prefer-bloc-extensions/) — Use context.read/watch instead of BlocProvider.of or RepositoryProvider.of.
- [`prefer_immutable_bloc_state`](/many_lints/docs/rules/bloc-riverpod/prefer-immutable-bloc-state/) — Ensure Bloc and Cubit state classes are annotated with @immutable.
- [`prefer_multi_bloc_provider`](/many_lints/docs/rules/bloc-riverpod/prefer-multi-bloc-provider/) — Use MultiBlocProvider, MultiBlocListener, or MultiRepositoryProvider instead of nesting.

<a id="class-naming"></a>

## Class naming (12)

- [`avoid_unnecessary_enum_prefix`](/many_lints/docs/rules/class-naming/avoid-unnecessary-enum-prefix/) — Drop an enum name repeated in its own constants.
- [`match_class_name_pattern`](/many_lints/docs/rules/class-naming/match-class-name-pattern/) — Match class names against a regular expression.
- [`prefer_boolean_prefixes`](/many_lints/docs/rules/class-naming/prefer-boolean-prefixes/) — Name booleans as questions.
- [`prefer_correct_callback_field_name`](/many_lints/docs/rules/class-naming/prefer-correct-callback-field-name/) — Name callbacks onSomething, the way Flutter does.
- [`prefer_correct_error_name`](/many_lints/docs/rules/class-naming/prefer-correct-error-name/) — Name exception and error classes with the matching suffix.
- [`prefer_correct_handler_name`](/many_lints/docs/rules/class-naming/prefer-correct-handler-name/) — Name event handlers after the event they answer.
- [`prefer_correct_identifier_length`](/many_lints/docs/rules/class-naming/prefer-correct-identifier-length/) — Keep identifier length within bounds.
- [`prefer_correct_setter_parameter_name`](/many_lints/docs/rules/class-naming/prefer-correct-setter-parameter-name/) — Use one parameter name in every setter.
- [`prefer_correct_type_name`](/many_lints/docs/rules/class-naming/prefer-correct-type-name/) — Keep type names within a sensible length and correctly capitalised.
- [`prefer_prefixed_global_constants`](/many_lints/docs/rules/class-naming/prefer-prefixed-global-constants/) — Prefix public top-level constants.
- [`use_class_prefix`](/many_lints/docs/rules/class-naming/use-class-prefix/) — Require a name prefix for classes deriving from a configured type.
- [`use_class_suffix`](/many_lints/docs/rules/class-naming/use-class-suffix/) — Require a name suffix for classes deriving from a configured type.

<a id="code-organization"></a>

## Code organization (17)

- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
- [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/) — Avoid generic type parameters that shadow top-level declarations.
- [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) — Remove a constructor identical to the default one.
- [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/) — Remove an explicit `extends Object`.
- [`enum_constants_ordering`](/many_lints/docs/rules/code-organization/enum-constants-ordering/) — Keep enum constants in a configured order.
- [`initializers_ordering`](/many_lints/docs/rules/code-organization/initializers-ordering/) — Keep constructor initializers in field order.
- [`map_keys_ordering`](/many_lints/docs/rules/code-organization/map-keys-ordering/) — Keep map literal keys in a configured order.
- [`match_lib_folder_structure`](/many_lints/docs/rules/code-organization/match-lib-folder-structure/) — Keep folders under lib/ in lower_snake_case.
- [`member_ordering`](/many_lints/docs/rules/code-organization/member-ordering/) — Keep class members in a configured order.
- [`parameters_ordering`](/many_lints/docs/rules/code-organization/parameters-ordering/) — Keep named parameters in a configured order.
- [`pattern_fields_ordering`](/many_lints/docs/rules/code-organization/pattern-fields-ordering/) — Keep pattern fields in a configured order.
- [`prefer_abstract_final_static_class`](/many_lints/docs/rules/code-organization/prefer-abstract-final-static-class/) — Classes with only static members should be declared as abstract final.
- [`prefer_for_loop_in_children`](/many_lints/docs/rules/code-organization/prefer-for-loop-in-children/) — Prefer collection-for syntax over functional list building in widget children.
- [`prefer_match_file_name`](/many_lints/docs/rules/code-organization/prefer-match-file-name/) — Name a file after the first public declaration in it.
- [`prefer_single_declaration_per_file`](/many_lints/docs/rules/code-organization/prefer-single-declaration-per-file/) — Keep one top-level declaration per file, with per-type budgets.
- [`record_fields_ordering`](/many_lints/docs/rules/code-organization/record-fields-ordering/) — Keep record named fields in a configured order.

<a id="code-quality"></a>

## Code quality (34)

- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
- [`avoid_deep_nesting`](/many_lints/docs/rules/code-quality/avoid-deep-nesting/) — Keep control flow within a nesting budget.
- [`avoid_default_tostring`](/many_lints/docs/rules/code-quality/avoid-default-tostring/) — Don't interpolate objects that don't override toString.
- [`avoid_dst_unsafe_date_arithmetic`](/many_lints/docs/rules/code-quality/avoid-dst-unsafe-date-arithmetic/) — Calendar day arithmetic on a local DateTime should not go through Duration.
- [`avoid_equal_expressions`](/many_lints/docs/rules/code-quality/avoid-equal-expressions/) — Both operands of a binary expression should not be identical.
- [`avoid_exit_outside_entrypoint`](/many_lints/docs/rules/code-quality/avoid-exit-outside-entrypoint/) — Detect exit() outside the program entrypoint, which kills tests.
- [`avoid_high_cyclomatic_complexity`](/many_lints/docs/rules/code-quality/avoid-high-cyclomatic-complexity/) — Keep a function within a complexity budget.
- [`avoid_long_files`](/many_lints/docs/rules/code-quality/avoid-long-files/) — Keep a file within a line budget.
- [`avoid_long_functions`](/many_lints/docs/rules/code-quality/avoid-long-functions/) — Keep function bodies within a line budget.
- [`avoid_long_parameter_list`](/many_lints/docs/rules/code-quality/avoid-long-parameter-list/) — Keep parameter lists within a budget.
- [`avoid_non_null_assertion`](/many_lints/docs/rules/code-quality/avoid-non-null-assertion/) — Don't assert away null with the ! operator.
- [`avoid_self_compare`](/many_lints/docs/rules/code-quality/avoid-self-compare/) — Flag a value compared against itself with compareTo.
- [`avoid_shadowed_extension_methods`](/many_lints/docs/rules/code-quality/avoid-shadowed-extension-methods/) — An extension member the extended type already has.
- [`avoid_todo_comments`](/many_lints/docs/rules/code-quality/avoid-todo-comments/) — Detect TODO comments that reference no tracked issue.
- [`avoid_too_many_methods`](/many_lints/docs/rules/code-quality/avoid-too-many-methods/) — Keep a class within a method budget.
- [`avoid_unnecessary_call`](/many_lints/docs/rules/code-quality/avoid-unnecessary-call/) — Invoke a function directly instead of through .call().
- [`function_always_returns_null`](/many_lints/docs/rules/code-quality/function-always-returns-null/) — A nullable-returning function whose every path returns null.
- [`function_always_returns_same_value`](/many_lints/docs/rules/code-quality/function-always-returns-same-value/) — Flag a function whose every return yields the same constant.
- [`match_getter_setter_field_names`](/many_lints/docs/rules/code-quality/match-getter-setter-field-names/) — Make a getter and setter pair use the same field.
- [`max_imports`](/many_lints/docs/rules/code-quality/max-imports/) — Keep a file within an import budget.
- [`max_statements`](/many_lints/docs/rules/code-quality/max-statements/) — Keep a function within a statement budget.
- [`no_magic_number`](/many_lints/docs/rules/code-quality/no-magic-number/) — Give a number a name when it carries a policy.
- [`no_magic_string`](/many_lints/docs/rules/code-quality/no-magic-string/) — Name a string once it is repeated.
- [`prefer_compute_over_isolate_run`](/many_lints/docs/rules/code-quality/prefer-compute-over-isolate-run/) — Use 'compute()' instead of 'Isolate.run()' for web platform compatibility.
- [`prefer_declaring_const_constructor`](/many_lints/docs/rules/code-quality/prefer-declaring-const-constructor/) — Declare a const constructor where the class allows one.
- [`prefer_getter_over_method`](/many_lints/docs/rules/code-quality/prefer-getter-over-method/) — Make a no-argument value read a getter.
- [`prefer_immediate_return`](/many_lints/docs/rules/code-quality/prefer-immediate-return/) — Return an expression directly instead of via a throwaway variable.
- [`prefer_moving_to_variable`](/many_lints/docs/rules/code-quality/prefer-moving-to-variable/) — Compute a repeated property or invocation chain once into a variable.
- [`prefer_named_parameters`](/many_lints/docs/rules/code-quality/prefer-named-parameters/) — Name parameters once there are more than a couple.
- [`prefer_primary_constructors`](/many_lints/docs/rules/code-quality/prefer-primary-constructors/) — Prefer a primary constructor (Dart 3.13+) over a class of final fields plus a field-assigning constructor.
- [`prefer_private_named_parameters`](/many_lints/docs/rules/code-quality/prefer-private-named-parameters/) — Prefer private named parameters (Dart 3.12+) over initializer-list boilerplate.
- [`prefer_single_setstate`](/many_lints/docs/rules/code-quality/prefer-single-setstate/) — Merge multiple setState calls into a single call.

<a id="collection-type"></a>

## Collections and types (20)

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) — Don't repeat the same element in a collection literal.
- [`avoid_empty_spread`](/many_lints/docs/rules/collection-type/avoid-empty-spread/) — Remove spreads of empty collection literals.
- [`avoid_incomplete_copy_with`](/many_lints/docs/rules/collection-type/avoid-incomplete-copy-with/) — Ensure copyWith methods include all constructor parameters.
- [`avoid_map_keys_contains`](/many_lints/docs/rules/collection-type/avoid-map-keys-contains/) — Use containsKey() instead of .keys.contains() for better performance.
- [`avoid_missing_enum_constant_in_map`](/many_lints/docs/rules/collection-type/avoid-missing-enum-constant-in-map/) — Cover every enum constant in a map keyed by that enum.
- [`avoid_not_encodable_in_to_json`](/many_lints/docs/rules/collection-type/avoid-not-encodable-in-to-json/) — Don't put values jsonEncode cannot serialize into a toJson map.
- [`avoid_unrelated_type_casts`](/many_lints/docs/rules/collection-type/avoid-unrelated-type-casts/) — Don't cast or type-test between unrelated types.
- [`avoid_unsafe_collection_methods`](/many_lints/docs/rules/collection-type/avoid-unsafe-collection-methods/) — Check for emptiness before using first, last, single or reduce.
- [`list_all_equatable_fields`](/many_lints/docs/rules/collection-type/list-all-equatable-fields/) — Ensure all fields are listed in Equatable props.
- [`prefer_add_all`](/many_lints/docs/rules/collection-type/prefer-add-all/) — Replace an add-only loop with addAll.
- [`prefer_any_or_every`](/many_lints/docs/rules/collection-type/prefer-any-or-every/) — Use .any() or .every() instead of .where().isEmpty/.isNotEmpty.
- [`prefer_class_destructuring`](/many_lints/docs/rules/collection-type/prefer-class-destructuring/) — Use Dart 3 class destructuring when accessing multiple properties on the same object.
- [`prefer_correct_edge_insets_constructor`](/many_lints/docs/rules/collection-type/prefer-correct-edge-insets-constructor/) — Use the simplest EdgeInsets constructor for the given values.
- [`prefer_correct_json_casts`](/many_lints/docs/rules/collection-type/prefer-correct-json-casts/) — Cast JSON values to nullable types.
- [`prefer_enums_by_name`](/many_lints/docs/rules/collection-type/prefer-enums-by-name/) — Use .byName() instead of .firstWhere() to look up enum values by name.
- [`prefer_iterable_of`](/many_lints/docs/rules/collection-type/prefer-iterable-of/) — Use List.of() / Set.of() instead of .from() for type-safe copies.
- [`prefer_overriding_parent_equality`](/many_lints/docs/rules/collection-type/prefer-overriding-parent-equality/) — Override == and hashCode when the parent class overrides them.

<a id="control-flow"></a>

## Control flow (29)

- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_constant_switches`](/many_lints/docs/rules/control-flow/avoid-constant-switches/) — Detect switch statements on constant expressions.
- [`avoid_contradictory_expressions`](/many_lints/docs/rules/control-flow/avoid-contradictory-expressions/) — Detect logical AND conditions that always evaluate to false.
- [`avoid_duplicate_cascades`](/many_lints/docs/rules/control-flow/avoid-duplicate-cascades/) — Detect duplicate cascade sections in cascade expressions.
- [`avoid_empty_catch`](/many_lints/docs/rules/control-flow/avoid-empty-catch/) — Detect catch clauses that silently discard the failure.
- [`avoid_inverted_boolean_checks`](/many_lints/docs/rules/control-flow/avoid-inverted-boolean-checks/) — Use the opposite operator instead of negating a comparison.
- [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/) — State the positive case first in an if/else.
- [`avoid_nested_conditional_expressions`](/many_lints/docs/rules/control-flow/avoid-nested-conditional-expressions/) — Flag a conditional nested inside another.
- [`avoid_only_rethrow`](/many_lints/docs/rules/control-flow/avoid-only-rethrow/) — Detect catch clauses that only rethrow the exception.
- [`avoid_redundant_else`](/many_lints/docs/rules/control-flow/avoid-redundant-else/) — Drop the else when the if branch always exits.
- [`avoid_throw_in_catch_block`](/many_lints/docs/rules/control-flow/avoid-throw-in-catch-block/) — Detect throw expressions inside catch blocks.
- [`avoid_unmodified_loop_condition`](/many_lints/docs/rules/control-flow/avoid-unmodified-loop-condition/) — A while loop whose condition the body can never change.
- [`avoid_unnecessary_continue`](/many_lints/docs/rules/control-flow/avoid-unnecessary-continue/) — Remove a `continue` that ends a loop body.
- [`avoid_unnecessary_negations`](/many_lints/docs/rules/control-flow/avoid-unnecessary-negations/) — Collapse double negations.
- [`avoid_unnecessary_return`](/many_lints/docs/rules/control-flow/avoid-unnecessary-return/) — Remove a bare `return;` that ends a void function.
- [`avoid_unused_after_null_check`](/many_lints/docs/rules/control-flow/avoid-unused-after-null-check/) — A variable null-checked but never used in the guarded branch.
- [`no_equal_conditions`](/many_lints/docs/rules/control-flow/no-equal-conditions/) — Flag an if/else-if chain that repeats a condition.
- [`no_equal_switch_case`](/many_lints/docs/rules/control-flow/no-equal-switch-case/) — Flag two switch branches with identical bodies.
- [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/) — Both branches of a condition are identical.
- [`prefer_conditional_expressions`](/many_lints/docs/rules/control-flow/prefer-conditional-expressions/) — Collapse a two-way if/else into a conditional expression.
- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`prefer_return_await`](/many_lints/docs/rules/control-flow/prefer-return-await/) — Detect missing await on returned Futures inside try-catch.
- [`prefer_returning_condition`](/many_lints/docs/rules/control-flow/prefer-returning-condition/) — Return the condition instead of true/false branches.
- [`prefer_simpler_patterns_null_check`](/many_lints/docs/rules/control-flow/prefer-simpler-patterns-null-check/) — Suggest simpler null-check patterns in if-case expressions.
- [`prefer_switch_expression`](/many_lints/docs/rules/control-flow/prefer-switch-expression/) — Suggest converting switch statements to switch expressions.
- [`prefer_typed_exceptions`](/many_lints/docs/rules/control-flow/prefer-typed-exceptions/) — Detect throws that give callers nothing to catch selectively.
- [`proper_super_calls`](/many_lints/docs/rules/control-flow/proper-super-calls/) — Enforce correct ordering of super lifecycle calls in State classes.

<a id="formatting"></a>

## Formatting (3)

- [`avoid_inconsistent_digit_separators`](/many_lints/docs/rules/formatting/avoid-inconsistent-digit-separators/) — Group digit separators at a regular interval.
- [`double_literal_format`](/many_lints/docs/rules/formatting/double-literal-format/) — Write double literals with exactly one leading zero and no redundant trailing zeros.
- [`format_comment`](/many_lints/docs/rules/formatting/format-comment/) — Write comments as capitalised, terminated sentences.

<a id="fpdart"></a>

## fpdart (22)

- [`avoid_ad_hoc_left_type`](/many_lints/docs/rules/fpdart/avoid-ad-hoc-left-type/) — A pipeline only composes when every step shares one error type.
- [`avoid_bare_await_in_do`](/many_lints/docs/rules/fpdart/avoid-bare-await-in-do/) — Awaiting a raw Future inside a Do block escapes the block's tracking.
- [`avoid_dollar_outside_do_frame`](/many_lints/docs/rules/fpdart/avoid-dollar-outside-do-frame/) — Calling a Do block's extraction function from a nested callback unwinds through code that cannot handle it.
- [`avoid_either_of_future`](/many_lints/docs/rules/fpdart/avoid-either-of-future/) — A Future nested in Either or Option escapes the error channel.
- [`avoid_future_of_either`](/many_lints/docs/rules/fpdart/avoid-future-of-either/) — Future&lt;Either&gt; throws away the composition TaskEither already gives you.
- [`avoid_future_of_option`](/many_lints/docs/rules/fpdart/avoid-future-of-option/) — Future&lt;Option&gt; throws away the composition TaskOption already gives you.
- [`avoid_get_or_else_swallowing_failure`](/many_lints/docs/rules/fpdart/avoid-get-or-else-swallowing-failure/) — getOrElse is handed the failure; ignoring it should be a visible decision.
- [`avoid_nested_do_notation`](/many_lints/docs/rules/fpdart/avoid-nested-do-notation/) — A nested Do block short-circuits on its own instead of failing the outer pipeline.
- [`avoid_removed_fpdart_api`](/many_lints/docs/rules/fpdart/avoid-removed-fpdart-api/) — Names removed in fpdart 1.0.0, with the replacement to use.
- [`avoid_throw_in_fp_callback`](/many_lints/docs/rules/fpdart/avoid-throw-in-fp-callback/) — A throw inside an fpdart callback escapes the error channel the pipeline is built to carry.
- [`avoid_unnecessary_option`](/many_lints/docs/rules/fpdart/avoid-unnecessary-option/) — An Option that is wrapped and immediately unwrapped earns nothing.
- [`avoid_unrun_task`](/many_lints/docs/rules/fpdart/avoid-unrun-task/) — Discarding a lazy fpdart value silently skips the work it describes.
- [`avoid_untyped_safe_cast`](/many_lints/docs/rules/fpdart/avoid-untyped-safe-cast/) — safeCast without explicit type arguments infers dynamic and always succeeds.
- [`prefer_chain_either`](/many_lints/docs/rules/fpdart/prefer-chain-either/) — chainEither lifts a synchronous Either step for you.
- [`prefer_chaining_over_intermediate_run`](/many_lints/docs/rules/fpdart/prefer-chaining-over-intermediate-run/) — Several .run() calls in one body are a chain that was never joined up.
- [`prefer_do_notation`](/many_lints/docs/rules/fpdart/prefer-do-notation/) — Deeply nested flatMap callbacks read flatter as a Do block.
- [`prefer_from_nullable`](/many_lints/docs/rules/fpdart/prefer-from-nullable/) — A null check that builds an Option by hand is what Option.fromNullable is for.
- [`prefer_from_predicate`](/many_lints/docs/rules/fpdart/prefer-from-predicate/) — A conditional guarding an Option is one Option.fromPredicate call.
- [`prefer_safe_collection_access`](/many_lints/docs/rules/fpdart/prefer-safe-collection-access/) — list.first throws where list.head returns None.
- [`prefer_string_parse_extensions`](/many_lints/docs/rules/fpdart/prefer-string-parse-extensions/) — Option.fromNullable(int.tryParse(s)) is what toIntOption already is.
- [`prefer_task_either_over_try_catch`](/many_lints/docs/rules/fpdart/prefer-task-either-over-try-catch/) — A repository's failures belong in its signature, not in a try/catch.
- [`prefer_unit_over_void`](/many_lints/docs/rules/fpdart/prefer-unit-over-void/) — void is not a value, so an fpdart type parameterised with it stops composing.

<a id="hook-rules"></a>

## Hooks (4)

- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`prefer_use_callback`](/many_lints/docs/rules/hook-rules/prefer-use-callback/) — Use 'useCallback' instead of 'useMemoized' for memoizing functions.
- [`prefer_use_prefix`](/many_lints/docs/rules/hook-rules/prefer-use-prefix/) — Custom hooks should start with the 'use' prefix.

<a id="pattern-matching"></a>

## Pattern matching (6)

- [`avoid_single_field_destructuring`](/many_lints/docs/rules/pattern-matching/avoid-single-field-destructuring/) — Avoid destructuring a single field when direct property access is simpler.
- [`avoid_wildcard_cases_with_enums`](/many_lints/docs/rules/pattern-matching/avoid-wildcard-cases-with-enums/) — Keep exhaustiveness checking by listing enum cases explicitly.
- [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) — Use a switch instead of an if-else chain over enum constants.
- [`prefer_wildcard_pattern`](/many_lints/docs/rules/pattern-matching/prefer-wildcard-pattern/) — Use the wildcard pattern '_' instead of 'Object()' for catch-all cases.
- [`use_existing_destructuring`](/many_lints/docs/rules/pattern-matching/use-existing-destructuring/) — Add properties to an existing destructuring instead of accessing them directly.
- [`use_existing_variable`](/many_lints/docs/rules/pattern-matching/use-existing-variable/) — Use an existing variable instead of repeating its initializer expression.

<a id="resource-management"></a>

## Resource management (5)

- [`always_remove_listener`](/many_lints/docs/rules/resource-management/always-remove-listener/) — Ensure every addListener() has a matching removeListener() in dispose().
- [`avoid_late_final_reassignment`](/many_lints/docs/rules/resource-management/avoid-late-final-reassignment/) — Flag a `late final` field assigned twice on one path.
- [`avoid_unassigned_stream_subscriptions`](/many_lints/docs/rules/resource-management/avoid-unassigned-stream-subscriptions/) — Ensure stream subscriptions are assigned to a variable for proper cancellation.
- [`avoid_unremovable_callbacks_in_listeners`](/many_lints/docs/rules/resource-management/avoid-unremovable-callbacks-in-listeners/) — Don't pass an inline closure to addListener.
- [`dispose_fields`](/many_lints/docs/rules/resource-management/dispose-fields/) — Ensure State fields with disposal methods are cleaned up in dispose().

<a id="riverpod-state"></a>

## Riverpod state (9)

- [`async_value_nullable_pattern`](/many_lints/docs/rules/riverpod-state/async-value-nullable-pattern/) — Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
- [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/) — Subscribe in build; do not read once.
- [`avoid_ref_watch_outside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-watch-outside-build/) — Subscribe only in build; read once everywhere else.
- [`missing_provider_scope`](/many_lints/docs/rules/riverpod-state/missing-provider-scope/) — Flutter applications using Riverpod must have a ProviderScope at the root of the widget tree.
- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
- [`protected_notifier_properties`](/many_lints/docs/rules/riverpod-state/protected-notifier-properties/) — A Notifier's state, ref and future should not be used from outside the notifier.
- [`provider_parameters`](/many_lints/docs/rules/riverpod-state/provider-parameters/) — Family provider arguments must have stable equality, or the provider is recreated on every rebuild.

<a id="shorthand-patterns"></a>

## Shorthand patterns (5)

- [`avoid_nested_shorthands`](/many_lints/docs/rules/shorthand-patterns/avoid-nested-shorthands/) — Avoid nesting a dot shorthand inside another dot shorthand invocation.
- [`prefer_returning_shorthands`](/many_lints/docs/rules/shorthand-patterns/prefer-returning-shorthands/) — Use dot shorthand constructors in expression function return values.
- [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/) — Use dot shorthand constructors for common Flutter classes.
- [`prefer_shorthands_with_enums`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-enums/) — Use dot shorthands instead of explicit enum prefixes.
- [`prefer_shorthands_with_static_fields`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-static-fields/) — Use dot shorthands instead of explicit class prefixes for static fields.

<a id="state-management"></a>

## State management (9)

- [`avoid_empty_setstate`](/many_lints/docs/rules/state-management/avoid-empty-setstate/) — Don't call setState with an empty callback.
- [`avoid_inherited_widget_in_initstate`](/many_lints/docs/rules/state-management/avoid-inherited-widget-in-initstate/) — Don't look up inherited widgets inside initState.
- [`avoid_late_context`](/many_lints/docs/rules/state-management/avoid-late-context/) — Don't read BuildContext in a late field initializer.
- [`avoid_mounted_in_setstate`](/many_lints/docs/rules/state-management/avoid-mounted-in-setstate/) — Detect mounted checks inside setState callbacks.
- [`avoid_state_constructors`](/many_lints/docs/rules/state-management/avoid-state-constructors/) — Avoid constructors with logic in State classes.
- [`avoid_unnecessary_overrides`](/many_lints/docs/rules/state-management/avoid-unnecessary-overrides/) — Detect overrides that only delegate to super.
- [`avoid_unnecessary_setstate`](/many_lints/docs/rules/state-management/avoid-unnecessary-setstate/) — Detect unnecessary setState calls in lifecycle methods.
- [`avoid_unnecessary_stateful_widgets`](/many_lints/docs/rules/state-management/avoid-unnecessary-stateful-widgets/) — Detect StatefulWidgets that have no mutable state.
- [`prefer_immutable_state`](/many_lints/docs/rules/state-management/prefer-immutable-state/) — Ensure classes named as state are annotated with @immutable.

<a id="testing-rules"></a>

## Testing (8)

- [`avoid_focused_tests`](/many_lints/docs/rules/testing-rules/avoid-focused-tests/) — Detect tests focused with solo:, which silences their siblings.
- [`avoid_misused_test_matchers`](/many_lints/docs/rules/testing-rules/avoid-misused-test-matchers/) — Detect test matchers used with incompatible value types.
- [`avoid_skipped_tests`](/many_lints/docs/rules/testing-rules/avoid-skipped-tests/) — Detect tests, groups and libraries switched off in place.
- [`format_test_name`](/many_lints/docs/rules/testing-rules/format-test-name/) — Hold test descriptions to a house pattern.
- [`prefer_correct_test_file_name`](/many_lints/docs/rules/testing-rules/prefer-correct-test-file-name/) — Name test files so the runner actually runs them.
- [`prefer_expect_later`](/many_lints/docs/rules/testing-rules/prefer-expect-later/) — Use 'expectLater' instead of 'expect' when testing Futures.
- [`prefer_test_matchers`](/many_lints/docs/rules/testing-rules/prefer-test-matchers/) — Prefer using a Matcher instead of a literal value in expect().
- [`require_mirror_test`](/many_lints/docs/rules/testing-rules/require-mirror-test/) — Detect libraries under lib/ with no matching test file.

<a id="type-annotations"></a>

## Type annotations (8)

- [`prefer_async_callback`](/many_lints/docs/rules/type-annotations/prefer-async-callback/) — Use 'AsyncCallback' instead of 'Future&lt;void&gt; Function()'.
- [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/) — Prefer using EquatableMixin instead of extending Equatable.
- [`prefer_explicit_function_type`](/many_lints/docs/rules/type-annotations/prefer-explicit-function-type/) — Prefer explicit function type annotations over the bare 'Function' type.
- [`prefer_explicit_parameter_names`](/many_lints/docs/rules/type-annotations/prefer-explicit-parameter-names/) — Name the parameters of a function type.
- [`prefer_explicit_type_arguments`](/many_lints/docs/rules/type-annotations/prefer-explicit-type-arguments/) — Pin the type arguments of the APIs where inference surprises.
- [`prefer_type_over_var`](/many_lints/docs/rules/type-annotations/prefer-type-over-var/) — Prefer an explicit type annotation over 'var'.
- [`prefer_typedefs_for_callbacks`](/many_lints/docs/rules/type-annotations/prefer-typedefs-for-callbacks/) — Name a multi-parameter function type with a typedef.
- [`prefer_void_callback`](/many_lints/docs/rules/type-annotations/prefer-void-callback/) — Use 'VoidCallback' instead of 'void Function()'.

<a id="widget-best-practices"></a>

## Widget best practices (25)

- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
- [`avoid_recursive_widget_calls`](/many_lints/docs/rules/widget-best-practices/avoid-recursive-widget-calls/) — Don't build a widget from inside its own build method.
- [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/) — Extract widget helper methods into separate widget classes.
- [`avoid_shrink_wrap_in_lists`](/many_lints/docs/rules/widget-best-practices/avoid-shrink-wrap-in-lists/) — Avoid using shrinkWrap in ListView for better scroll performance.
- [`avoid_single_child_in_multi_child_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-single-child-in-multi-child-widgets/) — Don't use Column, Row, or other multi-child widgets with only one child.
- [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/) — Keep one build method within a widget budget.
- [`avoid_unnecessary_consumer_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-consumer-widgets/) — Don't extend ConsumerWidget if you never use WidgetRef.
- [`avoid_unnecessary_gesture_detector`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-gesture-detector/) — Remove GestureDetector widgets that have no event handlers.
- [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/) — Don't extend HookWidget if you never call any hooks.
- [`check_for_equals_in_render_object_setters`](/many_lints/docs/rules/widget-best-practices/check-for-equals-in-render-object-setters/) — Compare before marking a RenderObject dirty.
- [`never_discard_build_context`](/many_lints/docs/rules/widget-best-practices/never-discard-build-context/) — Don't discard a BuildContext parameter with a wildcard.
- [`pass_existing_future_to_future_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-future-to-future-builder/) — Don't create a new Future inline inside FutureBuilder.
- [`pass_existing_stream_to_stream_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-stream-to-stream-builder/) — Don't create a new Stream inline inside StreamBuilder.
- [`prefer_extracting_callbacks`](/many_lints/docs/rules/widget-best-practices/prefer-extracting-callbacks/) — Keep long callbacks out of the widget tree.
- [`prefer_single_widget_per_file`](/many_lints/docs/rules/widget-best-practices/prefer-single-widget-per-file/) — Keep one public widget per file for better organization.
- [`prefer_spacing`](/many_lints/docs/rules/widget-best-practices/prefer-spacing/) — Use the spacing argument on Row/Column instead of SizedBox spacers.
- [`prefer_theme_mode_getters`](/many_lints/docs/rules/widget-best-practices/prefer-theme-mode-getters/) — Prefer ThemeMode.isDark/isLight/isSystem getters (Flutter 3.44+) over == comparisons.
- [`prefer_widget_private_members`](/many_lints/docs/rules/widget-best-practices/prefer-widget-private-members/) — A widget's public API is its constructor.
- [`use_closest_build_context`](/many_lints/docs/rules/widget-best-practices/use-closest-build-context/) — Use the inner BuildContext from builder callbacks, not the outer one.
- [`use_dedicated_media_query_methods`](/many_lints/docs/rules/widget-best-practices/use-dedicated-media-query-methods/) — Use MediaQuery.sizeOf(context) instead of MediaQuery.of(context).size.
- [`use_gap`](/many_lints/docs/rules/widget-best-practices/use-gap/) — Use Gap widget instead of SizedBox for spacing in multi-child widgets.
- [`use_sliver_prefix`](/many_lints/docs/rules/widget-best-practices/use-sliver-prefix/) — Name widgets that return slivers with a Sliver prefix.

<a id="widget-replacement"></a>

## Widget replacement (13)

- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
- [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/) — Use Spacer instead of Expanded with an empty child.
- [`avoid_incorrect_image_opacity`](/many_lints/docs/rules/widget-replacement/avoid-incorrect-image-opacity/) — Use Image's opacity parameter instead of wrapping in Opacity.
- [`avoid_wrapping_in_padding`](/many_lints/docs/rules/widget-replacement/avoid-wrapping-in-padding/) — Avoid wrapping widgets that support padding in a Padding widget.
- [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/) — Use Align instead of Container when only alignment is set.
- [`prefer_center_over_align`](/many_lints/docs/rules/widget-replacement/prefer-center-over-align/) — Use Center instead of Align when alignment is center.
- [`prefer_const_border_radius`](/many_lints/docs/rules/widget-replacement/prefer-const-border-radius/) — Use BorderRadius.all(Radius.circular()) for const support.
- [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/) — Use ConstrainedBox instead of Container when only constraints is set.
- [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) — Replace sequences of nested widgets with a single Container.
- [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/) — Use Padding instead of Container when only padding or margin is set.
- [`prefer_sized_box_square`](/many_lints/docs/rules/widget-replacement/prefer-sized-box-square/) — Use SizedBox.square when width and height are equal.
- [`prefer_text_rich`](/many_lints/docs/rules/widget-replacement/prefer-text-rich/) — Use Text.rich instead of RichText for better accessibility.
- [`prefer_transform_over_container`](/many_lints/docs/rules/widget-replacement/prefer-transform-over-container/) — Use Transform instead of Container when only transform is set.

<!-- Generated by scripts/update-documentation-catalogs.mjs. -->
