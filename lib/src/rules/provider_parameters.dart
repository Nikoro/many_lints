// SPDX-FileCopyrightText: 2023 Remi Rousselet
// SPDX-License-Identifier: MIT

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

class ProviderParameters extends ManyLintsRule {
  static const LintCode code = LintCode(
    'provider_parameters',
    'This argument has no stable equality, so the provider is recreated on '
        'every rebuild.',
    correctionMessage:
        'Try passing a const value, or a type that overrides ==.',
  );

  ProviderParameters()
    : super(
        name: 'provider_parameters',
        description:
            'Warns when a family provider is passed an argument that has no '
            'stable equality.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ProviderParameters rule;

  _Visitor(this.rule);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkExpression(node);
  }

  void _checkExpression(Expression node) {
    final staticType = node.staticType;
    if (staticType == null) return;
    if (!providerBaseChecker.isAssignableFromType(staticType)) return;

    final arguments = _familyArgumentsOf(node);
    if (arguments == null) return;
    if (!_callsExistingFamily(node)) return;

    for (final argument in arguments.arguments) {
      final value = argument.argumentExpression;
      if (_hasUnstableEquality(value)) {
        rule.reportAtNode(value);
      }
    }
  }

  ArgumentList? _familyArgumentsOf(Expression node) {
    return switch (node) {
      FunctionExpressionInvocation() => node.argumentList,
      MethodInvocation() => node.argumentList,
      _ => null,
    };
  }

  bool _callsExistingFamily(Expression node) {
    final target = switch (node) {
      FunctionExpressionInvocation() => node.function,
      MethodInvocation() => node.target,
      _ => null,
    };

    final targetType = target?.staticType;
    if (targetType == null) return false;

    return familyChecker.isAssignableFromType(targetType);
  }

  bool _hasUnstableEquality(Expression value) {
    if (value is TypedLiteral) return !value.isConst;

    if (value is FunctionExpression) return true;

    if (value is InstanceCreationExpression) {
      if (value.isConst) return false;

      final constructor = value.constructorName.element
          ?.applyRedirectedConstructors();
      var equalityOwner = constructor?.enclosingElement;
      if (equalityOwner is ExtensionTypeElement) {
        final erasure = value.staticType?.extensionTypeErasure.element;
        equalityOwner = erasure is InterfaceElement ? erasure : null;
      }

      return equalityOwner?.nonObjectMethodNamed('==') == null;
    }

    return false;
  }
}

extension on ConstructorElement {
  ConstructorElement applyRedirectedConstructors() {
    final redirected = redirectedConstructor;
    if (redirected != null) return redirected.applyRedirectedConstructors();
    return this;
  }
}

extension on InterfaceElement {
  MethodElement? nonObjectMethodNamed(String name) {
    if (thisType.isDartCoreObject) return null;

    final thisMethod = getMethod(name);
    if (thisMethod != null) return thisMethod;

    for (final superType in allSupertypes) {
      if (superType.isDartCoreObject) continue;

      final superMethod = superType.getMethod(name);
      if (superMethod != null) return superMethod;
    }

    return null;
  }
}
