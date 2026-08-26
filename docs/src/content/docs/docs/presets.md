---
title: Presets
description: Choose how strict Many Lints should be and see the exact rules each preset adds.
sidebar:
  order: 3
---

Presets are cumulative starting points. Each level includes every rule from the
levels before it, then adds a clearly defined kind of scrutiny. Choose the
lowest tier whose philosophy matches the project and override individual rules
when the codebase deliberately makes a different choice.

| Preset | Total rules | Adds | Intended use |
|--------|------------:|-----:|--------------|
| `none` | 0 | 0 | Explicit opt-out or a fully hand-picked rule set. |
| `core` | 35 | 35 | Near-certain defects with almost no stylistic judgement. |
| `recommended` | 97 | 62 | The default choice for most production projects. |
| `opinionated` | 185 | 88 | A coherent Many Lints house style. |
| `pedantic` | 242 | 57 | Maximum uniformity, explicitness, ordering, and structural limits. |

## `none`: choose everything yourself

`none` is the default and enables no rules. It is useful while evaluating the
plugin, for repositories that enable every rule individually, and for a shared
configuration that should provide options without selecting a policy tier.

```yaml
# many_lints.yaml
preset: none
```

## `core`: bugs, not taste

Use `core` when diagnostics must have an exceptionally high signal-to-noise
ratio. It targets contradictory conditions, invalid type relationships,
unreachable behavior, broken lifecycle management, and other code that is very
likely to fail independently of the team's preferred style.

### Rules added by `core` (35)

- **Async safety:** [`avoid_nested_futures`](/many_lints/docs/rules/async-safety/avoid-nested-futures/)
- **Bloc / Riverpod:** [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/), [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/)
- **Code quality:** [`avoid_equal_expressions`](/many_lints/docs/rules/code-quality/avoid-equal-expressions/), [`avoid_self_compare`](/many_lints/docs/rules/code-quality/avoid-self-compare/), [`avoid_shadowed_extension_methods`](/many_lints/docs/rules/code-quality/avoid-shadowed-extension-methods/)
- **Collections and types:** [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/), [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/), [`avoid_unrelated_type_casts`](/many_lints/docs/rules/collection-type/avoid-unrelated-type-casts/)
- **Control flow:** [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/), [`avoid_constant_switches`](/many_lints/docs/rules/control-flow/avoid-constant-switches/), [`avoid_contradictory_expressions`](/many_lints/docs/rules/control-flow/avoid-contradictory-expressions/), [`avoid_duplicate_cascades`](/many_lints/docs/rules/control-flow/avoid-duplicate-cascades/), [`avoid_unmodified_loop_condition`](/many_lints/docs/rules/control-flow/avoid-unmodified-loop-condition/), [`avoid_unnecessary_negations`](/many_lints/docs/rules/control-flow/avoid-unnecessary-negations/), [`prefer_return_await`](/many_lints/docs/rules/control-flow/prefer-return-await/)
- **fpdart:** [`avoid_bare_await_in_do`](/many_lints/docs/rules/fpdart/avoid-bare-await-in-do/), [`avoid_dollar_outside_do_frame`](/many_lints/docs/rules/fpdart/avoid-dollar-outside-do-frame/), [`avoid_nested_do_notation`](/many_lints/docs/rules/fpdart/avoid-nested-do-notation/), [`avoid_throw_in_fp_callback`](/many_lints/docs/rules/fpdart/avoid-throw-in-fp-callback/), [`avoid_unrun_task`](/many_lints/docs/rules/fpdart/avoid-unrun-task/), [`avoid_untyped_safe_cast`](/many_lints/docs/rules/fpdart/avoid-untyped-safe-cast/)
- **Resource management:** [`always_remove_listener`](/many_lints/docs/rules/resource-management/always-remove-listener/), [`avoid_late_final_reassignment`](/many_lints/docs/rules/resource-management/avoid-late-final-reassignment/), [`avoid_unassigned_stream_subscriptions`](/many_lints/docs/rules/resource-management/avoid-unassigned-stream-subscriptions/), [`dispose_fields`](/many_lints/docs/rules/resource-management/dispose-fields/)
- **Riverpod state:** [`async_value_nullable_pattern`](/many_lints/docs/rules/riverpod-state/async-value-nullable-pattern/), [`missing_provider_scope`](/many_lints/docs/rules/riverpod-state/missing-provider-scope/), [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/)
- **Testing:** [`avoid_misused_test_matchers`](/many_lints/docs/rules/testing-rules/avoid-misused-test-matchers/), [`prefer_expect_later`](/many_lints/docs/rules/testing-rules/prefer-expect-later/)
- **Widget best practices:** [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/), [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/), [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/), [`avoid_recursive_widget_calls`](/many_lints/docs/rules/widget-best-practices/avoid-recursive-widget-calls/)

