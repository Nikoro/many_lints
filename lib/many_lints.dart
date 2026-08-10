/// Many Lints - A collection of useful lint rules for Dart and Flutter.
///
/// This package provides custom lint rules, quick fixes, and code assists
/// that integrate with the Dart analyzer and IDEs.
///
/// ## Usage
///
/// Add `many_lints` to the top-level `plugins` section in your
/// `analysis_options.yaml`:
///
/// ```yaml
/// plugins:
///   many_lints: ^0.9.0
/// ```
///
/// The analysis server will automatically download and resolve the plugin
/// from [pub.dev](https://pub.dev/packages/many_lints). There is no need
/// to add it to your `pubspec.yaml`.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
// ignore: implementation_imports
import 'package:analysis_server_plugin/src/plugin_server.dart';
// ignore: implementation_imports
import 'package:analysis_server_plugin/src/registry.dart' as plugin_registry;
import 'package:analyzer/analysis_rule/analysis_rule.dart';

// Rules
import 'package:many_lints/src/rules/always_remove_listener.dart';
import 'package:many_lints/src/rules/always_pass_global_key.dart';
import 'package:many_lints/src/rules/avoid_bloc_public_methods.dart';
import 'package:many_lints/src/rules/avoid_passing_async_when_sync_expected.dart';
import 'package:many_lints/src/rules/avoid_passing_bloc_to_bloc.dart';
import 'package:many_lints/src/rules/avoid_passing_build_context_to_blocs.dart';
import 'package:many_lints/src/rules/prefer_bloc_extensions.dart';
import 'package:many_lints/src/rules/prefer_immutable_bloc_state.dart';
import 'package:many_lints/src/rules/prefer_multi_bloc_provider.dart';
import 'package:many_lints/src/rules/avoid_cascade_after_if_null.dart';
import 'package:many_lints/src/rules/avoid_conditional_hooks.dart';
import 'package:many_lints/src/rules/avoid_border_all.dart';
import 'package:many_lints/src/rules/avoid_expanded_as_spacer.dart';
import 'package:many_lints/src/rules/avoid_returning_widgets.dart';
import 'package:many_lints/src/rules/prefer_async_callback.dart';
import 'package:many_lints/src/rules/prefer_compute_over_isolate_run.dart';
import 'package:many_lints/src/rules/prefer_const_border_radius.dart';
import 'package:many_lints/src/rules/prefer_correct_json_casts.dart';
import 'package:many_lints/src/rules/avoid_wrapping_in_padding.dart';
import 'package:many_lints/src/rules/prefer_constrained_box_over_container.dart';
import 'package:many_lints/src/rules/avoid_shadowed_extension_methods.dart';
import 'package:many_lints/src/rules/avoid_shrink_wrap_in_lists.dart';
import 'package:many_lints/src/rules/avoid_not_encodable_in_to_json.dart';
import 'package:many_lints/src/rules/avoid_notifier_constructors.dart';
import 'package:many_lints/src/rules/avoid_public_notifier_properties.dart';
import 'package:many_lints/src/rules/function_always_returns_null.dart';
import 'package:many_lints/src/rules/handle_bloc_event_subclasses.dart';
import 'package:many_lints/src/rules/missing_provider_scope.dart';
import 'package:many_lints/src/rules/protected_notifier_properties.dart';
import 'package:many_lints/src/rules/provider_parameters.dart';
import 'package:many_lints/src/rules/async_value_nullable_pattern.dart';
import 'package:many_lints/src/rules/no_equal_then_else.dart';
import 'package:many_lints/src/rules/notifier_build.dart';
import 'package:many_lints/src/rules/avoid_build_context_in_providers.dart';
import 'package:many_lints/src/rules/avoid_ref_inside_state_dispose.dart';
import 'package:many_lints/src/rules/avoid_ref_read_inside_build.dart';
import 'package:many_lints/src/rules/avoid_ref_watch_outside_build.dart';
import 'package:many_lints/src/rules/avoid_collapsible_if.dart';
import 'package:many_lints/src/rules/avoid_default_tostring.dart';
import 'package:many_lints/src/rules/avoid_duplicate_collection_elements.dart';
import 'package:many_lints/src/rules/avoid_nested_futures.dart';
import 'package:many_lints/src/rules/prefer_switch_with_enums.dart';
import 'package:many_lints/src/rules/prefer_add_all.dart';
import 'package:many_lints/src/rules/prefer_immediate_return.dart';
import 'package:many_lints/src/rules/avoid_empty_spread.dart';
import 'package:many_lints/src/rules/avoid_inverted_boolean_checks.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_negations.dart';
import 'package:many_lints/src/rules/avoid_equal_expressions.dart';
import 'package:many_lints/src/rules/avoid_wildcard_cases_with_enums.dart';
import 'package:many_lints/src/rules/avoid_duplicate_bloc_event_handlers.dart';
import 'package:many_lints/src/rules/avoid_redundant_else.dart';
import 'package:many_lints/src/rules/avoid_missing_enum_constant_in_map.dart';
import 'package:many_lints/src/rules/avoid_unmodified_loop_condition.dart';
import 'package:many_lints/src/rules/avoid_unrelated_type_casts.dart';
import 'package:many_lints/src/rules/avoid_unused_after_null_check.dart';
import 'package:many_lints/src/rules/avoid_unsafe_collection_methods.dart';
import 'package:many_lints/src/rules/avoid_empty_setstate.dart';
import 'package:many_lints/src/rules/check_for_equals_in_render_object_setters.dart';
import 'package:many_lints/src/rules/check_is_not_closed_after_async_gap.dart';
import 'package:many_lints/src/rules/avoid_hooks_outside_build.dart';
import 'package:many_lints/src/rules/avoid_late_context.dart';
import 'package:many_lints/src/rules/avoid_missing_completer_stack_trace.dart';
import 'package:many_lints/src/rules/avoid_misused_hooks.dart';
import 'package:many_lints/src/rules/avoid_inherited_widget_in_initstate.dart';
import 'package:many_lints/src/rules/avoid_recursive_widget_calls.dart';
import 'package:many_lints/src/rules/pass_existing_future_to_future_builder.dart';
import 'package:many_lints/src/rules/pass_existing_stream_to_stream_builder.dart';
import 'package:many_lints/src/rules/dispose_provided_instances.dart';
import 'package:many_lints/src/rules/avoid_state_constructors.dart';
import 'package:many_lints/src/rules/avoid_single_field_destructuring.dart';
import 'package:many_lints/src/rules/avoid_flexible_outside_flex.dart';
import 'package:many_lints/src/rules/avoid_constant_conditions.dart';
import 'package:many_lints/src/rules/avoid_duplicate_cascades.dart';
import 'package:many_lints/src/rules/avoid_contradictory_expressions.dart';
import 'package:many_lints/src/rules/avoid_constant_switches.dart';
import 'package:many_lints/src/rules/avoid_commented_out_code.dart';
import 'package:many_lints/src/rules/avoid_collection_equality_checks.dart';
import 'package:many_lints/src/rules/dispose_fields.dart';
import 'package:many_lints/src/rules/emit_new_bloc_state_instances.dart';
import 'package:many_lints/src/rules/avoid_incomplete_copy_with.dart';
import 'package:many_lints/src/rules/avoid_incorrect_image_opacity.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_gesture_detector.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_overrides.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_setstate.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_overrides_in_state.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_stateful_widgets.dart';
import 'package:many_lints/src/rules/avoid_mounted_in_setstate.dart';
import 'package:many_lints/src/rules/avoid_collection_methods_with_unrelated_types.dart';
import 'package:many_lints/src/rules/avoid_accessing_collections_by_constant_index.dart';
import 'package:many_lints/src/rules/avoid_generics_shadowing.dart';
import 'package:many_lints/src/rules/avoid_map_keys_contains.dart';
import 'package:many_lints/src/rules/avoid_misused_test_matchers.dart';
import 'package:many_lints/src/rules/avoid_only_rethrow.dart';
import 'package:many_lints/src/rules/avoid_throw_in_catch_block.dart';
import 'package:many_lints/src/rules/avoid_unassigned_stream_subscriptions.dart';
import 'package:many_lints/src/rules/avoid_unremovable_callbacks_in_listeners.dart';
import 'package:many_lints/src/rules/prefer_test_matchers.dart';
import 'package:many_lints/src/rules/prefer_theme_mode_getters.dart';
import 'package:many_lints/src/rules/avoid_single_child_in_multi_child_widgets.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_consumer_widgets.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_hook_widgets.dart';
import 'package:many_lints/src/rules/prefer_abstract_final_static_class.dart';
import 'package:many_lints/src/rules/prefer_align_over_container.dart';
import 'package:many_lints/src/rules/prefer_any_or_every.dart';
import 'package:many_lints/src/rules/prefer_center_over_align.dart';
import 'package:many_lints/src/rules/prefer_enums_by_name.dart';
import 'package:many_lints/src/rules/prefer_expect_later.dart';
import 'package:many_lints/src/rules/prefer_iterable_of.dart';
import 'package:many_lints/src/rules/prefer_explicit_function_type.dart';
import 'package:many_lints/src/rules/prefer_overriding_parent_equality.dart';
import 'package:many_lints/src/rules/prefer_padding_over_container.dart';
import 'package:many_lints/src/rules/prefer_private_named_parameters.dart';
import 'package:many_lints/src/rules/prefer_return_await.dart';
import 'package:many_lints/src/rules/proper_super_calls.dart';
import 'package:many_lints/src/rules/require_atomic_async_updates.dart';
import 'package:many_lints/src/rules/prefer_returning_shorthands.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_constructors.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_enums.dart';
import 'package:many_lints/src/rules/prefer_single_widget_per_file.dart';
import 'package:many_lints/src/rules/prefer_spacing.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_static_fields.dart';
import 'package:many_lints/src/rules/prefer_simpler_patterns_null_check.dart';
import 'package:many_lints/src/rules/prefer_switch_expression.dart';
import 'package:many_lints/src/rules/prefer_wildcard_pattern.dart';
import 'package:many_lints/src/rules/prefer_type_over_var.dart';
import 'package:many_lints/src/rules/avoid_banned_annotations.dart';
import 'package:many_lints/src/rules/avoid_banned_exports.dart';
import 'package:many_lints/src/rules/avoid_banned_imports.dart';
import 'package:many_lints/src/rules/avoid_banned_names.dart';
import 'package:many_lints/src/rules/avoid_banned_types.dart';
import 'package:many_lints/src/rules/banned_usage.dart';
import 'package:many_lints/src/rules/use_class_prefix.dart';
import 'package:many_lints/src/rules/use_class_suffix.dart';
import 'package:many_lints/src/rules/use_dedicated_media_query_methods.dart';
import 'package:many_lints/src/rules/use_gap.dart';
import 'package:many_lints/src/rules/prefer_class_destructuring.dart';
import 'package:many_lints/src/rules/use_closest_build_context.dart';
import 'package:many_lints/src/rules/use_existing_destructuring.dart';
import 'package:many_lints/src/rules/use_existing_variable.dart';
import 'package:many_lints/src/rules/prefer_container.dart';
import 'package:many_lints/src/rules/prefer_correct_edge_insets_constructor.dart';
import 'package:many_lints/src/rules/prefer_for_loop_in_children.dart';
import 'package:many_lints/src/rules/prefer_single_setstate.dart';
import 'package:many_lints/src/rules/prefer_sized_box_square.dart';
import 'package:many_lints/src/rules/prefer_text_rich.dart';
import 'package:many_lints/src/rules/prefer_transform_over_container.dart';
import 'package:many_lints/src/rules/prefer_void_callback.dart';
import 'package:many_lints/src/rules/use_ref_and_state_synchronously.dart';
import 'package:many_lints/src/rules/use_ref_read_synchronously.dart';
import 'package:many_lints/src/rules/list_all_equatable_fields.dart';
import 'package:many_lints/src/rules/prefer_equatable_mixin.dart';
import 'package:many_lints/src/rules/prefer_use_callback.dart';
import 'package:many_lints/src/rules/prefer_use_prefix.dart';
import 'package:many_lints/src/rules/use_sliver_prefix.dart';
import 'package:many_lints/src/rules/avoid_catch_error.dart';
import 'package:many_lints/src/rules/never_discard_build_context.dart';

