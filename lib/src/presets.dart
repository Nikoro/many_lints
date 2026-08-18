/// Curated rule sets, selected by `preset:` in `many_lints.yaml` or the
/// top-level `many_lints:` section of `analysis_options.yaml`.
///
/// ## Why presets are resolved by this package rather than by `include:`
///
/// The official lint packages ship presets as YAML that consumers pull in with
/// `include: package:lints/recommended.yaml`. That works because their rules
/// live under the `linter:` key, which the analyzer parses and *merges* across
/// an include graph.
///
/// Plugin rules cannot use that channel. They are configured under
/// `plugins: many_lints: diagnostics:`, and `_applyPlugins` in the analyzer's
/// options parser merges plugin configurations keyed by plugin name, where a
/// later configuration **replaces** an earlier one outright:
///
/// ```dart
/// for (var configuration in plugins.configurations) {
///   configurations[configuration.name] = configuration;   // replace
/// }
/// ```
///
/// So an included preset would be silently discarded the moment a consumer
/// writes its own `plugins: many_lints:` block — which it must, to declare the
/// plugin version at all. `diagnostics:` is also validated to accept only
/// severity scalars, leaving no room for a preset or group key.
///
/// Presets therefore resolve here, through the same configuration file that
/// already carries `rules:`, `exclude`, `include` and `message`.
library;

/// The name of every rule in this package that reports a near-certain bug.
///
/// The bar is deliberately high, matching `package:lints/core.yaml`: a rule
/// belongs here only when what it flags is dead, contradictory, unreachable or
/// guaranteed to misbehave at runtime, with no stylistic judgement and
/// essentially no false positives.
const coreRules = <String>{
  'always_pass_global_key',
  'always_remove_listener',
  'async_value_nullable_pattern',
  'avoid_bare_await_in_do',
  'avoid_collection_equality_checks',
  'avoid_collection_methods_with_unrelated_types',
  'avoid_conditional_hooks',
  'avoid_constant_conditions',
  'avoid_constant_switches',
  'avoid_contradictory_expressions',
  'avoid_dollar_outside_do_frame',
  'avoid_duplicate_bloc_event_handlers',
  'avoid_duplicate_cascades',
  'avoid_equal_expressions',
  'avoid_self_compare',
  'avoid_flexible_outside_flex',
  'avoid_late_final_reassignment',
  'avoid_misused_test_matchers',
  'avoid_nested_do_notation',
  'avoid_nested_futures',
  'avoid_recursive_widget_calls',
  'avoid_shadowed_extension_methods',
  'avoid_throw_in_fp_callback',
  'avoid_unassigned_stream_subscriptions',
  'avoid_unmodified_loop_condition',
  'avoid_unnecessary_negations',
  'avoid_unrelated_type_casts',
  'avoid_unrun_task',
  'avoid_untyped_safe_cast',
  'dispose_fields',
  'emit_new_bloc_state_instances',
  'missing_provider_scope',
  'notifier_build',
  'prefer_expect_later',
  'prefer_return_await',
};

/// Rules that [recommendedRules] adds on top of [coreRules].
///
/// These catch likely defects and concrete runtime risks that are not certain
/// enough for [coreRules]. Rules that merely prefer an equivalent spelling,
/// impose an architecture or naming scheme, or enforce a performance style
/// are deliberately excluded, as are rules that do nothing until configured.
const _recommendedOnlyRules = <String>{
  'avoid_accessing_collections_by_constant_index',
  'avoid_build_context_in_providers',
  'avoid_cascade_after_if_null',
  'avoid_collapsible_if',
  'avoid_duplicate_mixins',
  'avoid_either_of_future',
  'avoid_empty_catch',
  'avoid_empty_spread',
  'avoid_exit_outside_entrypoint',
  'avoid_expanded_as_spacer',
  'avoid_focused_tests',
  'avoid_future_ignore',
  'avoid_generics_shadowing',
  'avoid_hooks_outside_build',
  'avoid_incorrect_image_opacity',
  'avoid_inherited_widget_in_initstate',
  'avoid_inverted_boolean_checks',
  'avoid_late_context',
  'avoid_map_keys_contains',
  'avoid_missing_completer_stack_trace',
  'avoid_misused_hooks',
  'avoid_mounted_in_setstate',
  'avoid_not_encodable_in_to_json',
  'avoid_notifier_constructors',
  'avoid_only_rethrow',
  'avoid_passing_build_context_to_blocs',
  'avoid_removed_fpdart_api',
  'avoid_ref_inside_state_dispose',
  'avoid_ref_read_inside_build',
  'avoid_ref_watch_outside_build',
  'avoid_returning_widgets',
  'avoid_skipped_tests',
  'avoid_state_constructors',
  'avoid_throw_in_catch_block',
  'avoid_unnecessary_gesture_detector',
  'avoid_unnecessary_setstate',
  'avoid_unremovable_callbacks_in_listeners',
  'dispose_provided_instances',
  'function_always_returns_null',
  'function_always_returns_same_value',
  'handle_bloc_event_subclasses',
  'match_getter_setter_field_names',
  'no_equal_conditions',
  'no_equal_then_else',
  'pass_existing_future_to_future_builder',
  'pass_existing_stream_to_stream_builder',
  'prefer_any_or_every',
  'prefer_correct_test_file_name',
  'prefer_enums_by_name',
  'prefer_explicit_function_type',
  'prefer_iterable_of',
  'prefer_safe_collection_access',
  'prefer_simpler_patterns_null_check',
  'prefer_text_rich',
  'prefer_typed_exceptions',
  'prefer_wildcard_pattern',
  'proper_super_calls',
  'provider_parameters',
  'use_closest_build_context',
  'use_dedicated_media_query_methods',
  'use_setstate_synchronously',
};

