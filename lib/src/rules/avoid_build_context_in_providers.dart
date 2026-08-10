// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

/// Warns when a `@riverpod` provider takes a `BuildContext` parameter.
///
/// Providers outlive the widgets that read them. A `BuildContext` captured in
/// a provider may refer to a widget that has already been unmounted, so using
/// it later throws or silently reads stale data.
///
/// **BAD:**
/// ```dart
/// @riverpod
/// int example(Ref ref, BuildContext context) => 0; // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// @riverpod
/// int example(Ref ref) => 0;
/// ```
class AvoidBuildContextInProviders extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_build_context_in_providers',
    'Providers should not receive a BuildContext.',
    correctionMessage:
        'Try passing the value read from the context instead of the context '
        'itself.',
  );

  AvoidBuildContextInProviders()
    : super(
        name: 'avoid_build_context_in_providers',
        description:
            "Warns when a '@riverpod' provider takes a BuildContext parameter.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBuildContextInProviders rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!hasRiverpodAnnotation(node)) return;
    _checkParameters(node.functionExpression.parameters);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasRiverpodAnnotation(node)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration) {
        _checkParameters(member.parameters);
      }
    }
  }

  void _checkParameters(FormalParameterList? parameters) {
    if (parameters == null) return;

    for (final parameter in parameters.parameters) {
      final type = parameter.declaredFragment?.element.type;
      if (type == null) continue;
      if (!buildContextChecker.isExactlyType(type)) continue;

      rule.reportAtNode(parameter);
    }
  }
}
