import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidCollectionEqualityChecks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_collection_equality_checks',
    'Comparing collections with {0} checks reference equality, not contents.',
    correctionMessage:
        'Use DeepCollectionEquality or a type-specific equality helper.',
  );

  AvoidCollectionEqualityChecks()
    : super(
        name: 'avoid_collection_equality_checks',
        description:
            'Warns when mutable collections are compared with == or !=.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidCollectionEqualityChecks rule;

  _Visitor(this.rule);

  static const _collectionChecker = TypeChecker.any([
    TypeChecker.fromUrl('dart:core#List'),
    TypeChecker.fromUrl('dart:core#Set'),
    TypeChecker.fromUrl('dart:core#Map'),
    TypeChecker.fromUrl('dart:core#Iterable'),
  ]);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.type;
    if (op != TokenType.EQ_EQ && op != TokenType.BANG_EQ) return;

    final leftType = node.leftOperand.staticType;
    final rightType = node.rightOperand.staticType;

    if (leftType == null || rightType == null) return;

    final leftIsCollection = _isCollectionType(leftType);
    final rightIsCollection = _isCollectionType(rightType);

    if (!leftIsCollection && !rightIsCollection) return;

    if (node.leftOperand is NullLiteral || node.rightOperand is NullLiteral) {
      return;
    }

    if (_isConstExpression(node.leftOperand) &&
        _isConstExpression(node.rightOperand)) {
      return;
    }

    rule.reportAtNode(node, arguments: [node.operator.lexeme]);
  }

  static bool _isCollectionType(DartType type) {
    return _collectionChecker.isAssignableFromType(type);
  }

  static bool _isConstExpression(Expression expr) {
    var e = expr;
    while (e is ParenthesizedExpression) {
      e = e.expression;
    }

    return switch (e) {
      TypedLiteral(constKeyword: _?) => true,
      InstanceCreationExpression(:final keyword?)
          when keyword.type == Keyword.CONST =>
        true,
      NullLiteral() => true,
      _ => false,
    };
  }
}