/// [coreRules] plus everything in [_recommendedOnlyRules].
///
/// Layered the same way `package:lints/recommended.yaml` includes
/// `core.yaml`, so moving up a tier only ever adds rules.
final recommendedRules = <String>{...coreRules, ..._recommendedOnlyRules};

/// Rules that [opinionatedRules] adds on top of [recommendedRules].
///
/// These express a stylistic preference rather than a defect: reasonable
/// codebases disagree about them. Every rule here is one this package takes a
/// side on.
///
/// The side it takes is a concrete one: this tier is a coherent house style, so
/// adopting it should make a codebase look a particular way rather than hand it
/// an assortment of unrelated opinions. The test for adding a rule here is
/// empirical — run it against real production codebases and keep it only if
/// what it reports is code they would actually change. A rule that fights an
/// established style belongs in no preset and stays opt-in by name, which is
/// also the honest default whenever the answer is unclear.
///
/// Three kinds of rule are deliberately **excluded**, and stay opt-in by name:
///
/// 1. **Rules that contradict one in this set.** A preset must never enable
///    both halves of a disagreement, because each would undo the other's fix.
///    See [conflictingWithOpinionated].
/// 2. **Rules that do nothing until configured** — the `banned_*` family,
///    `use_class_prefix`-style affix rules and `prefer_use_prefix`. They enforce
///    *your* project's vocabulary, which this package cannot guess, and report
///    nothing at all until told what to look for.
/// 3. **Rules that assume a package this project may not depend on**, such as
///    `use_gap` (the `gap` package) or the `equatable` rules.
///
/// The same reasoning keeps three fpdart rules out: `avoid_ad_hoc_left_type`
/// reports nothing until given `error_types`, while
/// `avoid_unnecessary_option` and `avoid_get_or_else_swallowing_failure` each
/// disagree with a coherent choice a codebase may have made deliberately.
const _opinionatedOnlyRules = <String>{
  'avoid_bloc_public_methods',
  'avoid_border_all',
  'avoid_catch_error',
  'avoid_commented_out_code',
  'avoid_default_tostring',
  'avoid_empty_setstate',
  'avoid_future_of_either',
  'avoid_future_of_option',
  'avoid_incomplete_copy_with',
  'avoid_missing_enum_constant_in_map',
  'avoid_non_null_assertion',
  'avoid_passing_async_when_sync_expected',
  'avoid_passing_bloc_to_bloc',
  'avoid_public_notifier_properties',
  'avoid_redundant_async',
  'avoid_redundant_else',
  'avoid_shrink_wrap_in_lists',
  'avoid_single_child_in_multi_child_widgets',
  'avoid_single_field_destructuring',
  'avoid_todo_comments',
  'avoid_unnecessary_call',
  'avoid_unnecessary_consumer_widgets',
  'avoid_unnecessary_constructor',
  'avoid_unnecessary_continue',
  'avoid_unnecessary_enum_prefix',
  'avoid_unnecessary_extends',
  'avoid_unnecessary_hook_widgets',
  'avoid_unnecessary_overrides',
  'avoid_unnecessary_return',
  'avoid_unnecessary_stateful_widgets',
  'avoid_unsafe_collection_methods',
  'avoid_wrapping_in_padding',
  'check_for_equals_in_render_object_setters',
  'check_is_not_closed_after_async_gap',
  'prefer_abstract_final_static_class',
  'prefer_align_over_container',
  'prefer_async_callback',
  'prefer_bloc_extensions',
  'prefer_center_over_align',
  'prefer_chain_either',
  'prefer_chaining_over_intermediate_run',
  'prefer_compute_over_isolate_run',
  'prefer_const_border_radius',
  'prefer_constrained_box_over_container',
  'prefer_correct_edge_insets_constructor',
  'prefer_correct_future_return_type',
  'prefer_correct_json_casts',
  'prefer_do_notation',
  'prefer_for_loop_in_children',
  'prefer_from_nullable',
  'prefer_from_predicate',
  'prefer_immediate_return',
  'prefer_immutable_bloc_state',
  'prefer_immutable_state',
  'avoid_nested_conditional_expressions',
  'prefer_add_all',
  'prefer_multi_bloc_provider',
  'prefer_overriding_parent_equality',
  'prefer_padding_over_container',
  'prefer_primary_constructors',
  'prefer_private_named_parameters',
  'prefer_returning_condition',
  'prefer_returning_shorthands',
  'prefer_shorthands_with_constructors',
  'prefer_shorthands_with_enums',
  'prefer_shorthands_with_static_fields',
  'prefer_single_setstate',
  'prefer_single_widget_per_file',
  'prefer_sized_box_square',
  'prefer_spacing',
  'prefer_string_parse_extensions',
  'prefer_switch_expression',
  'prefer_switch_with_enums',
  'prefer_task_either_over_try_catch',
  'prefer_test_matchers',
  'prefer_theme_mode_getters',
  'prefer_transform_over_container',
  'prefer_type_over_var',
  'prefer_unit_over_void',
  'prefer_use_callback',
  'prefer_void_callback',
  'protected_notifier_properties',
  'require_atomic_async_updates',
  'use_existing_destructuring',
  'use_existing_variable',
  'use_ref_and_state_synchronously',
  'use_ref_read_synchronously',
};

