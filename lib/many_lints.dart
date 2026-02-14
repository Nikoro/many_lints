/// Many Lints - A collection of useful lint rules for Dart and Flutter.
///
/// This package provides custom lint rules, quick fixes, and code assists
/// that integrate with the Dart analyzer and IDEs.
///
/// ## Usage
///
/// Add `many_lints` to your `pubspec.yaml`:
///
/// ```yaml
/// dev_dependencies:
///   many_lints: ^0.1.0
/// ```
///
/// Then enable the plugin in your `analysis_options.yaml`:
///
/// ```yaml
/// analyzer:
///   plugins:
///     - many_lints
/// ```
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

// Rules
import 'package:many_lints/src/rules/avoid_cascade_after_if_null.dart';
import 'package:many_lints/src/rules/avoid_commented_out_code.dart';
import 'package:many_lints/src/rules/avoid_collection_equality_checks.dart';
import 'package:many_lints/src/rules/avoid_collection_methods_with_unrelated_types.dart';
import 'package:many_lints/src/rules/avoid_accessing_collections_by_constant_index.dart';
import 'package:many_lints/src/rules/avoid_single_child_in_multi_child_widgets.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_consumer_widgets.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_hook_widgets.dart';
import 'package:many_lints/src/rules/prefer_abstract_final_static_class.dart';
import 'package:many_lints/src/rules/prefer_align_over_container.dart';
import 'package:many_lints/src/rules/prefer_any_or_every.dart';
import 'package:many_lints/src/rules/prefer_center_over_align.dart';
import 'package:many_lints/src/rules/prefer_iterable_of.dart';
import 'package:many_lints/src/rules/prefer_explicit_function_type.dart';
import 'package:many_lints/src/rules/prefer_padding_over_container.dart';
import 'package:many_lints/src/rules/prefer_returning_shorthands.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_constructors.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_enums.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_static_fields.dart';
import 'package:many_lints/src/rules/prefer_switch_expression.dart';
import 'package:many_lints/src/rules/prefer_type_over_var.dart';
import 'package:many_lints/src/rules/use_bloc_suffix.dart';
import 'package:many_lints/src/rules/use_cubit_suffix.dart';
import 'package:many_lints/src/rules/use_dedicated_media_query_methods.dart';
import 'package:many_lints/src/rules/use_gap.dart';
import 'package:many_lints/src/rules/use_notifier_suffix.dart';

// Fixes
import 'package:many_lints/src/fixes/avoid_cascade_after_if_null_fix.dart';
import 'package:many_lints/src/fixes/avoid_commented_out_code_fix.dart';
import 'package:many_lints/src/fixes/add_suffix_fix.dart';
import 'package:many_lints/src/fixes/prefer_abstract_final_static_class_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart';
import 'package:many_lints/src/fixes/avoid_unnecessary_hook_widgets_fix.dart';
import 'package:many_lints/src/fixes/change_widget_name_fix.dart';
import 'package:many_lints/src/fixes/prefer_any_or_every_fix.dart';
import 'package:many_lints/src/fixes/prefer_center_over_align_fix.dart';
import 'package:many_lints/src/fixes/prefer_iterable_of_fix.dart';
import 'package:many_lints/src/fixes/prefer_explicit_function_type_fix.dart';
import 'package:many_lints/src/fixes/prefer_padding_over_container_fix.dart';
import 'package:many_lints/src/fixes/prefer_returning_shorthands_fix.dart';
import 'package:many_lints/src/fixes/prefer_shorthands_with_constructors_fix.dart';
import 'package:many_lints/src/fixes/prefer_shorthands_with_enums_fix.dart';
import 'package:many_lints/src/fixes/prefer_shorthands_with_static_fields_fix.dart';
import 'package:many_lints/src/fixes/prefer_switch_expression_fix.dart';
import 'package:many_lints/src/fixes/prefer_type_over_var_fix.dart';
import 'package:many_lints/src/fixes/use_dedicated_media_query_methods_fix.dart';
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
    registry.registerWarningRule(AvoidCascadeAfterIfNull());
    registry.registerWarningRule(AvoidCommentedOutCode());
    registry.registerWarningRule(AvoidAccessingCollectionsByConstantIndex());
    registry.registerWarningRule(AvoidCollectionEqualityChecks());
    registry.registerWarningRule(AvoidCollectionMethodsWithUnrelatedTypes());
    registry.registerWarningRule(PreferAbstractFinalStaticClass());
    registry.registerWarningRule(PreferCenterOverAlign());
    registry.registerWarningRule(PreferAlignOverContainer());
    registry.registerWarningRule(PreferExplicitFunctionType());
    registry.registerWarningRule(PreferPaddingOverContainer());
    registry.registerWarningRule(PreferReturningShorthands());
    registry.registerWarningRule(PreferShorthandsWithConstructors());
    registry.registerWarningRule(PreferShorthandsWithEnums());
    registry.registerWarningRule(PreferShorthandsWithStaticFields());
    registry.registerWarningRule(PreferSwitchExpression());
    registry.registerWarningRule(PreferTypeOverVar());
    registry.registerWarningRule(PreferAnyOrEvery());
    registry.registerWarningRule(PreferIterableOf());
    registry.registerWarningRule(AvoidSingleChildInMultiChildWidgets());
    registry.registerWarningRule(AvoidUnnecessaryHookWidgets());
    registry.registerWarningRule(AvoidUnnecessaryConsumerWidgets());
    registry.registerWarningRule(UseBlocSuffix());
    registry.registerWarningRule(UseCubitSuffix());
    registry.registerWarningRule(UseNotifierSuffix());
    registry.registerWarningRule(UseDedicatedMediaQueryMethods());
    registry.registerWarningRule(UseGap());

    // Register fixes for rules
    registry.registerFixForRule(
      AvoidCascadeAfterIfNull.code,
      AvoidCascadeAfterIfNullFix.new,
    );
    registry.registerFixForRule(
      AvoidCommentedOutCode.code,
      AvoidCommentedOutCodeFix.new,
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
    registry.registerFixForRule(PreferIterableOf.code, PreferIterableOfFix.new);
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
      PreferSwitchExpression.code,
      PreferSwitchExpressionFix.new,
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

    // Register assists
    registry.registerAssist(ConvertIterableMapToCollectionFor.new);
  }
}
