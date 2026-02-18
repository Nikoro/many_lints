import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that introduces a class destructuring declaration to replace
/// multiple property accesses on the same variable.
class PreferClassDestructuringFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferClassDestructuring',
    DartFixKindPriority.standard,
    'Extract properties with destructuring',
  );

  PreferClassDestructuringFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Find the variable name and enclosing block
    final String variableName;
    final DartType? variableType;
    if (targetNode is PrefixedIdentifier) {
      variableName = targetNode.prefix.name;
      variableType = targetNode.prefix.staticType;
    } else if (targetNode is PropertyAccess) {
      final target = targetNode.target;
      if (target is! SimpleIdentifier) return;
      variableName = target.name;
      variableType = target.staticType;
    } else {
      return;
    }

    if (variableType is! InterfaceType) return;
    final typeName = variableType.element.name;
    if (typeName == null) return;

    // Find the enclosing block
    final block = _findEnclosingBlock(targetNode);
    if (block == null) return;

    // Collect all distinct property names accessed on this variable
    final collector = _FixPropertyCollector(variableName);
    for (final statement in block.statements) {
      statement.accept(collector);
    }

    if (collector.properties.isEmpty) return;

    final sortedProperties = collector.properties.toList()..sort();
    final destructuring =
        'final $typeName(${sortedProperties.map((p) => ':$p').join(', ')}) = '
        '$variableName;\n';

    // Find the statement containing the first property access
    final firstStatement = _findContainingStatement(
      block,
      collector.firstAccess!,
    );
    if (firstStatement == null) return;

    // Calculate indentation from the first statement
    final content = unitResult.content;
    final lineStart = content.lastIndexOf('\n', firstStatement.offset) + 1;
    final indent = content.substring(lineStart, firstStatement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
        firstStatement.offset,
        '$destructuring$indent',
      );
    });
  }

  static Block? _findEnclosingBlock(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is Block) return current;
      current = current.parent;
    }
    return null;
  }

  static Statement? _findContainingStatement(Block block, AstNode node) {
    for (final statement in block.statements) {
      if (_containsNode(statement, node)) return statement;
    }
    return null;
  }

  static bool _containsNode(AstNode parent, AstNode target) {
    return parent.offset <= target.offset && target.end <= parent.end;
  }
}

/// Collects distinct property names accessed on a specific variable.
class _FixPropertyCollector extends RecursiveAstVisitor<void> {
  final String variableName;
  final Set<String> properties = {};
  AstNode? firstAccess;

  _FixPropertyCollector(this.variableName);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == variableName &&
        node.prefix.element is LocalElement) {
      _addProperty(node.identifier.name, node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier &&
        target.name == variableName &&
        target.element is LocalElement) {
      _addProperty(node.propertyName.name, node);
    }
  }

  // Stop at nested function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _addProperty(String name, AstNode accessNode) {
    // Skip if used as method call target or assignment target
    final parent = accessNode.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == accessNode) {
      return;
    }
    if (parent is MethodInvocation && parent.target == accessNode) return;

    firstAccess ??= accessNode;
    properties.add(name);
  }
}
