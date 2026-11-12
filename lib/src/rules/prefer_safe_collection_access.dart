import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

const _totalAccessorsByThrowingAccessor = {
  'first': 'head',
  'last': 'lastOption',
  'single': 'singleOption',
};

class PreferSafeCollectionAccess extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_safe_collection_access',
    "Use '{0}' instead of '{1}', which throws when there is no element.",
    correctionMessage:
        "The total accessor returns an 'Option', so absence stays in the "
        'value instead of escaping as an exception.',
  );

  PreferSafeCollectionAccess()
    : super(
        name: 'prefer_safe_collection_access',
        description:
            'Warns when a throwing collection accessor is used in an fpdart '
            'pipeline, where absence should be a value rather than an '
            'exception.',
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

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSafeCollectionAccess rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node, node.identifier, node.prefix.staticType);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _check(node, node.propertyName, node.realTarget.staticType);
  }

  void _check(Expression node, SimpleIdentifier property, DartType? type) {
    if (type == null) return;
    if (!_iterableChecker.isAssignableFromType(type)) return;

    final accessors = rule.config.nameSetOption(
      'accessors',
      defaultValue: _totalAccessorsByThrowingAccessor.keys.toSet(),
    );
    final name = property.name;
    if (!accessors.contains(name)) return;

    final reportOutsidePipelines = rule.config.boolOption(
      'report_outside_pipelines',
      defaultValue: false,
    );
    if (!reportOutsidePipelines && !_isInsideFpdartPipeline(node)) return;

    rule.reportAtNode(
      property,
      arguments: [
        _totalAccessorsByThrowingAccessor[name] ?? '${name}Option',
        name,
      ],
    );
  }

  bool _isInsideFpdartPipeline(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is Expression) {
        final type = current.staticType;
        if (type != null && anyFpdartChecker.isAssignableFromType(type)) {
          return true;
        }
      }

      final returnType = switch (current) {
        MethodDeclaration(:final returnType) => returnType?.type,
        FunctionDeclaration(:final returnType) => returnType?.type,
        _ => null,
      };
      if (returnType != null &&
          anyFpdartChecker.isAssignableFromType(returnType)) {
        return true;
      }
    }

    return false;
  }
}
