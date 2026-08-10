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
  'avoid_collection_equality_checks',
  'avoid_collection_methods_with_unrelated_types',
  'avoid_conditional_hooks',
  'avoid_constant_conditions',
  'avoid_constant_switches',
  'avoid_contradictory_expressions',
  'avoid_duplicate_bloc_event_handlers',
  'avoid_duplicate_cascades',
  'avoid_equal_expressions',
  'avoid_flexible_outside_flex',
  'avoid_misused_test_matchers',
  'avoid_nested_futures',
  'avoid_recursive_widget_calls',
  'avoid_shadowed_extension_methods',
  'avoid_unassigned_stream_subscriptions',
  'avoid_unmodified_loop_condition',
  'avoid_unnecessary_negations',
  'avoid_unrelated_type_casts',
  'avoid_unremovable_callbacks_in_listeners',
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
  'avoid_empty_spread',
  'avoid_expanded_as_spacer',
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
  'prefer_correct_json_casts',
  'prefer_enums_by_name',
  'prefer_explicit_function_type',
  'prefer_iterable_of',
  'prefer_simpler_patterns_null_check',
  'prefer_text_rich',
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

/// A named rule set that a project can select with `preset:`.
enum Preset {
  /// Enables nothing. The default, and the explicit way to opt out.
  none('none'),

  /// Near-certain bugs only.
  core('core'),

  /// [core] plus idiomatic, uncontroversial Dart and Flutter practice.
  recommended('recommended'),

  /// Every rule in the package, including opinionated ones.
  ///
  /// Offered so that a project can deliberately choose the whole catalogue in
  /// one line, rather than having to restate 156 rule names.
  all('all');

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
    Preset.all => true,
  };
}
