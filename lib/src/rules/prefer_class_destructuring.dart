import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when multiple properties of the same object are accessed separately
/// and could be consolidated using Dart 3 class destructuring.
///
/// When 3 or more distinct properties are accessed on the same variable,
/// suggest using destructuring syntax instead:
///
/// ```dart
/// // Bad
/// final a = obj.x;
/// final b = obj.y;
/// print(obj.z);
///
/// // Good
/// final SomeClass(:x, :y, :z) = obj;
/// final a = x;
/// final b = y;
/// print(z);
/// ```
class PreferClassDestructuring extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_class_destructuring',
    'Consider using class destructuring for {0} property accesses on '
        "'{1}'.",
    correctionMessage:
        'Use a destructuring declaration to extract all properties at once.',
  );

  /// Minimum number of distinct property accesses to trigger the lint.
  static const _minOccurrences = 3;

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
  void registerNodeProcessors(
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
    // Collect property accesses grouped by target variable
    final collector = _PropertyAccessCollector();
    for (final statement in node.statements) {
      statement.accept(collector);
    }

    // Report variables with enough distinct property accesses
    for (final entry in collector.accessesByVariable.entries) {
      final variableName = entry.key;
      final info = entry.value;

      if (info.properties.length < PreferClassDestructuring._minOccurrences) {
        continue;
      }

      // Only suggest destructuring for interface types (classes, enums, etc.)
      if (info.targetType is! InterfaceType) continue;

      // Report at the first property access occurrence
      rule.reportAtNode(
        info.firstAccess,
        arguments: [info.properties.length.toString(), variableName],
      );
    }
  }
}

/// Tracks property access info for a variable.
class _VariableAccessInfo {
  final Set<String> properties = {};
  final DartType? targetType;
  late final AstNode firstAccess;
  bool _hasFirst = false;

  _VariableAccessInfo(this.targetType);

  void addAccess(String propertyName, AstNode accessNode) {
    if (!_hasFirst) {
      firstAccess = accessNode;
      _hasFirst = true;
    }
    properties.add(propertyName);
  }
}

/// Collects property accesses within a block, grouped by target variable.
///
/// Only collects simple property reads (not method calls, not assignments).
/// Stops at nested function boundaries to avoid mixing scopes.
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
    // Don't recurse into children — we already processed both parts
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
    // Don't recurse into target — we already processed it
    // But do recurse into the property name in case of chaining
  }

  // Stop at nested function boundaries
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
    // Only track local variables and parameters (not fields, top-level, etc.)
    if (targetElement is! LocalElement) return;

    // Skip if the parent is an assignment target (writing, not reading)
    final parent = accessNode.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == accessNode) {
      return;
    }

    // Skip method calls — only track field/getter accesses
    if (parent is MethodInvocation && parent.target == accessNode) return;

    final info = accessesByVariable.putIfAbsent(
      targetName,
      () => _VariableAccessInfo(targetType),
    );
    info.addAccess(propertyName, accessNode);
  }
}
