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
  'avoid_flexible_outside_flex',
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
  'avoid_unremovable_callbacks_in_listeners',
  'avoid_unrun_task',
  'avoid_untyped_safe_cast',
  'avoid_unused_after_null_check',
  'dispose_fields',
  'emit_new_bloc_state_instances',
  'function_always_returns_null',
  'missing_provider_scope',
  'no_equal_then_else',
  'notifier_build',
  'prefer_expect_later',
  'prefer_return_await',
};

/// Rules that [recommendedRules] adds on top of [coreRules].
///
/// These enforce idiomatic, widely-agreed Dart and Flutter practice, or catch
/// likely-but-not-certain mistakes. Rules that impose an architecture, a naming
/// scheme or a contested style choice are deliberately excluded, as are rules
/// that do nothing until configured.
const _recommendedOnlyRules = <String>{
  'avoid_accessing_collections_by_constant_index',
  'avoid_build_context_in_providers',
  'avoid_cascade_after_if_null',
  'avoid_catch_error',
  'avoid_collapsible_if',
  'avoid_duplicate_collection_elements',
  'avoid_either_of_future',
  'avoid_empty_spread',
  'avoid_expanded_as_spacer',
  'avoid_future_of_either',
  'avoid_future_of_option',
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
  'avoid_nested_shorthands',
  'avoid_not_encodable_in_to_json',
  'avoid_notifier_constructors',
  'avoid_only_rethrow',
  'avoid_passing_build_context_to_blocs',
  'avoid_removed_fpdart_api',
  'avoid_ref_inside_state_dispose',
  'avoid_ref_read_inside_build',
  'avoid_ref_watch_outside_build',
  'avoid_state_constructors',
  'avoid_throw_in_catch_block',
  'avoid_unnecessary_gesture_detector',
  'avoid_unnecessary_setstate',
  'avoid_wildcard_cases_with_enums',
  'check_for_equals_in_render_object_setters',
  'dispose_provided_instances',
  'handle_bloc_event_subclasses',
  'pass_existing_future_to_future_builder',
  'pass_existing_stream_to_stream_builder',
  'prefer_add_all',
  'prefer_any_or_every',
  'prefer_chain_either',
  'prefer_chaining_over_intermediate_run',
  'prefer_correct_json_casts',
  'prefer_do_notation',
  'prefer_enums_by_name',
  'prefer_explicit_function_type',
  'prefer_from_nullable',
  'prefer_from_predicate',
  'prefer_iterable_of',
  'prefer_safe_collection_access',
  'prefer_simpler_patterns_null_check',
  'prefer_string_parse_extensions',
  'prefer_task_either_over_try_catch',
  'prefer_text_rich',
  'prefer_unit_over_void',
  'prefer_wildcard_pattern',
  'proper_super_calls',
  'provider_parameters',
  'use_closest_build_context',
  'use_dedicated_media_query_methods',
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
  'avoid_commented_out_code',
  'avoid_default_tostring',
  'avoid_empty_setstate',
  'avoid_incomplete_copy_with',
  'avoid_missing_enum_constant_in_map',
  'avoid_non_null_assertion',
  'avoid_passing_async_when_sync_expected',
  'avoid_passing_bloc_to_bloc',
  'avoid_public_notifier_properties',
  'avoid_redundant_else',
  'avoid_returning_widgets',
  'avoid_shrink_wrap_in_lists',
  'avoid_single_child_in_multi_child_widgets',
  'avoid_single_field_destructuring',
  'avoid_unnecessary_consumer_widgets',
  'avoid_unnecessary_hook_widgets',
  'avoid_unnecessary_overrides',
  'avoid_unnecessary_overrides_in_state',
  'avoid_unnecessary_stateful_widgets',
  'avoid_unsafe_collection_methods',
  'avoid_wrapping_in_padding',
  'check_is_not_closed_after_async_gap',
  'never_discard_build_context',
  'prefer_abstract_final_static_class',
  'prefer_align_over_container',
  'prefer_async_callback',
  'prefer_bloc_extensions',
  'prefer_center_over_align',
  'prefer_class_destructuring',
  'prefer_compute_over_isolate_run',
  'prefer_const_border_radius',
  'prefer_constrained_box_over_container',
  'prefer_correct_edge_insets_constructor',
  'prefer_for_loop_in_children',
  'prefer_immediate_return',
  'prefer_immutable_bloc_state',
  'prefer_multi_bloc_provider',
  'prefer_overriding_parent_equality',
  'prefer_padding_over_container',
  'prefer_primary_constructors',
  'prefer_private_named_parameters',
  'prefer_returning_shorthands',
  'prefer_shorthands_with_constructors',
  'prefer_shorthands_with_enums',
  'prefer_shorthands_with_static_fields',
  'prefer_single_setstate',
  'prefer_single_widget_per_file',
  'prefer_sized_box_square',
  'prefer_spacing',
  'prefer_switch_expression',
  'prefer_switch_with_enums',
  'prefer_test_matchers',
  'prefer_theme_mode_getters',
  'prefer_transform_over_container',
  'prefer_type_over_var',
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

/// A named rule set that a project can select with `preset:`.
enum Preset {
  /// Enables nothing. The default, and the explicit way to opt out.
  none('none'),

  /// Near-certain bugs only.
  core('core'),

  /// [core] plus idiomatic, uncontroversial Dart and Flutter practice.
  recommended('recommended'),

  /// [recommended] plus the opinionated style rules this package prefers.
  opinionated('opinionated');

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
  };
}
