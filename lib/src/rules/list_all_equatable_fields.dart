import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../type_checker.dart';

class ListAllEquatableFields extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

    if (!_equatableChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final ownFields = _collectOwnFields(element);
    if (ownFields.isEmpty) return;

    final propsGetter = _findPropsGetter(body);
    if (propsGetter == null) return;

    final listLiteral = _findPropsListLiteral(propsGetter);
    if (listLiteral == null) return;

    final propsFieldNames = _extractPropsFieldNames(listLiteral);

    final missingFields = ownFields
        .where((f) => !propsFieldNames.contains(f))
        .toList();

    if (missingFields.isNotEmpty) {
      rule.reportAtNode(propsGetter, arguments: [missingFields.join(', ')]);
    }
  }

  static List<String> _collectOwnFields(ClassElement element) {
    final names = <String>[];
    for (final f in element.fields) {
      if (f.isStatic || !f.isOriginDeclaration) continue;
      final name = f.name;
      if (name != null) names.add(name);
    }
    return names;
  }

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

  static ListLiteral? _findPropsListLiteral(MethodDeclaration propsGetter) {
    final expr = maybeGetSingleReturnExpression(propsGetter.body);
    return expr is ListLiteral ? expr : null;
  }

  static Set<String> _extractPropsFieldNames(ListLiteral listLiteral) {
    final collector = _IdentifierCollector();
    listLiteral.accept(collector);
    return collector.names;
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