/// Rules deliberately kept out of [opinionatedRules] because each contradicts
/// a rule that is in it.
///
/// Enabling both halves would leave a project with two diagnostics on one line
/// whose fixes undo one another, so the preset takes a side and the other half
/// stays available by name.
///
/// - `prefer_container` merges nested single-purpose widgets *into* a
///   `Container`, which is the exact inverse of `prefer_padding_over_container`
///   and its `prefer_*_over_container` siblings.
/// - `use_gap` replaces a spacing `SizedBox` with the `gap` package's `Gap`,
///   while `prefer_spacing` replaces the same `SizedBox` with the built-in
///   `spacing:` argument. Both match on `sizedBoxChecker` inside a flex.
/// - `list_all_equatable_fields` and `prefer_equatable_mixin` presume a
///   dependency on `equatable`, so they are opt-in rather than contradictory.
/// Public so a test can assert the preset never enables one of these, keeping
/// the exclusions a checked invariant rather than a comment that drifts.
const conflictingWithOpinionated = <String>{'prefer_container', 'use_gap'};

/// [recommendedRules] plus [_opinionatedOnlyRules].
///
/// Layered like the tiers below it, so moving up a preset only ever adds rules.
final opinionatedRules = <String>{
  ...recommendedRules,
  ..._opinionatedOnlyRules,
};