## `recommended`: safe production defaults

`recommended` includes `core` and adds likely defects, concrete runtime risks,
and broadly accepted Dart and Flutter practices. It avoids naming schemes,
architecture mandates, dependency-specific preferences, and choices on which
healthy codebases commonly disagree. This is the best starting point for most
applications and packages.

### Rules added by `recommended` (62)

- **Async safety:** [`avoid_future_ignore`](/many_lints/docs/rules/async-safety/avoid-future-ignore/), [`avoid_missing_completer_stack_trace`](/many_lints/docs/rules/async-safety/avoid-missing-completer-stack-trace/), [`use_setstate_synchronously`](/many_lints/docs/rules/async-safety/use-setstate-synchronously/)
- **Bloc / Riverpod:** [`avoid_notifier_constructors`](/many_lints/docs/rules/bloc-riverpod/avoid-notifier-constructors/), [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/), [`dispose_provided_instances`](/many_lints/docs/rules/bloc-riverpod/dispose-provided-instances/), [`handle_bloc_event_subclasses`](/many_lints/docs/rules/bloc-riverpod/handle-bloc-event-subclasses/)
- **Code organization:** [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/), [`avoid_generics_shadowing`](/many_lints/docs/rules/code-organization/avoid-generics-shadowing/)
- **Code quality:** [`avoid_dst_unsafe_date_arithmetic`](/many_lints/docs/rules/code-quality/avoid-dst-unsafe-date-arithmetic/), [`avoid_exit_outside_entrypoint`](/many_lints/docs/rules/code-quality/avoid-exit-outside-entrypoint/), [`function_always_returns_null`](/many_lints/docs/rules/code-quality/function-always-returns-null/), [`function_always_returns_same_value`](/many_lints/docs/rules/code-quality/function-always-returns-same-value/), [`match_getter_setter_field_names`](/many_lints/docs/rules/code-quality/match-getter-setter-field-names/)
- **Collections and types:** [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/), [`avoid_empty_spread`](/many_lints/docs/rules/collection-type/avoid-empty-spread/), [`avoid_map_keys_contains`](/many_lints/docs/rules/collection-type/avoid-map-keys-contains/), [`avoid_not_encodable_in_to_json`](/many_lints/docs/rules/collection-type/avoid-not-encodable-in-to-json/), [`prefer_any_or_every`](/many_lints/docs/rules/collection-type/prefer-any-or-every/), [`prefer_enums_by_name`](/many_lints/docs/rules/collection-type/prefer-enums-by-name/), [`prefer_iterable_of`](/many_lints/docs/rules/collection-type/prefer-iterable-of/)
- **Control flow:** [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/), [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/), [`avoid_empty_catch`](/many_lints/docs/rules/control-flow/avoid-empty-catch/), [`avoid_inverted_boolean_checks`](/many_lints/docs/rules/control-flow/avoid-inverted-boolean-checks/), [`avoid_only_rethrow`](/many_lints/docs/rules/control-flow/avoid-only-rethrow/), [`avoid_throw_in_catch_block`](/many_lints/docs/rules/control-flow/avoid-throw-in-catch-block/), [`no_equal_conditions`](/many_lints/docs/rules/control-flow/no-equal-conditions/), [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/), [`prefer_simpler_patterns_null_check`](/many_lints/docs/rules/control-flow/prefer-simpler-patterns-null-check/), [`prefer_typed_exceptions`](/many_lints/docs/rules/control-flow/prefer-typed-exceptions/), [`proper_super_calls`](/many_lints/docs/rules/control-flow/proper-super-calls/)
- **fpdart:** [`avoid_either_of_future`](/many_lints/docs/rules/fpdart/avoid-either-of-future/), [`avoid_removed_fpdart_api`](/many_lints/docs/rules/fpdart/avoid-removed-fpdart-api/), [`prefer_safe_collection_access`](/many_lints/docs/rules/fpdart/prefer-safe-collection-access/)
- **Hooks:** [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/), [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/)
- **Pattern matching:** [`prefer_wildcard_pattern`](/many_lints/docs/rules/pattern-matching/prefer-wildcard-pattern/)
- **Resource management:** [`avoid_unremovable_callbacks_in_listeners`](/many_lints/docs/rules/resource-management/avoid-unremovable-callbacks-in-listeners/)
- **Riverpod state:** [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/), [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/), [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/), [`avoid_ref_watch_outside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-watch-outside-build/), [`provider_parameters`](/many_lints/docs/rules/riverpod-state/provider-parameters/)
- **State management:** [`avoid_inherited_widget_in_initstate`](/many_lints/docs/rules/state-management/avoid-inherited-widget-in-initstate/), [`avoid_late_context`](/many_lints/docs/rules/state-management/avoid-late-context/), [`avoid_mounted_in_setstate`](/many_lints/docs/rules/state-management/avoid-mounted-in-setstate/), [`avoid_state_constructors`](/many_lints/docs/rules/state-management/avoid-state-constructors/), [`avoid_unnecessary_setstate`](/many_lints/docs/rules/state-management/avoid-unnecessary-setstate/)
- **Testing:** [`avoid_focused_tests`](/many_lints/docs/rules/testing-rules/avoid-focused-tests/), [`avoid_skipped_tests`](/many_lints/docs/rules/testing-rules/avoid-skipped-tests/), [`prefer_correct_test_file_name`](/many_lints/docs/rules/testing-rules/prefer-correct-test-file-name/)
- **Type annotations:** [`prefer_explicit_function_type`](/many_lints/docs/rules/type-annotations/prefer-explicit-function-type/)
- **Widget best practices:** [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/), [`avoid_unnecessary_gesture_detector`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-gesture-detector/), [`pass_existing_future_to_future_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-future-to-future-builder/), [`pass_existing_stream_to_stream_builder`](/many_lints/docs/rules/widget-best-practices/pass-existing-stream-to-stream-builder/), [`use_closest_build_context`](/many_lints/docs/rules/widget-best-practices/use-closest-build-context/), [`use_dedicated_media_query_methods`](/many_lints/docs/rules/widget-best-practices/use-dedicated-media-query-methods/)
- **Widget replacement:** [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/), [`avoid_incorrect_image_opacity`](/many_lints/docs/rules/widget-replacement/avoid-incorrect-image-opacity/), [`prefer_text_rich`](/many_lints/docs/rules/widget-replacement/prefer-text-rich/)

