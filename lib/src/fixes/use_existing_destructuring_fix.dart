import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that adds the accessed property to the existing destructuring pattern
/// and replaces the property access with the destructured variable name.
class UseExistingDestructuringFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useExistingDestructuring',
    DartFixKindPriority.standard,
    'Add to existing destructuring',
  );

  UseExistingDestructuringFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Extract the property name and source variable
    final String propertyName;
    final String sourceName;

    if (targetNode is PrefixedIdentifier) {
      sourceName = targetNode.prefix.name;
      propertyName = targetNode.identifier.name;
    } else if (targetNode is PropertyAccess) {
      final target = targetNode.target;
      if (target is! SimpleIdentifier) return;
      sourceName = target.name;
      propertyName = targetNode.propertyName.name;
    } else {
      return;
    }

    // Find the destructuring declaration in the enclosing block
    final pattern = _findDestructuringPattern(targetNode, sourceName);
    if (pattern == null) return;

    // Find the last field in the pattern to insert after it
    final NodeList<PatternField> fields;
    if (pattern is ObjectPattern) {
      fields = pattern.fields;
    } else if (pattern is RecordPattern) {
      fields = pattern.fields;
    } else {
      return;
    }

    if (fields.isEmpty) return;

    final lastField = fields.last;

    await builder.addDartFileEdit(file, (builder) {
      // 1. Add the new field to the destructuring pattern
      builder.addSimpleInsertion(lastField.end, ', :$propertyName');

      // 2. Replace the property access with the variable name
      builder.addSimpleReplacement(range.node(targetNode), propertyName);
    });
  }

  /// Finds the destructuring pattern for the given source variable in the
  /// enclosing block.
  static DartPattern? _findDestructuringPattern(
    AstNode node,
    String sourceName,
  ) {
    // Walk up to find the enclosing Block
    AstNode? current = node.parent;
    while (current != null && current is! Block) {
      current = current.parent;
    }
    if (current is! Block) return null;

    final targetOffset = node.offset;

    for (final statement in current.statements) {
      if (statement.offset >= targetOffset) break;

      if (statement is! PatternVariableDeclarationStatement) continue;
      final decl = statement.declaration;
      final expression = decl.expression;

      if (expression is SimpleIdentifier && expression.name == sourceName) {
        // Verify it's a local variable/parameter
        if (expression.element is! LocalElement) continue;
        return decl.pattern;
      }
    }

    return null;
  }
}
