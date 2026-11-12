import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferClassDestructuring extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_class_destructuring',
    'Consider using class destructuring for {0} property accesses on '
        "'{1}'.",
    correctionMessage:
        'Use a destructuring declaration to extract all properties at once.',
  );

  static const _defaultMinOccurrences = 3;

  PreferClassDestructuring()
    : super(
        name: 'prefer_class_destructuring',
        description:
            'Warns when multiple properties of the same object are accessed '
            'separately and could use class destructuring.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBlock(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferClassDestructuring rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    final collector = _PropertyAccessCollector();
    for (final statement in node.statements) {
      statement.accept(collector);
    }

    // Edge case: rule instances are reused across package roots, so options are read per visit
    final minOccurrences = rule.config.intOption(
      'min_occurrences',
      defaultValue: PreferClassDestructuring._defaultMinOccurrences,
    );
    final ignoredTypes = rule.config.stringListOption('ignored_types');

    for (final entry in collector.accessesByVariable.entries) {
      final variableName = entry.key;
      final info = entry.value;

      if (info.properties.length < minOccurrences) {
        continue;
      }

      final targetType = info.targetType;
      if (targetType is! InterfaceType) continue;

      if (ignoredTypes.contains(targetType.element.name)) continue;

      rule.reportAtNode(
        info.firstAccess!,
        arguments: [info.properties.length.toString(), variableName],
      );
    }
  }
}

class _VariableAccessInfo {
  final Set<String> properties = {};
  final DartType? targetType;
  AstNode? firstAccess;

  _VariableAccessInfo(this.targetType);

  void addAccess(String propertyName, AstNode accessNode) {
    firstAccess ??= accessNode;
    properties.add(propertyName);
  }
}

class _PropertyAccessCollector extends RecursiveAstVisitor<void> {
  final Map<String, _VariableAccessInfo> accessesByVariable = {};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkPropertyAccess(
      targetName: node.prefix.name,
      targetElement: node.prefix.element,
      targetType: node.prefix.staticType,
      propertyName: node.identifier.name,
      accessNode: node,
    );
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      _checkPropertyAccess(
        targetName: target.name,
        targetElement: target.element,
        targetType: target.staticType,
        propertyName: node.propertyName.name,
        accessNode: node,
      );
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _checkPropertyAccess({
    required String targetName,
    required Element? targetElement,
    required DartType? targetType,
    required String propertyName,
    required AstNode accessNode,
  }) {
    if (targetElement is! LocalElement) return;

    final parent = accessNode.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == accessNode) {
      return;
    }

    if (parent is MethodInvocation && parent.target == accessNode) return;

    final info = accessesByVariable.putIfAbsent(
      targetName,
      () => _VariableAccessInfo(targetType),
    );
    info.addAccess(propertyName, accessNode);
  }
}
