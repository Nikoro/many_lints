// SPDX-FileCopyrightText: 2023 Remi Rousselet
// SPDX-License-Identifier: MIT

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

class ProtectedNotifierProperties extends ManyLintsRule {
  static const LintCode code = LintCode(
    'protected_notifier_properties',
    "The property '{0}' should not be used outside of the Notifier itself.",
    correctionMessage:
        'Try reading the value through its provider instead of the notifier.',
  );

  ProtectedNotifierProperties()
    : super(
        name: 'protected_notifier_properties',
        description:
            "Warns when a Notifier's protected properties are accessed from "
            'outside the notifier itself.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPropertyAccess(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
  }
}

const _notifierOnlyProperties = {'state', 'stateOrNull', 'future', 'ref'};

class _Visitor extends SimpleAstVisitor<void> {
  final ProtectedNotifierProperties rule;

  _Visitor(this.rule);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _check(node, node.target?.staticType, node.propertyName);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node, node.prefix.staticType, node.identifier);
  }

  void _check(
    Expression node,
    DartType? targetType,
    SimpleIdentifier property,
  ) {
    if (!_notifierOnlyProperties.contains(property.name)) return;
    if (targetType == null) return;

    if (!notifierChecker.isAssignableFromType(targetType)) return;

    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    final enclosingElement = enclosingClass?.declaredFragment?.element;
    final isOwnNotifier = targetType == enclosingElement?.thisType;
    if (isOwnNotifier) return;

    rule.reportAtNode(property, arguments: [property.name]);
  }
}
