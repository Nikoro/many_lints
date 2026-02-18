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

// Rules
import 'package:many_lints/src/rules/always_remove_listener.dart';
import 'package:many_lints/src/rules/avoid_cascade_after_if_null.dart';
import 'package:many_lints/src/rules/avoid_border_all.dart';
import 'package:many_lints/src/rules/avoid_expanded_as_spacer.dart';
import 'package:many_lints/src/rules/avoid_returning_widgets.dart';
import 'package:many_lints/src/rules/prefer_async_callback.dart';
import 'package:many_lints/src/rules/prefer_compute_over_isolate_run.dart';
import 'package:many_lints/src/rules/prefer_const_border_radius.dart';
import 'package:many_lints/src/rules/avoid_wrapping_in_padding.dart';
import 'package:many_lints/src/rules/prefer_constrained_box_over_container.dart';
import 'package:many_lints/src/rules/avoid_shrink_wrap_in_lists.dart';
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
import 'package:many_lints/src/rules/use_notifier_suffix.dart';

// Fixes
import 'package:many_lints/src/fixes/always_remove_listener_fix.dart';
import 'package:many_lints/src/fixes/dispose_fields_fix.dart';
import 'package:many_lints/src/fixes/avoid_cascade_after_if_null_fix.dart';
import 'package:many_lints/src/fixes/avoid_border_all_fix.dart';
import 'package:many_lints/src/fixes/avoid_expanded_as_spacer_fix.dart';
import 'package:many_lints/src/fixes/avoid_state_constructors_fix.dart';
import 'package:many_lints/src/fixes/avoid_single_field_destructuring_fix.dart';
import 'package:many_lints/src/fixes/avoid_commented_out_code_fix.dart';
import 'package:many_lints/src/fixes/avoid_incomplete_copy_with_fix.dart';
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
import 'package:many_lints/src/fixes/use_gap_fix.dart';

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
    registry.registerWarningRule(AlwaysRemoveListener());
    registry.registerWarningRule(AvoidCascadeAfterIfNull());
    registry.registerWarningRule(AvoidCommentedOutCode());
    registry.registerWarningRule(AvoidDuplicateCascades());
    registry.registerWarningRule(AvoidConstantConditions());
    registry.registerWarningRule(AvoidConstantSwitches());
    registry.registerWarningRule(AvoidContradictoryExpressions());
    registry.registerWarningRule(AvoidAccessingCollectionsByConstantIndex());
    registry.registerWarningRule(AvoidGenericsShadowing());
    registry.registerWarningRule(AvoidMapKeysContains());
    registry.registerWarningRule(AvoidMisusedTestMatchers());
    registry.registerWarningRule(AvoidOnlyRethrow());
    registry.registerWarningRule(AvoidThrowInCatchBlock());
    registry.registerWarningRule(AvoidUnassignedStreamSubscriptions());
    registry.registerWarningRule(AvoidFlexibleOutsideFlex());
    registry.registerWarningRule(AvoidIncompleteCopyWith());
    registry.registerWarningRule(AvoidIncorrectImageOpacity());
    registry.registerWarningRule(AvoidUnnecessaryGestureDetector());
    registry.registerWarningRule(AvoidUnnecessaryOverrides());
    registry.registerWarningRule(AvoidUnnecessaryOverridesInState());
    registry.registerWarningRule(AvoidUnnecessarySetstate());
    registry.registerWarningRule(AvoidUnnecessaryStatefulWidgets());
    registry.registerWarningRule(AvoidMountedInSetstate());
    registry.registerWarningRule(AvoidCollectionEqualityChecks());
    registry.registerWarningRule(DisposeFields());
    registry.registerWarningRule(AvoidCollectionMethodsWithUnrelatedTypes());
    registry.registerWarningRule(PreferAbstractFinalStaticClass());
    registry.registerWarningRule(PreferCenterOverAlign());
    registry.registerWarningRule(PreferAlignOverContainer());
    registry.registerWarningRule(PreferExplicitFunctionType());
    registry.registerWarningRule(PreferOverridingParentEquality());
    registry.registerWarningRule(PreferPaddingOverContainer());
    registry.registerWarningRule(PreferReturnAwait());
    registry.registerWarningRule(PreferReturningShorthands());
    registry.registerWarningRule(PreferShorthandsWithConstructors());
    registry.registerWarningRule(PreferShorthandsWithEnums());
    registry.registerWarningRule(PreferShorthandsWithStaticFields());
    registry.registerWarningRule(PreferSimplerPatternsNullCheck());
    registry.registerWarningRule(PreferSwitchExpression());
    registry.registerWarningRule(PreferWildcardPattern());
    registry.registerWarningRule(PreferTypeOverVar());
    registry.registerWarningRule(PreferAnyOrEvery());
    registry.registerWarningRule(PreferContains());
    registry.registerWarningRule(PreferEnumsByName());
    registry.registerWarningRule(PreferExpectLater());
    registry.registerWarningRule(PreferIterableOf());
    registry.registerWarningRule(AvoidSingleChildInMultiChildWidgets());
    registry.registerWarningRule(AvoidUnnecessaryHookWidgets());
    registry.registerWarningRule(AvoidUnnecessaryConsumerWidgets());
    registry.registerWarningRule(UseBlocSuffix());
    registry.registerWarningRule(UseCubitSuffix());
    registry.registerWarningRule(UseNotifierSuffix());
    registry.registerWarningRule(UseDedicatedMediaQueryMethods());
    registry.registerWarningRule(UseGap());
    registry.registerWarningRule(PreferSingleWidgetPerFile());
    registry.registerWarningRule(PreferSpacing());
    registry.registerWarningRule(PreferTestMatchers());
    registry.registerWarningRule(ProperSuperCalls());
    registry.registerWarningRule(PreferClassDestructuring());
    registry.registerWarningRule(UseClosestBuildContext());
    registry.registerWarningRule(UseExistingDestructuring());
    registry.registerWarningRule(UseExistingVariable());
    registry.registerWarningRule(AvoidSingleFieldDestructuring());
    registry.registerWarningRule(AvoidBorderAll());
    registry.registerWarningRule(AvoidExpandedAsSpacer());
    registry.registerWarningRule(AvoidReturningWidgets());
    registry.registerWarningRule(AvoidShrinkWrapInLists());
    registry.registerWarningRule(AvoidStateConstructors());
    registry.registerWarningRule(PreferAsyncCallback());
    registry.registerWarningRule(PreferComputeOverIsolateRun());
    registry.registerWarningRule(PreferConstBorderRadius());
    registry.registerWarningRule(AvoidWrappingInPadding());
    registry.registerWarningRule(PreferConstrainedBoxOverContainer());
    registry.registerWarningRule(PreferContainer());

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

    // Register assists
    registry.registerAssist(ConvertIterableMapToCollectionFor.new);
  }
}
