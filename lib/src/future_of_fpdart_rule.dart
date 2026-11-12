import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import 'many_lints_rule.dart';
import 'type_checker.dart';

abstract class FutureOfFpdartRule extends ManyLintsRule {
  FutureOfFpdartRule({required super.name, required super.description});

  TypeChecker get wrappedChecker;

  String get replacementType;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final FutureOfFpdartRule rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node.returnType, node.name.lexeme, node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.returnType, node.name.lexeme, node.functionExpression.body);
  }

  void _check(TypeAnnotation? returnType, String name, FunctionBody body) {
    if (rule.config.boolOption('ignore_private', defaultValue: false) &&
        name.startsWith('_')) {
      return;
    }

    if (body.isGenerator) return;

    if (returnType == null) return;

    final type = returnType.type;
    if (type is! InterfaceType) return;

    // Edge case: FutureOr may complete synchronously, so it gets a different fix
    if (!_futureChecker.isExactlyType(type)) return;

    final argument = type.typeArguments.singleOrNull;
    if (argument == null) return;
    if (!rule.wrappedChecker.isExactlyType(argument)) return;

    rule.reportAtNode(returnType, arguments: [rule.replacementType]);
  }
}
