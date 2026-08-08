// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

/// Warns when `runApp()` is called without a `ProviderScope` at the root of
/// the widget tree.
///
/// Riverpod stores provider state inside a `ProviderScope`. Without one at the
/// root, every `ref.watch`/`ref.read` throws at runtime, so this is an
/// app-breaking mistake that no compile-time check catches.
///
/// **BAD:**
/// ```dart
/// void main() {
///   runApp(MyApp()); // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void main() {
///   runApp(ProviderScope(child: MyApp()));
/// }
/// ```
class MissingProviderScope extends ManyLintsRule {
  static const LintCode code = LintCode(
    'missing_provider_scope',
    'Flutter applications using Riverpod must contain a ProviderScope at the '
        'root of their widget tree.',
    correctionMessage: 'Try wrapping the root widget in a ProviderScope.',
  );

  MissingProviderScope()
    : super(
        name: 'missing_provider_scope',
        description:
            'Warns when runApp() is called without a ProviderScope at the '
            'root of the widget tree.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MissingProviderScope rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'runApp') return;

    // Only Flutter's own `runApp`, not a same-named local function.
    final element = node.methodName.element;
    if (element == null) return;
    final libraryUri = element.library?.identifier;
    if (libraryUri == null || !libraryUri.startsWith('package:flutter/')) {
      return;
    }

    final rootWidget = node.argumentList.arguments.firstOrNull;
    if (rootWidget == null) return;

    final rootType = rootWidget.argumentExpression.staticType;
    if (rootType == null) return;

    if (providerScopeChecker.isExactlyType(rootType)) return;

    rule.reportAtNode(node.methodName);
  }
}