// Fixes
import 'package:many_lints/src/fixes/always_remove_listener_fix.dart';
import 'package:many_lints/src/fixes/dispose_fields_fix.dart';
import 'package:many_lints/src/fixes/dispose_provided_instances_fix.dart';
import 'package:many_lints/src/fixes/avoid_cascade_after_if_null_fix.dart';
import 'package:many_lints/src/fixes/avoid_border_all_fix.dart';
import 'package:many_lints/src/fixes/avoid_expanded_as_spacer_fix.dart';
import 'package:many_lints/src/fixes/avoid_notifier_constructors_fix.dart';
import 'package:many_lints/src/fixes/missing_provider_scope_fix.dart';
import 'package:many_lints/src/fixes/async_value_nullable_pattern_fix.dart';
import 'package:many_lints/src/fixes/notifier_build_fix.dart';
import 'package:many_lints/src/fixes/avoid_collapsible_if_fix.dart';
import 'package:many_lints/src/fixes/prefer_add_all_fix.dart';
import 'package:many_lints/src/fixes/prefer_immediate_return_fix.dart';
import 'package:many_lints/src/fixes/avoid_empty_spread_fix.dart';
import 'package:many_lints/src/fixes/avoid_inverted_boolean_checks_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_negations_fix.dart';
import 'package:many_lints/src/fixes/avoid_redundant_else_fix.dart';
import 'package:many_lints/src/fixes/avoid_ref_read_inside_build_fix.dart';
import 'package:many_lints/src/fixes/avoid_state_constructors_fix.dart';
import 'package:many_lints/src/fixes/avoid_single_field_destructuring_fix.dart';
import 'package:many_lints/src/fixes/avoid_commented_out_code_fix.dart';
import 'package:many_lints/src/fixes/avoid_incomplete_copy_with_fix.dart';
import 'package:many_lints/src/fixes/prefer_bloc_extensions_fix.dart';
import 'package:many_lints/src/fixes/prefer_immutable_bloc_state_fix.dart';
import 'package:many_lints/src/fixes/prefer_multi_bloc_provider_fix.dart';
import 'package:many_lints/src/fixes/avoid_incorrect_image_opacity_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_gesture_detector_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_overrides_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_setstate_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_overrides_in_state_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_stateful_widgets_fix.dart';
import 'package:many_lints/src/fixes/avoid_duplicate_cascades_fix.dart';
import 'package:many_lints/src/fixes/avoid_duplicate_collection_elements_fix.dart';
import 'package:many_lints/src/fixes/avoid_shrink_wrap_in_lists_fix.dart';
import 'package:many_lints/src/fixes/add_affix_fix.dart';
import 'package:many_lints/src/fixes/avoid_generics_shadowing_fix.dart';
import 'package:many_lints/src/fixes/avoid_map_keys_contains_fix.dart';
import 'package:many_lints/src/fixes/avoid_only_rethrow_fix.dart';
import 'package:many_lints/src/fixes/avoid_throw_in_catch_block_fix.dart';
import 'package:many_lints/src/fixes/prefer_abstract_final_static_class_fix.dart';
import 'package:many_lints/src/fixes/never_discard_build_context_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_hook_widgets_fix.dart';
import 'package:many_lints/src/fixes/change_widget_name_fix.dart';
import 'package:many_lints/src/fixes/prefer_any_or_every_fix.dart';
import 'package:many_lints/src/fixes/prefer_center_over_align_fix.dart';
import 'package:many_lints/src/fixes/prefer_enums_by_name_fix.dart';
import 'package:many_lints/src/fixes/prefer_expect_later_fix.dart';
import 'package:many_lints/src/fixes/prefer_iterable_of_fix.dart';
import 'package:many_lints/src/fixes/prefer_async_callback_fix.dart';
import 'package:many_lints/src/fixes/prefer_compute_over_isolate_run_fix.dart';
import 'package:many_lints/src/fixes/prefer_const_border_radius_fix.dart';
import 'package:many_lints/src/fixes/avoid_wrapping_in_padding_fix.dart';
import 'package:many_lints/src/fixes/prefer_constrained_box_over_container_fix.dart';
import 'package:many_lints/src/fixes/prefer_explicit_function_type_fix.dart';
import 'package:many_lints/src/fixes/prefer_overriding_parent_equality_fix.dart';
import 'package:many_lints/src/fixes/prefer_padding_over_container_fix.dart';
import 'package:many_lints/src/fixes/prefer_private_named_parameters_fix.dart';
import 'package:many_lints/src/fixes/prefer_return_await_fix.dart';
import 'package:many_lints/src/fixes/prefer_theme_mode_getters_fix.dart';
import 'package:many_lints/src/fixes/proper_super_calls_fix.dart';
import 'package:many_lints/src/fixes/prefer_returning_shorthands_fix.dart';
import 'package:many_lints/src/fixes/prefer_shorthands_with_constructors_fix.dart';
import 'package:many_lints/src/fixes/prefer_shorthands_with_enums_fix.dart';
import 'package:many_lints/src/fixes/prefer_shorthands_with_static_fields_fix.dart';
import 'package:many_lints/src/fixes/prefer_simpler_patterns_null_check_fix.dart';
import 'package:many_lints/src/fixes/prefer_switch_expression_fix.dart';
import 'package:many_lints/src/fixes/prefer_wildcard_pattern_fix.dart';
import 'package:many_lints/src/fixes/prefer_type_over_var_fix.dart';
import 'package:many_lints/src/fixes/use_dedicated_media_query_methods_fix.dart';
import 'package:many_lints/src/fixes/prefer_class_destructuring_fix.dart';
import 'package:many_lints/src/fixes/use_closest_build_context_fix.dart';
import 'package:many_lints/src/fixes/use_existing_destructuring_fix.dart';
import 'package:many_lints/src/fixes/use_existing_variable_fix.dart';
import 'package:many_lints/src/fixes/prefer_container_fix.dart';
import 'package:many_lints/src/fixes/prefer_correct_edge_insets_constructor_fix.dart';
import 'package:many_lints/src/fixes/prefer_for_loop_in_children_fix.dart';
import 'package:many_lints/src/fixes/prefer_single_setstate_fix.dart';
import 'package:many_lints/src/fixes/prefer_sized_box_square_fix.dart';
import 'package:many_lints/src/fixes/use_gap_fix.dart';
import 'package:many_lints/src/fixes/prefer_text_rich_fix.dart';
import 'package:many_lints/src/fixes/prefer_void_callback_fix.dart';
import 'package:many_lints/src/fixes/use_ref_and_state_synchronously_fix.dart';
import 'package:many_lints/src/fixes/use_ref_read_synchronously_fix.dart';
import 'package:many_lints/src/fixes/list_all_equatable_fields_fix.dart';
import 'package:many_lints/src/fixes/prefer_equatable_mixin_fix.dart';
import 'package:many_lints/src/fixes/prefer_use_callback_fix.dart';
import 'package:many_lints/src/fixes/prefer_use_prefix_fix.dart';
import 'package:many_lints/src/fixes/use_sliver_prefix_fix.dart';

