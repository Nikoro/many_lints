import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a class extending `Equatable` or using `EquatableMixin` does not
/// include all of its declared instance fields in the `props` getter.
class ListAllEquatableFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'list_all_equatable_fields',
    'Not all fields are listed in props. Missing: {0}.',
    correctionMessage: 'Add the missing fields to the props list.',
  );

  ListAllEquatableFields()
    : super(
        name: 'list_all_equatable_fields',
        description:
            'Warns when an Equatable class does not list all instance '
            'fields in props.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ListAllEquatableFields rule;

  _Visitor(this.rule);

  static const _equatableChecker = TypeChecker.any([
    TypeChecker.fromName('Equatable', packageName: 'equatable'),
    TypeChecker.fromName('EquatableMixin', packageName: 'equatable'),
  ]);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    // Check if the class extends Equatable or uses EquatableMixin
    if (!_equatableChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    // Collect all own non-static instance fields
    final ownFields = _collectOwnFields(element);
    if (ownFields.isEmpty) return;

    // Find the props getter with a list literal body
    final propsGetter = _findPropsGetter(body);
    if (propsGetter == null) return;

    final listLiteral = _findPropsListLiteral(propsGetter);
    if (listLiteral == null) return;

    // Extract field names referenced in the list literal
    final propsFieldNames = _extractPropsFieldNames(listLiteral);

    // Find missing fields
    final missingFields = ownFields
        .where((f) => !propsFieldNames.contains(f))
        .toList();

    if (missingFields.isNotEmpty) {
      rule.reportAtNode(propsGetter, arguments: [missingFields.join(', ')]);
    }
  }

  /// Collects the names of all non-static instance fields declared directly
  /// on this class (not inherited).
  static List<String> _collectOwnFields(ClassElement element) {
    final names = <String>[];
    for (final f in element.fields) {
      if (f.isStatic || !f.isOriginDeclaration) continue;
      final name = f.name;
      if (name != null) names.add(name);
    }
    return names;
  }

  /// Finds the `props` getter in the class body.
  static MethodDeclaration? _findPropsGetter(BlockClassBody body) {
    for (final member in body.members) {
      if (member is MethodDeclaration &&
          member.isGetter &&
          member.name.lexeme == 'props') {
        return member;
      }
    }
    return null;
  }

  /// Finds the list literal in the props getter body.
  /// Handles both `=> [a, b]` and `{ return [a, b]; }` forms.
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

  /// Extracts field name identifiers from a list literal.
  static Set<String> _extractPropsFieldNames(ListLiteral listLiteral) {
    final collector = _IdentifierCollector();
    listLiteral.accept(collector);
    return collector.names;
  }
}

/// Recursively collects all [SimpleIdentifier] names in an expression tree.
class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
