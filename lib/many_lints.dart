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
///   many_lints: ^0.3.0
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
import 'package:many_lints/src/rules/avoid_bloc_public_methods.dart';
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
import 'package:many_lints/src/rules/avoid_wrapping_in_padding.dart';
import 'package:many_lints/src/rules/prefer_constrained_box_over_container.dart';
import 'package:many_lints/src/rules/avoid_shrink_wrap_in_lists.dart';
import 'package:many_lints/src/rules/avoid_notifier_constructors.dart';
import 'package:many_lints/src/rules/avoid_public_notifier_properties.dart';
import 'package:many_lints/src/rules/avoid_ref_inside_state_dispose.dart';
import 'package:many_lints/src/rules/avoid_ref_read_inside_build.dart';
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
import 'package:many_lints/src/rules/prefer_test_matchers.dart';
import 'package:many_lints/src/rules/avoid_single_child_in_multi_child_widgets.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_consumer_widgets.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_hook_widgets.dart';
import 'package:many_lints/src/rules/prefer_abstract_final_static_class.dart';
import 'package:many_lints/src/rules/prefer_align_over_container.dart';
import 'package:many_lints/src/rules/prefer_any_or_every.dart';
import 'package:many_lints/src/rules/prefer_center_over_align.dart';
import 'package:many_lints/src/rules/prefer_contains.dart';
import 'package:many_lints/src/rules/prefer_enums_by_name.dart';
import 'package:many_lints/src/rules/prefer_expect_later.dart';
import 'package:many_lints/src/rules/prefer_iterable_of.dart';
import 'package:many_lints/src/rules/prefer_explicit_function_type.dart';
import 'package:many_lints/src/rules/prefer_overriding_parent_equality.dart';
import 'package:many_lints/src/rules/prefer_padding_over_container.dart';
import 'package:many_lints/src/rules/prefer_return_await.dart';
import 'package:many_lints/src/rules/proper_super_calls.dart';
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
import 'package:many_lints/src/rules/use_bloc_suffix.dart';
import 'package:many_lints/src/rules/use_cubit_suffix.dart';
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
import 'package:many_lints/src/rules/use_notifier_suffix.dart';
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

// Fixes
import 'package:many_lints/src/fixes/always_remove_listener_fix.dart';
import 'package:many_lints/src/fixes/dispose_fields_fix.dart';
import 'package:many_lints/src/fixes/dispose_provided_instances_fix.dart';
import 'package:many_lints/src/fixes/avoid_cascade_after_if_null_fix.dart';
import 'package:many_lints/src/fixes/avoid_border_all_fix.dart';
import 'package:many_lints/src/fixes/avoid_expanded_as_spacer_fix.dart';
import 'package:many_lints/src/fixes/avoid_notifier_constructors_fix.dart';
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
import 'package:many_lints/src/fixes/add_suffix_fix.dart';
import 'package:many_lints/src/fixes/avoid_generics_shadowing_fix.dart';
import 'package:many_lints/src/fixes/avoid_map_keys_contains_fix.dart';
import 'package:many_lints/src/fixes/avoid_only_rethrow_fix.dart';
import 'package:many_lints/src/fixes/avoid_throw_in_catch_block_fix.dart';
import 'package:many_lints/src/fixes/prefer_abstract_final_static_class_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_hook_widgets_fix.dart';
import 'package:many_lints/src/fixes/change_widget_name_fix.dart';
import 'package:many_lints/src/fixes/prefer_any_or_every_fix.dart';
import 'package:many_lints/src/fixes/prefer_center_over_align_fix.dart';
import 'package:many_lints/src/fixes/prefer_contains_fix.dart';
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
import 'package:many_lints/src/fixes/prefer_return_await_fix.dart';
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

  @override
  void register(PluginRegistry registry) {
    // Register warning rules (enabled by default)
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
    _registerWarningRule(registry, PreferContains());
    _registerWarningRule(registry, PreferEnumsByName());
    _registerWarningRule(registry, PreferExpectLater());
    _registerWarningRule(registry, PreferIterableOf());
    _registerWarningRule(registry, AvoidSingleChildInMultiChildWidgets());
    _registerWarningRule(registry, AvoidUnnecessaryHookWidgets());
    _registerWarningRule(registry, AvoidConditionalHooks());
    _registerWarningRule(registry, AvoidUnnecessaryConsumerWidgets());
    _registerWarningRule(registry, UseBlocSuffix());
    _registerWarningRule(registry, UseCubitSuffix());
    _registerWarningRule(registry, UseNotifierSuffix());
    _registerWarningRule(registry, UseDedicatedMediaQueryMethods());
    _registerWarningRule(registry, UseGap());
    _registerWarningRule(registry, PreferSingleWidgetPerFile());
    _registerWarningRule(registry, PreferSpacing());
    _registerWarningRule(registry, PreferTestMatchers());
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
    _registerWarningRule(registry, AvoidRefInsideStateDispose());
    _registerWarningRule(registry, AvoidRefReadInsideBuild());
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
      PreferAbstractFinalStaticClass.code,
      PreferAbstractFinalStaticClassFix.new,
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
    registry.registerFixForRule(PreferAnyOrEvery.code, PreferAnyOrEveryFix.new);
    registry.registerFixForRule(PreferContains.code, PreferContainsFix.new);
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
    registry.registerFixForRule(UseBlocSuffix.code, AddSuffixFix.blocFix);
    registry.registerFixForRule(UseCubitSuffix.code, AddSuffixFix.cubitFix);
    registry.registerFixForRule(
      UseNotifierSuffix.code,
      AddSuffixFix.notifierFix,
    );
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

void _registerWarningRule(PluginRegistry registry, AbstractAnalysisRule rule) {
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