// Assists
import 'package:many_lints/src/assists/convert_iterable_map_to_collection_for.dart';

/// Top-level plugin variable required by analysis_server_plugin.
final plugin = ManyLintsPlugin();

/// Many Lints - A collection of useful lint rules for Dart and Flutter.
class ManyLintsPlugin extends Plugin {
  @override
  String get name => 'Many Lints';

  /// The names of every rule this plugin registers.
  ///
  /// Populated by [register]. Exposed so tests can assert that each name in a
  /// preset still corresponds to a real rule — a preset entry left behind by a
  /// rename would otherwise shrink the preset silently.
  final registeredRuleNames = <String>{};

  @override
  void register(PluginRegistry registry) {
    // Every rule is registered opt-in: nothing reports until the project
    // selects a preset or enables the rule by name. See lib/src/presets.dart.
    _registerWarningRule(registry, AlwaysRemoveListener());
    _registerWarningRule(registry, AvoidBlocPublicMethods());
    _registerWarningRule(registry, AvoidPassingBlocToBloc());
    _registerWarningRule(registry, AvoidPassingBuildContextToBlocs());
    _registerWarningRule(registry, PreferBlocExtensions());
    _registerWarningRule(registry, PreferImmutableBlocState());
    _registerWarningRule(registry, PreferMultiBlocProvider());
    _registerWarningRule(registry, AvoidCascadeAfterIfNull());
    _registerWarningRule(registry, AvoidCommentedOutCode());
    _registerWarningRule(registry, AvoidDuplicateCascades());
    _registerWarningRule(registry, AvoidConstantConditions());
    _registerWarningRule(registry, AvoidConstantSwitches());
    _registerWarningRule(registry, AvoidContradictoryExpressions());
    _registerWarningRule(registry, AvoidAccessingCollectionsByConstantIndex());
    _registerWarningRule(registry, AvoidGenericsShadowing());
    _registerWarningRule(registry, AvoidMapKeysContains());
    _registerWarningRule(registry, AvoidMisusedTestMatchers());
    _registerWarningRule(registry, AvoidOnlyRethrow());
    _registerWarningRule(registry, AvoidThrowInCatchBlock());
    _registerWarningRule(registry, AvoidUnassignedStreamSubscriptions());
    _registerWarningRule(registry, AvoidFlexibleOutsideFlex());
    _registerWarningRule(registry, AvoidIncompleteCopyWith());
    _registerWarningRule(registry, AvoidIncorrectImageOpacity());
    _registerWarningRule(registry, AvoidUnnecessaryGestureDetector());
    _registerWarningRule(registry, AvoidUnnecessaryOverrides());
    _registerWarningRule(registry, AvoidUnnecessaryOverridesInState());
    _registerWarningRule(registry, AvoidUnnecessarySetstate());
    _registerWarningRule(registry, AvoidUnnecessaryStatefulWidgets());
    _registerWarningRule(registry, AvoidMountedInSetstate());
    _registerWarningRule(registry, AvoidCollectionEqualityChecks());
    _registerWarningRule(registry, DisposeFields());
    _registerWarningRule(registry, DisposeProvidedInstances());
    _registerWarningRule(registry, AvoidCollectionMethodsWithUnrelatedTypes());
    _registerWarningRule(registry, PreferAbstractFinalStaticClass());
    _registerWarningRule(registry, PreferCenterOverAlign());
    _registerWarningRule(registry, PreferAlignOverContainer());
    _registerWarningRule(registry, PreferExplicitFunctionType());
    _registerWarningRule(registry, PreferOverridingParentEquality());
    _registerWarningRule(registry, PreferPaddingOverContainer());
    _registerWarningRule(registry, PreferPrivateNamedParameters());
    _registerWarningRule(registry, PreferReturnAwait());
    _registerWarningRule(registry, PreferReturningShorthands());
    _registerWarningRule(registry, PreferShorthandsWithConstructors());
    _registerWarningRule(registry, PreferShorthandsWithEnums());
    _registerWarningRule(registry, PreferShorthandsWithStaticFields());
    _registerWarningRule(registry, PreferSimplerPatternsNullCheck());
    _registerWarningRule(registry, PreferSwitchExpression());
    _registerWarningRule(registry, PreferWildcardPattern());
    _registerWarningRule(registry, PreferTypeOverVar());
    _registerWarningRule(registry, PreferAnyOrEvery());
    _registerWarningRule(registry, PreferEnumsByName());
    _registerWarningRule(registry, PreferExpectLater());
    _registerWarningRule(registry, PreferIterableOf());
    _registerWarningRule(registry, AvoidSingleChildInMultiChildWidgets());
    _registerWarningRule(registry, AvoidUnnecessaryHookWidgets());
    _registerWarningRule(registry, AvoidConditionalHooks());
    _registerWarningRule(registry, AvoidUnnecessaryConsumerWidgets());
    _registerWarningRule(registry, UseClassSuffix());
    _registerWarningRule(registry, UseClassPrefix());
    _registerWarningRule(registry, AvoidBannedImports());
    _registerWarningRule(registry, AvoidBannedExports());
    _registerWarningRule(registry, AvoidBannedTypes());
    _registerWarningRule(registry, AvoidBannedNames());
    _registerWarningRule(registry, AvoidBannedAnnotations());
    _registerWarningRule(registry, BannedUsage());
    _registerWarningRule(registry, UseDedicatedMediaQueryMethods());
    _registerWarningRule(registry, UseGap());
    _registerWarningRule(registry, PreferSingleWidgetPerFile());
    _registerWarningRule(registry, PreferSpacing());
    _registerWarningRule(registry, PreferTestMatchers());
    _registerWarningRule(registry, PreferThemeModeGetters());
    _registerWarningRule(registry, ProperSuperCalls());
    _registerWarningRule(registry, PreferClassDestructuring());
    _registerWarningRule(registry, UseClosestBuildContext());
    _registerWarningRule(registry, UseExistingDestructuring());
    _registerWarningRule(registry, UseExistingVariable());
    _registerWarningRule(registry, AvoidSingleFieldDestructuring());
    _registerWarningRule(registry, AvoidBorderAll());
    _registerWarningRule(registry, AvoidExpandedAsSpacer());
    _registerWarningRule(registry, AvoidReturningWidgets());
    _registerWarningRule(registry, AvoidShrinkWrapInLists());
    _registerWarningRule(registry, AvoidNotifierConstructors());
    _registerWarningRule(registry, AvoidPublicNotifierProperties());
    _registerWarningRule(registry, MissingProviderScope());
    _registerWarningRule(registry, ProtectedNotifierProperties());
    _registerWarningRule(registry, ProviderParameters());
    _registerWarningRule(registry, AsyncValueNullablePattern());
    _registerWarningRule(registry, NotifierBuild());
    _registerWarningRule(registry, AvoidBuildContextInProviders());
    _registerWarningRule(registry, AvoidRefInsideStateDispose());
    _registerWarningRule(registry, AvoidRefReadInsideBuild());
    _registerWarningRule(registry, AvoidRefWatchOutsideBuild());
    _registerWarningRule(registry, AvoidCollapsibleIf());
    _registerWarningRule(registry, AvoidDefaultTostring());
    _registerWarningRule(registry, AvoidDuplicateCollectionElements());
    _registerWarningRule(registry, AvoidNestedFutures());
    _registerWarningRule(registry, PreferSwitchWithEnums());
    _registerWarningRule(registry, PreferAddAll());
    _registerWarningRule(registry, PreferImmediateReturn());
    _registerWarningRule(registry, AvoidEmptySpread());
    _registerWarningRule(registry, AvoidInvertedBooleanChecks());
    _registerWarningRule(registry, AvoidUnnecessaryNegations());
    _registerWarningRule(registry, AvoidEqualExpressions());
    _registerWarningRule(registry, AvoidWildcardCasesWithEnums());
    _registerWarningRule(registry, AvoidDuplicateBlocEventHandlers());
    _registerWarningRule(registry, AvoidRedundantElse());
    _registerWarningRule(registry, AvoidMissingEnumConstantInMap());
    _registerWarningRule(registry, AvoidUnsafeCollectionMethods());
    _registerWarningRule(registry, AvoidEmptySetstate());
    _registerWarningRule(registry, CheckIsNotClosedAfterAsyncGap());
    _registerWarningRule(registry, RequireAtomicAsyncUpdates());
    _registerWarningRule(registry, EmitNewBlocStateInstances());
    _registerWarningRule(registry, AvoidCatchError());
    _registerWarningRule(registry, NeverDiscardBuildContext());
    _registerWarningRule(registry, AvoidMissingCompleterStackTrace());
    _registerWarningRule(registry, AvoidPassingAsyncWhenSyncExpected());
    _registerWarningRule(registry, AvoidUnrelatedTypeCasts());
    _registerWarningRule(registry, AvoidNotEncodableInToJson());
    _registerWarningRule(registry, FunctionAlwaysReturnsNull());
    _registerWarningRule(registry, AvoidUnmodifiedLoopCondition());
    _registerWarningRule(registry, AvoidUnusedAfterNullCheck());
    _registerWarningRule(registry, AvoidLateContext());
    _registerWarningRule(registry, AlwaysPassGlobalKey());
    _registerWarningRule(registry, CheckForEqualsInRenderObjectSetters());
    _registerWarningRule(registry, NoEqualThenElse());
    _registerWarningRule(registry, PreferCorrectJsonCasts());
    _registerWarningRule(registry, AvoidUnremovableCallbacksInListeners());
    _registerWarningRule(registry, AvoidShadowedExtensionMethods());
    _registerWarningRule(registry, HandleBlocEventSubclasses());
    _registerWarningRule(registry, AvoidHooksOutsideBuild());
    _registerWarningRule(registry, AvoidMisusedHooks());
    _registerWarningRule(registry, AvoidInheritedWidgetInInitstate());
    _registerWarningRule(registry, AvoidRecursiveWidgetCalls());
    _registerWarningRule(registry, PassExistingFutureToFutureBuilder());
    _registerWarningRule(registry, PassExistingStreamToStreamBuilder());
    _registerWarningRule(registry, AvoidStateConstructors());
    _registerWarningRule(registry, PreferAsyncCallback());
    _registerWarningRule(registry, PreferComputeOverIsolateRun());
    _registerWarningRule(registry, PreferConstBorderRadius());
    _registerWarningRule(registry, AvoidWrappingInPadding());
    _registerWarningRule(registry, PreferConstrainedBoxOverContainer());
    _registerWarningRule(registry, PreferContainer());
    _registerWarningRule(registry, PreferCorrectEdgeInsetsConstructor());
    _registerWarningRule(registry, PreferForLoopInChildren());
    _registerWarningRule(registry, PreferSingleSetstate());
    _registerWarningRule(registry, PreferSizedBoxSquare());
    _registerWarningRule(registry, PreferTextRich());
    _registerWarningRule(registry, PreferTransformOverContainer());
    _registerWarningRule(registry, PreferVoidCallback());
    _registerWarningRule(registry, UseRefAndStateSynchronously());
    _registerWarningRule(registry, UseRefReadSynchronously());
    _registerWarningRule(registry, ListAllEquatableFields());
    _registerWarningRule(registry, PreferEquatableMixin());
    _registerWarningRule(registry, PreferUseCallback());
    _registerWarningRule(registry, PreferUsePrefix());
    _registerWarningRule(registry, UseSliverPrefix());

    // Keep removed names registered so existing configurations receive the
    // analyzer's replacement guidance instead of an unknown-rule warning.
    _registerWarningRule(
      registry,
      RemovedAnalysisRule(
        name: 'prefer_contains',
        description:
            'Removed in many_lints 1.0.0. Use the Dart SDK rule instead.',
        replacedBy: 'prefer_contains',
      ),
    );

    // Register fixes for rules
    registry.registerFixForRule(
      AlwaysRemoveListener.code,
      AlwaysRemoveListenerFix.new,
    );
    registry.registerFixForRule(
      AvoidCascadeAfterIfNull.code,
      AvoidCascadeAfterIfNullFix.new,
    );
    registry.registerFixForRule(DisposeFields.code, DisposeFieldsFix.new);
    registry.registerFixForRule(
      MissingProviderScope.code,
      MissingProviderScopeFix.new,
    );
    registry.registerFixForRule(
      AsyncValueNullablePattern.code,
      AsyncValueNullablePatternFix.new,
    );
    registry.registerFixForRule(NotifierBuild.code, NotifierBuildFix.new);
    registry.registerFixForRule(
      DisposeProvidedInstances.code,
      DisposeProvidedInstancesFix.new,
    );
    registry.registerFixForRule(
      AvoidCommentedOutCode.code,
      AvoidCommentedOutCodeFix.new,
    );
    registry.registerFixForRule(
      AvoidDuplicateCascades.code,
      AvoidDuplicateCascadesFix.new,
    );
    registry.registerFixForRule(
      AvoidDuplicateCollectionElements.code,
      AvoidDuplicateCollectionElementsFix.new,
    );
    registry.registerFixForRule(
      AvoidShrinkWrapInLists.code,
      AvoidShrinkWrapInListsFix.new,
    );
    registry.registerFixForRule(
      PreferAbstractFinalStaticClass.code,
      PreferAbstractFinalStaticClassFix.new,
    );
    registry.registerFixForRule(
      NeverDiscardBuildContext.code,
      NeverDiscardBuildContextFix.new,
    );
    registry.registerFixForRule(
      PreferCenterOverAlign.code,
      PreferCenterOverAlignFix.new,
    );
    registry.registerFixForRule(
      PreferAlignOverContainer.code,
      ChangeWidgetNameFix.alignFix,
    );
    registry.registerFixForRule(
      PreferExplicitFunctionType.code,
      PreferExplicitFunctionTypeFix.new,
    );
    registry.registerFixForRule(
      PreferPaddingOverContainer.code,
      PreferPaddingOverContainerFix.new,
    );
    registry.registerFixForRule(
      PreferPrivateNamedParameters.code,
      PreferPrivateNamedParametersFix.new,
    );
    registry.registerFixForRule(PreferAnyOrEvery.code, PreferAnyOrEveryFix.new);
    registry.registerFixForRule(
      PreferEnumsByName.code,
      PreferEnumsByNameFix.new,
    );
    registry.registerFixForRule(
      PreferExpectLater.code,
      PreferExpectLaterFix.new,
    );
    registry.registerFixForRule(PreferIterableOf.code, PreferIterableOfFix.new);
    registry.registerFixForRule(
      PreferReturnAwait.code,
      PreferReturnAwaitFix.new,
    );
    registry.registerFixForRule(
      PreferReturningShorthands.code,
      PreferReturningShorthandsFix.new,
    );
    registry.registerFixForRule(
      PreferShorthandsWithConstructors.code,
      PreferShorthandsWithConstructorsFix.new,
    );
    registry.registerFixForRule(
      PreferShorthandsWithEnums.code,
      PreferShorthandsWithEnumsFix.new,
    );
    registry.registerFixForRule(
      PreferShorthandsWithStaticFields.code,
      PreferShorthandsWithStaticFieldsFix.new,
    );
    registry.registerFixForRule(
      PreferSimplerPatternsNullCheck.code,
      PreferSimplerPatternsNullCheckFix.new,
    );
    registry.registerFixForRule(
      PreferSwitchExpression.code,
      PreferSwitchExpressionFix.new,
    );
    registry.registerFixForRule(
      PreferWildcardPattern.code,
      PreferWildcardPatternFix.new,
    );
    registry.registerFixForRule(
      PreferTypeOverVar.code,
      PreferTypeOverVarFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessaryHookWidgets.code,
      AvoidUnnecessaryHookWidgetsFix.new,
    );
    registry.registerFixForRule(
      UseDedicatedMediaQueryMethods.code,
      UseDedicatedMediaQueryMethodsFix.new,
    );
    registry.registerFixForRule(UseClassSuffix.code, AddAffixFix.suffixFix);
    registry.registerFixForRule(UseClassPrefix.code, AddAffixFix.prefixFix);
    registry.registerFixForRule(
      AvoidUnnecessaryConsumerWidgets.code,
      AvoidUnnecessaryConsumerWidgetsFix.new,
    );
    registry.registerFixForRule(UseGap.code, UseGapFix.new);
    registry.registerFixForRule(
      AvoidGenericsShadowing.code,
      AvoidGenericsShadowingFix.new,
    );
    registry.registerFixForRule(
      AvoidMapKeysContains.code,
      AvoidMapKeysContainsFix.new,
    );
    registry.registerFixForRule(AvoidOnlyRethrow.code, AvoidOnlyRethrowFix.new);
    registry.registerFixForRule(
      PreferOverridingParentEquality.code,
      PreferOverridingParentEqualityFix.new,
    );
    registry.registerFixForRule(
      AvoidThrowInCatchBlock.code,
      AvoidThrowInCatchBlockFix.new,
    );
    registry.registerFixForRule(
      AvoidIncompleteCopyWith.code,
      AvoidIncompleteCopyWithFix.new,
    );
    registry.registerFixForRule(
      AvoidIncorrectImageOpacity.code,
      AvoidIncorrectImageOpacityFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessaryGestureDetector.code,
      AvoidUnnecessaryGestureDetectorFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessaryOverrides.code,
      AvoidUnnecessaryOverridesFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessaryOverridesInState.code,
      AvoidUnnecessaryOverridesInStateFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessarySetstate.code,
      AvoidUnnecessarySetstateFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessaryStatefulWidgets.code,
      AvoidUnnecessaryStatefulWidgetsFix.new,
    );

    registry.registerFixForRule(ProperSuperCalls.code, ProperSuperCallsFix.new);
    registry.registerFixForRule(
      PreferClassDestructuring.code,
      PreferClassDestructuringFix.new,
    );
    registry.registerFixForRule(
      AvoidCollapsibleIf.code,
      AvoidCollapsibleIfFix.new,
    );
    registry.registerFixForRule(PreferAddAll.code, PreferAddAllFix.new);
    registry.registerFixForRule(
      PreferImmediateReturn.code,
      PreferImmediateReturnFix.new,
    );
    registry.registerFixForRule(AvoidEmptySpread.code, AvoidEmptySpreadFix.new);
    registry.registerFixForRule(
      AvoidInvertedBooleanChecks.code,
      AvoidInvertedBooleanChecksFix.new,
    );
    registry.registerFixForRule(
      AvoidUnnecessaryNegations.code,
      AvoidUnnecessaryNegationsFix.new,
    );
    registry.registerFixForRule(
      AvoidRedundantElse.code,
      AvoidRedundantElseFix.new,
    );
    registry.registerFixForRule(
      UseClosestBuildContext.code,
      UseClosestBuildContextFix.new,
    );
    registry.registerFixForRule(
      UseExistingVariable.code,
      UseExistingVariableFix.new,
    );
    registry.registerFixForRule(
      UseExistingDestructuring.code,
      UseExistingDestructuringFix.new,
    );
    registry.registerFixForRule(
      AvoidSingleFieldDestructuring.code,
      AvoidSingleFieldDestructuringFix.new,
    );
    registry.registerFixForRule(AvoidBorderAll.code, AvoidBorderAllFix.new);
    registry.registerFixForRule(
      AvoidExpandedAsSpacer.code,
      AvoidExpandedAsSpacerFix.new,
    );
    registry.registerFixForRule(
      AvoidNotifierConstructors.code,
      AvoidNotifierConstructorsFix.new,
    );
    registry.registerFixForRule(
      AvoidRefReadInsideBuild.code,
      AvoidRefReadInsideBuildFix.new,
    );
    registry.registerFixForRule(
      AvoidStateConstructors.code,
      AvoidStateConstructorsFix.new,
    );
    registry.registerFixForRule(
      PreferAsyncCallback.code,
      PreferAsyncCallbackFix.new,
    );
    registry.registerFixForRule(
      PreferComputeOverIsolateRun.code,
      PreferComputeOverIsolateRunFix.new,
    );
    registry.registerFixForRule(
      PreferConstBorderRadius.code,
      PreferConstBorderRadiusFix.new,
    );
    registry.registerFixForRule(
      PreferConstrainedBoxOverContainer.code,
      PreferConstrainedBoxOverContainerFix.new,
    );
    registry.registerFixForRule(
      AvoidWrappingInPadding.code,
      AvoidWrappingInPaddingFix.new,
    );
    registry.registerFixForRule(PreferContainer.code, PreferContainerFix.new);
    registry.registerFixForRule(
      PreferCorrectEdgeInsetsConstructor.code,
      PreferCorrectEdgeInsetsConstructorFix.new,
    );
    registry.registerFixForRule(
      PreferForLoopInChildren.code,
      PreferForLoopInChildrenFix.new,
    );
    registry.registerFixForRule(
      PreferSingleSetstate.code,
      PreferSingleSetstateFix.new,
    );
    registry.registerFixForRule(
      PreferSizedBoxSquare.code,
      PreferSizedBoxSquareFix.new,
    );
    registry.registerFixForRule(PreferTextRich.code, PreferTextRichFix.new);
    registry.registerFixForRule(
      PreferThemeModeGetters.code,
      PreferThemeModeGettersFix.new,
    );
    registry.registerFixForRule(
      PreferTransformOverContainer.code,
      ChangeWidgetNameFix.transformFix,
    );
    registry.registerFixForRule(
      PreferVoidCallback.code,
      PreferVoidCallbackFix.new,
    );
    registry.registerFixForRule(
      UseRefAndStateSynchronously.code,
      UseRefAndStateSynchronouslyFix.new,
    );
    registry.registerFixForRule(
      UseRefReadSynchronously.code,
      UseRefReadSynchronouslyFix.new,
    );
    registry.registerFixForRule(
      ListAllEquatableFields.code,
      ListAllEquatableFieldsFix.new,
    );
    registry.registerFixForRule(
      PreferEquatableMixin.code,
      PreferEquatableMixinFix.new,
    );
    registry.registerFixForRule(
      PreferUseCallback.code,
      PreferUseCallbackFix.new,
    );
    registry.registerFixForRule(PreferUsePrefix.code, PreferUsePrefixFix.new);
    registry.registerFixForRule(UseSliverPrefix.code, UseSliverPrefixFix.new);
    registry.registerFixForRule(
      PreferBlocExtensions.code,
      PreferBlocExtensionsFix.new,
    );
    registry.registerFixForRule(
      PreferImmutableBlocState.code,
      PreferImmutableBlocStateFix.new,
    );
    registry.registerFixForRule(
      PreferMultiBlocProvider.code,
      PreferMultiBlocProviderFix.new,
    );

    // Register assists
    registry.registerAssist(ConvertIterableMapToCollectionFor.new);
  }
}

