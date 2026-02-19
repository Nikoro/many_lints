import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that adds missing fields to the Equatable `props` list.
class ListAllEquatableFieldsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.listAllEquatableFields',
    DartFixKindPriority.standard,
    'Add missing fields to props',
  );

  ListAllEquatableFieldsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodDeclaration) return;
    if (!targetNode.isGetter || targetNode.name.lexeme != 'props') return;

    // Navigate to enclosing class
    final enclosingBody = targetNode.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    // Collect own fields
    final ownFields = <String>[];
    for (final f in element.fields) {
      if (f.isStatic || !f.isOriginDeclaration) continue;
      final name = f.name;
      if (name != null) ownFields.add(name);
    }
    if (ownFields.isEmpty) return;

    // Extract currently listed field names from props
    final currentNames = _extractPropsFieldNames(targetNode);

    // Find missing fields
    final missingFields = ownFields
        .where((f) => !currentNames.contains(f))
        .toList();
    if (missingFields.isEmpty) return;

    // Find the list literal in props
    final listLiteral = _findPropsListLiteral(targetNode);
    if (listLiteral == null) return;

    // Build the replacement: existing elements + missing fields
    final existingSource = listLiteral.elements
        .map((e) => e.toSource())
        .toList();
    final allElements = [...existingSource, ...missingFields];
    final replacement = '[${allElements.join(', ')}]';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(listLiteral), replacement);
    });
  }

  static Set<String> _extractPropsFieldNames(MethodDeclaration propsGetter) {
    final collector = _IdentifierCollector();
    final body = propsGetter.body;
    if (body is ExpressionFunctionBody) {
      body.expression.accept(collector);
    } else if (body is BlockFunctionBody) {
      body.block.accept(collector);
    }
    return collector.names;
  }

  static ListLiteral? _findPropsListLiteral(MethodDeclaration propsGetter) {
    final body = propsGetter.body;
    if (body is ExpressionFunctionBody) {
      final expr = body.expression;
      if (expr is ListLiteral) return expr;
    } else if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length == 1 && statements.first is ReturnStatement) {
        final returnExpr = (statements.first as ReturnStatement).expression;
        if (returnExpr is ListLiteral) return returnExpr;
      }
    }
    return null;
  }
}

class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