## `opinionated`: one coherent house style

`opinionated` includes `recommended` and chooses a side where several valid
styles exist. It prefers particular widget shapes, collection expressions,
control-flow forms, shorthand syntax, and type-annotation habits. Adopt it when
consistency is worth occasionally disabling a preference that does not fit the
project.

### Rules added by `opinionated` (87)

- **Async safety:** [`avoid_catch_error`](/many_lints/docs/rules/async-safety/avoid-catch-error/), [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/), [`avoid_redundant_async`](/many_lints/docs/rules/async-safety/avoid-redundant-async/), [`check_is_not_closed_after_async_gap`](/many_lints/docs/rules/async-safety/check-is-not-closed-after-async-gap/), [`prefer_correct_future_return_type`](/many_lints/docs/rules/async-safety/prefer-correct-future-return-type/), [`require_atomic_async_updates`](/many_lints/docs/rules/async-safety/require-atomic-async-updates/), [`use_ref_and_state_synchronously`](/many_lints/docs/rules/async-safety/use-ref-and-state-synchronously/), [`use_ref_read_synchronously`](/many_lints/docs/rules/async-safety/use-ref-read-synchronously/)
- **Bloc / Riverpod:** [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/), [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/), [`avoid_public_notifier_properties`](/many_lints/docs/rules/bloc-riverpod/avoid-public-notifier-properties/), [`prefer_bloc_extensions`](/many_lints/docs/rules/bloc-riverpod/prefer-bloc-extensions/), [`prefer_immutable_bloc_state`](/many_lints/docs/rules/bloc-riverpod/prefer-immutable-bloc-state/), [`prefer_multi_bloc_provider`](/many_lints/docs/rules/bloc-riverpod/prefer-multi-bloc-provider/)
- **Class naming:** [`avoid_unnecessary_enum_prefix`](/many_lints/docs/rules/class-naming/avoid-unnecessary-enum-prefix/)
- **Code organization:** [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/), [`avoid_unnecessary_extends`](/many_lints/docs/rules/code-organization/avoid-unnecessary-extends/), [`prefer_abstract_final_static_class`](/many_lints/docs/rules/code-organization/prefer-abstract-final-static-class/), [`prefer_for_loop_in_children`](/many_lints/docs/rules/code-organization/prefer-for-loop-in-children/)
- **Code quality:** [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/), [`avoid_default_tostring`](/many_lints/docs/rules/code-quality/avoid-default-tostring/), [`avoid_non_null_assertion`](/many_lints/docs/rules/code-quality/avoid-non-null-assertion/), [`avoid_todo_comments`](/many_lints/docs/rules/code-quality/avoid-todo-comments/), [`avoid_unnecessary_call`](/many_lints/docs/rules/code-quality/avoid-unnecessary-call/), [`prefer_compute_over_isolate_run`](/many_lints/docs/rules/code-quality/prefer-compute-over-isolate-run/), [`prefer_immediate_return`](/many_lints/docs/rules/code-quality/prefer-immediate-return/), [`prefer_primary_constructors`](/many_lints/docs/rules/code-quality/prefer-primary-constructors/), [`prefer_private_named_parameters`](/many_lints/docs/rules/code-quality/prefer-private-named-parameters/), [`prefer_single_setstate`](/many_lints/docs/rules/code-quality/prefer-single-setstate/)
- **Collections and types:** [`avoid_incomplete_copy_with`](/many_lints/docs/rules/collection-type/avoid-incomplete-copy-with/), [`avoid_missing_enum_constant_in_map`](/many_lints/docs/rules/collection-type/avoid-missing-enum-constant-in-map/), [`avoid_unsafe_collection_methods`](/many_lints/docs/rules/collection-type/avoid-unsafe-collection-methods/), [`prefer_add_all`](/many_lints/docs/rules/collection-type/prefer-add-all/), [`prefer_correct_edge_insets_constructor`](/many_lints/docs/rules/collection-type/prefer-correct-edge-insets-constructor/), [`prefer_correct_json_casts`](/many_lints/docs/rules/collection-type/prefer-correct-json-casts/), [`prefer_overriding_parent_equality`](/many_lints/docs/rules/collection-type/prefer-overriding-parent-equality/)
- **Control flow:** [`avoid_nested_conditional_expressions`](/many_lints/docs/rules/control-flow/avoid-nested-conditional-expressions/), [`avoid_redundant_else`](/many_lints/docs/rules/control-flow/avoid-redundant-else/), [`avoid_unnecessary_continue`](/many_lints/docs/rules/control-flow/avoid-unnecessary-continue/), [`avoid_unnecessary_return`](/many_lints/docs/rules/control-flow/avoid-unnecessary-return/), [`prefer_returning_condition`](/many_lints/docs/rules/control-flow/prefer-returning-condition/), [`prefer_switch_expression`](/many_lints/docs/rules/control-flow/prefer-switch-expression/)
- **fpdart:** [`avoid_future_of_either`](/many_lints/docs/rules/fpdart/avoid-future-of-either/), [`avoid_future_of_option`](/many_lints/docs/rules/fpdart/avoid-future-of-option/), [`prefer_and_then`](/many_lints/docs/rules/fpdart/prefer-and-then/), [`prefer_chain_either`](/many_lints/docs/rules/fpdart/prefer-chain-either/), [`prefer_chaining_over_intermediate_run`](/many_lints/docs/rules/fpdart/prefer-chaining-over-intermediate-run/), [`prefer_do_notation`](/many_lints/docs/rules/fpdart/prefer-do-notation/), [`prefer_from_nullable`](/many_lints/docs/rules/fpdart/prefer-from-nullable/), [`prefer_from_predicate`](/many_lints/docs/rules/fpdart/prefer-from-predicate/), [`prefer_string_parse_extensions`](/many_lints/docs/rules/fpdart/prefer-string-parse-extensions/), [`prefer_task_either_over_try_catch`](/many_lints/docs/rules/fpdart/prefer-task-either-over-try-catch/), [`prefer_unit_over_void`](/many_lints/docs/rules/fpdart/prefer-unit-over-void/)
- **Hooks:** [`prefer_use_callback`](/many_lints/docs/rules/hook-rules/prefer-use-callback/)
- **Pattern matching:** [`avoid_single_field_destructuring`](/many_lints/docs/rules/pattern-matching/avoid-single-field-destructuring/), [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/), [`use_existing_destructuring`](/many_lints/docs/rules/pattern-matching/use-existing-destructuring/), [`use_existing_variable`](/many_lints/docs/rules/pattern-matching/use-existing-variable/)
- **Riverpod state:** [`protected_notifier_properties`](/many_lints/docs/rules/riverpod-state/protected-notifier-properties/)
- **Shorthand patterns:** [`prefer_returning_shorthands`](/many_lints/docs/rules/shorthand-patterns/prefer-returning-shorthands/), [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/), [`prefer_shorthands_with_enums`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-enums/), [`prefer_shorthands_with_static_fields`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-static-fields/)
- **State management:** [`avoid_empty_setstate`](/many_lints/docs/rules/state-management/avoid-empty-setstate/), [`avoid_unnecessary_overrides`](/many_lints/docs/rules/state-management/avoid-unnecessary-overrides/), [`avoid_unnecessary_stateful_widgets`](/many_lints/docs/rules/state-management/avoid-unnecessary-stateful-widgets/), [`prefer_immutable_state`](/many_lints/docs/rules/state-management/prefer-immutable-state/)
- **Testing:** [`prefer_test_matchers`](/many_lints/docs/rules/testing-rules/prefer-test-matchers/)
- **Type annotations:** [`prefer_async_callback`](/many_lints/docs/rules/type-annotations/prefer-async-callback/), [`prefer_type_over_var`](/many_lints/docs/rules/type-annotations/prefer-type-over-var/), [`prefer_void_callback`](/many_lints/docs/rules/type-annotations/prefer-void-callback/)
- **Widget best practices:** [`avoid_shrink_wrap_in_lists`](/many_lints/docs/rules/widget-best-practices/avoid-shrink-wrap-in-lists/), [`avoid_single_child_in_multi_child_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-single-child-in-multi-child-widgets/), [`avoid_unnecessary_consumer_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-consumer-widgets/), [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/), [`check_for_equals_in_render_object_setters`](/many_lints/docs/rules/widget-best-practices/check-for-equals-in-render-object-setters/), [`prefer_single_widget_per_file`](/many_lints/docs/rules/widget-best-practices/prefer-single-widget-per-file/), [`prefer_spacing`](/many_lints/docs/rules/widget-best-practices/prefer-spacing/), [`prefer_theme_mode_getters`](/many_lints/docs/rules/widget-best-practices/prefer-theme-mode-getters/)
- **Widget replacement:** [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/), [`avoid_wrapping_in_padding`](/many_lints/docs/rules/widget-replacement/avoid-wrapping-in-padding/), [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/), [`prefer_center_over_align`](/many_lints/docs/rules/widget-replacement/prefer-center-over-align/), [`prefer_const_border_radius`](/many_lints/docs/rules/widget-replacement/prefer-const-border-radius/), [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/), [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/), [`prefer_sized_box_square`](/many_lints/docs/rules/widget-replacement/prefer-sized-box-square/), [`prefer_transform_over_container`](/many_lints/docs/rules/widget-replacement/prefer-transform-over-container/)