/// Registers [rule] so that it runs, but reports only where this package's own
/// configuration says it should.
///
/// The rule is still installed as a *warning* rule, which the analyzer treats
/// as on-by-default. That is deliberate, and is not the same thing as the
/// package being on by default:
///
/// - `registerLintRule` would make a rule opt-in through the analyzer's own
///   `diagnostics:` map, but that map is the only channel the analyzer offers
///   and it cannot express a preset — `diagnostics:` accepts severity scalars
///   only, and a `plugins:` block is replaced wholesale rather than merged
///   across `include:`. Presets would be unavailable.
/// - Keeping the rules registered means every rule's visitors still run, and
///   enablement is decided per file in [ManyLintsRule]'s reporter seam, where
///   `preset:`, `enabled:`, `exclude:` and `include:` all already resolve.
///
/// So the default is enforced one layer in: with no configuration, every
/// rule's diagnostics are discarded and the package is silent.
extension on ManyLintsPlugin {
  void _registerWarningRule(
    PluginRegistry registry,
    AbstractAnalysisRule rule,
  ) {
    registeredRuleNames.add(rule.name);

    if (registry is plugin_registry.PluginRegistryImpl) {
      PluginServer.registries['many_lints'] = registry;
      registry.warningRules[rule.name.toLowerCase()] = rule;
      for (final code in rule.diagnosticCodes) {
        registry.codeMap[code.lowerCaseUniqueName] = code;
      }
      return;
    }

    registry.registerWarningRule(rule);
  }
}
