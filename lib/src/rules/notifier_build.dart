// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../riverpod_type_checkers.dart';

/// Warns when a `@riverpod` class does not define a `build` method.
///
/// The generator turns the `build` method into the provider's create function.
/// Without one, code generation fails with an error that points at the
/// generated file rather than the class that caused it.
///
/// **BAD:**
/// ```dart
/// @riverpod
/// class Counter extends _$Counter {} // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// @riverpod
/// class Counter extends _$Counter {
///   @override
///   int build() => 0;
/// }
/// ```
class NotifierBuild extends AnalysisRule {
  static const LintCode code = LintCode(
    'notifier_build',
    "Classes annotated with '@riverpod' must define a 'build' method.",
    correctionMessage: "Try adding a 'build' method to the class.",
  );

  NotifierBuild()
    : super(
        name: 'notifier_build',
        description:
            "Warns when a '@riverpod' class does not define a build method.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NotifierBuild rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasRiverpodAnnotation(node)) return;

    final body = node.body;
    if (body is! BlockClassBody) {
      rule.reportAtToken(node.namePart.typeName);
      return;
    }

    final hasBuildMethod = body.members.any(
      (member) => member.declaredFragment?.element.displayName == 'build',
    );
    if (hasBuildMethod) return;

    rule.reportAtToken(node.namePart.typeName);
  }
}
