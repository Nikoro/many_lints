// SPDX-FileCopyrightText: 2023 Remi Rousselet
// SPDX-License-Identifier: MIT

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

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
    if (!_isFlutterRunApp(node.methodName)) return;

    final rootWidget = node.argumentList.arguments.firstOrNull;
    if (rootWidget == null) return;

    final rootType = rootWidget.argumentExpression.staticType;
    if (rootType == null) return;

    if (providerScopeChecker.isExactlyType(rootType)) return;

    rule.reportAtNode(node.methodName);
  }

  bool _isFlutterRunApp(SimpleIdentifier methodName) {
    if (methodName.name != 'runApp') return false;

    final libraryUri = methodName.element?.library?.identifier;

    return libraryUri != null && libraryUri.startsWith('package:flutter/');
  }
}