/// Rules that [pedanticRules] adds on top of [opinionatedRules].
///
/// This tier deliberately optimizes for uniformity and explicitness rather
/// than for a quiet signal. It enables structural budgets, naming rules and
/// mechanical ordering that are too restrictive for a general-purpose house
/// style, but useful in a codebase that wants every file to follow one shape.
///
/// Rules that need project vocabulary, introduce a package dependency or
/// contradict a rule selected below still remain opt-in. In particular, a
/// preset cannot guess banned APIs or class affixes, cannot assume `equatable`
/// or `gap`, and must not enable `prefer_container` beside the rules that
/// unwrap a `Container`.
const _pedanticOnlyRules = <String>{
  'arguments_ordering',
  'avoid_accessing_other_classes_private_members',
  'avoid_complex_conditions',
  'avoid_deep_nesting',
  'avoid_deep_widget_nesting',
  'avoid_duplicate_collection_elements',
  'avoid_get_or_else_swallowing_failure',
  'avoid_high_cyclomatic_complexity',
  'avoid_inconsistent_digit_separators',
  'avoid_long_files',
  'avoid_long_functions',
  'avoid_long_parameter_list',
  'avoid_negated_conditions',
  'avoid_nested_shorthands',
  'avoid_too_many_methods',
  'avoid_too_many_widgets_per_build',
  'avoid_unnecessary_option',
  'avoid_unused_after_null_check',
  'avoid_wildcard_cases_with_enums',
  'double_literal_format',
  'enum_constants_ordering',
  'format_comment',
  'initializers_ordering',
  'map_keys_ordering',
  'match_lib_folder_structure',
  'max_imports',
  'max_statements',
  'member_ordering',
  'never_discard_build_context',
  'no_equal_switch_case',
  'no_magic_number',
  'no_magic_string',
  'parameters_ordering',
  'pattern_fields_ordering',
  'prefer_boolean_prefixes',
  'prefer_class_destructuring',
  'prefer_conditional_expressions',
  'prefer_correct_callback_field_name',
  'prefer_correct_error_name',
  'prefer_correct_handler_name',
  'prefer_correct_identifier_length',
  'prefer_correct_setter_parameter_name',
  'prefer_correct_type_name',
  'prefer_declaring_const_constructor',
  'prefer_early_return',
  'prefer_explicit_parameter_names',
  'prefer_extracting_callbacks',
  'prefer_getter_over_method',
  'prefer_match_file_name',
  'prefer_moving_to_variable',
  'prefer_named_parameters',
  'prefer_single_declaration_per_file',
  'prefer_typedefs_for_callbacks',
  'prefer_use_prefix',
  'prefer_widget_private_members',
  'record_fields_ordering',
  'use_sliver_prefix',
};

/// [opinionatedRules] plus [_pedanticOnlyRules].
final pedanticRules = <String>{...opinionatedRules, ..._pedanticOnlyRules};

/// Option defaults supplied by the strictest preset.
///
/// A user's per-rule options override these values. Keeping the defaults here
/// makes `preset: pedantic` complete on its own: ordering rules that are
/// intentionally silent in lower presets receive an actual policy here.
const pedanticRuleOptions = <String, Map<String, Object?>>{
  'arguments_ordering': {'order': 'alphabetical', 'min_arguments': 2},
  'avoid_non_null_assertion': {'ignore_map_indexes': false},
  'enum_constants_ordering': {'order': 'alphabetical'},
  'map_keys_ordering': {'order': 'alphabetical'},
  'parameters_ordering': {
    'order': 'alphabetical',
    'group_required': true,
    'min_parameters': 2,
  },
  'pattern_fields_ordering': {'order': 'alphabetical'},
  'prefer_explicit_parameter_names': {'min_parameters': 1},
  'prefer_single_declaration_per_file': {'ignore_private': false},
  'record_fields_ordering': {'order': 'alphabetical'},
};

/// A named rule set that a project can select with `preset:`.
enum Preset {
  /// Enables nothing. The default, and the explicit way to opt out.
  none('none'),

  /// Near-certain bugs only.
  core('core'),

  /// [core] plus idiomatic, uncontroversial Dart and Flutter practice.
  recommended('recommended'),

  /// [recommended] plus the opinionated style rules this package prefers.
  opinionated('opinionated'),

  /// [opinionated] plus strict naming, structure and ordering conventions.
  pedantic('pedantic');

  const Preset(this.name);

  /// The spelling used in configuration.
  final String name;

  /// The preset applied when a project selects none.
  ///
  /// Rules are opt-in: a bare install reports nothing until a preset is chosen
  /// or individual rules are enabled.
  static const fallback = Preset.none;

  /// Parses [value] as written in configuration, returning `null` when it
  /// names no known preset.
  ///
  /// An unknown name is rejected here so the caller can fall back rather than
  /// throw: configuration problems cannot be surfaced as diagnostics, so they
  /// have to degrade quietly.
  static Preset? parse(String value) {
    for (final preset in Preset.values) {
      if (preset.name == value) return preset;
    }
    return null;
  }

  /// Whether [ruleName] is enabled by this preset.
  bool enables(String ruleName) => switch (this) {
    Preset.none => false,
    Preset.core => coreRules.contains(ruleName),
    Preset.recommended => recommendedRules.contains(ruleName),
    Preset.opinionated => opinionatedRules.contains(ruleName),
    Preset.pedantic => pedanticRules.contains(ruleName),
  };

  /// Built-in rule options supplied by this preset.
  Map<String, Object?> optionsFor(String ruleName) => switch (this) {
    Preset.pedantic => pedanticRuleOptions[ruleName] ?? const {},
    _ => const {},
  };
}