## `pedantic`: uniformity over brevity

`pedantic` includes `opinionated` and treats mechanical consistency as a goal
in its own right. It adds strict naming, one-declaration-per-file organization,
file/type matching, constructor-first member order, alphabetical parameter and
field order, complexity budgets, explicit callback parameter names, and a full
ban on postfix `!` including `map[key]!`.

Use it for codebases that want one predictable shape everywhere and accept
configuration work during adoption. Because a plugin cannot activate Dart SDK
lints, combine it with SDK rules such as `always_specify_types`,
`directives_ordering`, and `public_member_api_docs` for the full strict
style. Avoid pairing `member_ordering` with `sort_constructors_first`: their
constructor-first checks overlap.

### Rules added by `pedantic` (57)

- **Class naming:** [`prefer_boolean_prefixes`](/many_lints/docs/rules/class-naming/prefer-boolean-prefixes/), [`prefer_correct_callback_field_name`](/many_lints/docs/rules/class-naming/prefer-correct-callback-field-name/), [`prefer_correct_error_name`](/many_lints/docs/rules/class-naming/prefer-correct-error-name/), [`prefer_correct_handler_name`](/many_lints/docs/rules/class-naming/prefer-correct-handler-name/), [`prefer_correct_identifier_length`](/many_lints/docs/rules/class-naming/prefer-correct-identifier-length/), [`prefer_correct_setter_parameter_name`](/many_lints/docs/rules/class-naming/prefer-correct-setter-parameter-name/), [`prefer_correct_type_name`](/many_lints/docs/rules/class-naming/prefer-correct-type-name/)
- **Code organization:** [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/), [`enum_constants_ordering`](/many_lints/docs/rules/code-organization/enum-constants-ordering/), [`initializers_ordering`](/many_lints/docs/rules/code-organization/initializers-ordering/), [`map_keys_ordering`](/many_lints/docs/rules/code-organization/map-keys-ordering/), [`match_lib_folder_structure`](/many_lints/docs/rules/code-organization/match-lib-folder-structure/), [`member_ordering`](/many_lints/docs/rules/code-organization/member-ordering/), [`parameters_ordering`](/many_lints/docs/rules/code-organization/parameters-ordering/), [`pattern_fields_ordering`](/many_lints/docs/rules/code-organization/pattern-fields-ordering/), [`prefer_match_file_name`](/many_lints/docs/rules/code-organization/prefer-match-file-name/), [`prefer_single_declaration_per_file`](/many_lints/docs/rules/code-organization/prefer-single-declaration-per-file/), [`record_fields_ordering`](/many_lints/docs/rules/code-organization/record-fields-ordering/)
- **Code quality:** [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/), [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/), [`avoid_deep_nesting`](/many_lints/docs/rules/code-quality/avoid-deep-nesting/), [`avoid_high_cyclomatic_complexity`](/many_lints/docs/rules/code-quality/avoid-high-cyclomatic-complexity/), [`avoid_long_files`](/many_lints/docs/rules/code-quality/avoid-long-files/), [`avoid_long_functions`](/many_lints/docs/rules/code-quality/avoid-long-functions/), [`avoid_long_parameter_list`](/many_lints/docs/rules/code-quality/avoid-long-parameter-list/), [`avoid_too_many_methods`](/many_lints/docs/rules/code-quality/avoid-too-many-methods/), [`max_imports`](/many_lints/docs/rules/code-quality/max-imports/), [`max_statements`](/many_lints/docs/rules/code-quality/max-statements/), [`no_magic_number`](/many_lints/docs/rules/code-quality/no-magic-number/), [`no_magic_string`](/many_lints/docs/rules/code-quality/no-magic-string/), [`prefer_declaring_const_constructor`](/many_lints/docs/rules/code-quality/prefer-declaring-const-constructor/), [`prefer_getter_over_method`](/many_lints/docs/rules/code-quality/prefer-getter-over-method/), [`prefer_moving_to_variable`](/many_lints/docs/rules/code-quality/prefer-moving-to-variable/), [`prefer_named_parameters`](/many_lints/docs/rules/code-quality/prefer-named-parameters/)
- **Collections and types:** [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/), [`prefer_class_destructuring`](/many_lints/docs/rules/collection-type/prefer-class-destructuring/)
- **Control flow:** [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/), [`avoid_unused_after_null_check`](/many_lints/docs/rules/control-flow/avoid-unused-after-null-check/), [`no_equal_switch_case`](/many_lints/docs/rules/control-flow/no-equal-switch-case/), [`prefer_conditional_expressions`](/many_lints/docs/rules/control-flow/prefer-conditional-expressions/), [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/)
- **Formatting:** [`avoid_inconsistent_digit_separators`](/many_lints/docs/rules/formatting/avoid-inconsistent-digit-separators/), [`double_literal_format`](/many_lints/docs/rules/formatting/double-literal-format/), [`format_comment`](/many_lints/docs/rules/formatting/format-comment/)
- **fpdart:** [`avoid_get_or_else_swallowing_failure`](/many_lints/docs/rules/fpdart/avoid-get-or-else-swallowing-failure/), [`avoid_unnecessary_option`](/many_lints/docs/rules/fpdart/avoid-unnecessary-option/)
- **Hooks:** [`prefer_use_prefix`](/many_lints/docs/rules/hook-rules/prefer-use-prefix/)
- **Pattern matching:** [`avoid_wildcard_cases_with_enums`](/many_lints/docs/rules/pattern-matching/avoid-wildcard-cases-with-enums/)
- **Shorthand patterns:** [`avoid_nested_shorthands`](/many_lints/docs/rules/shorthand-patterns/avoid-nested-shorthands/)
- **Type annotations:** [`prefer_explicit_parameter_names`](/many_lints/docs/rules/type-annotations/prefer-explicit-parameter-names/), [`prefer_typedefs_for_callbacks`](/many_lints/docs/rules/type-annotations/prefer-typedefs-for-callbacks/)
- **Widget best practices:** [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/), [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/), [`never_discard_build_context`](/many_lints/docs/rules/widget-best-practices/never-discard-build-context/), [`prefer_extracting_callbacks`](/many_lints/docs/rules/widget-best-practices/prefer-extracting-callbacks/), [`prefer_widget_private_members`](/many_lints/docs/rules/widget-best-practices/prefer-widget-private-members/), [`use_sliver_prefix`](/many_lints/docs/rules/widget-best-practices/use-sliver-prefix/)

## Rules outside every preset (18)

Some rules need project-specific vocabulary, assume an optional dependency,
enforce the opposite of a convention selected by `opinionated`, or are
deliberately opt-in conventions. They remain available by name so presets never
guess package dependencies, silently do nothing without required options,
overreach into project-specific taste, or enable fixes that undo one another.

- **Architecture:** [`avoid_banned_annotations`](/many_lints/docs/rules/architecture/avoid-banned-annotations/), [`avoid_banned_exports`](/many_lints/docs/rules/architecture/avoid-banned-exports/), [`avoid_banned_imports`](/many_lints/docs/rules/architecture/avoid-banned-imports/), [`avoid_banned_names`](/many_lints/docs/rules/architecture/avoid-banned-names/), [`avoid_banned_types`](/many_lints/docs/rules/architecture/avoid-banned-types/), [`banned_usage`](/many_lints/docs/rules/architecture/banned-usage/)
- **Class naming:** [`match_class_name_pattern`](/many_lints/docs/rules/class-naming/match-class-name-pattern/), [`prefer_prefixed_global_constants`](/many_lints/docs/rules/class-naming/prefer-prefixed-global-constants/), [`use_class_prefix`](/many_lints/docs/rules/class-naming/use-class-prefix/), [`use_class_suffix`](/many_lints/docs/rules/class-naming/use-class-suffix/)
- **Code quality:** [`match_pattern`](/many_lints/docs/rules/code-quality/match-pattern/)
- **Collections and types:** [`list_all_equatable_fields`](/many_lints/docs/rules/collection-type/list-all-equatable-fields/)
- **fpdart:** [`avoid_ad_hoc_left_type`](/many_lints/docs/rules/fpdart/avoid-ad-hoc-left-type/)
- **Testing:** [`format_test_name`](/many_lints/docs/rules/testing-rules/format-test-name/), [`require_mirror_test`](/many_lints/docs/rules/testing-rules/require-mirror-test/)
- **Type annotations:** [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/), [`prefer_explicit_type_arguments`](/many_lints/docs/rules/type-annotations/prefer-explicit-type-arguments/)
- **Widget best practices:** [`use_gap`](/many_lints/docs/rules/widget-best-practices/use-gap/)
- **Widget replacement:** [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/)

## Moving between presets

Moving upward only adds rules: `core ⊂ recommended ⊂ opinionated ⊂ pedantic`.
An explicit per-rule `enabled:` value always wins, so a project can adopt a
tier and document its few intentional exceptions:

```yaml
# many_lints.yaml
preset: pedantic
rules:
  avoid_long_functions:
    max_lines: 80
  prefer_spacing:
    enabled: false
  use_gap:
    enabled: true
```

See [Configuration](/many_lints/docs/configuration/) for option precedence,
per-rule exclusions, diagnostic severity, and both supported config locations.

<!-- Generated by scripts/update-documentation-catalogs.mjs. -->
