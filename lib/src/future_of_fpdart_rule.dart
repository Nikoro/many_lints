import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import 'many_lints_rule.dart';
import 'type_checker.dart';

/// Shared implementation of the "`Future<X>` should be the lazy fpdart type"
/// rules.
///
/// `avoid_future_of_either` and `avoid_future_of_option` are one mechanism
/// applied to two types, but they ship as separate rules on purpose: a rule
/// name is a claim about what it reports, and a project that wants only the
/// `Either` half should not have to accept the `Option` half to get it.
/// Sharing the base keeps that split from costing anything in duplicated
/// analysis.
abstract class FutureOfFpdartRule extends ManyLintsRule {
  FutureOfFpdartRule({required super.name, required super.description});

  /// The synchronous wrapper this rule looks for inside a `Future`.
  TypeChecker get wrappedChecker;

  /// The fpdart type that already means "async [wrappedChecker]".
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

    // A generator yields many values; a single lazy wrapper cannot stand in
    // for a stream of them.
    if (body.isGenerator) return;

    if (returnType == null) return;

    final type = returnType.type;
    if (type is! InterfaceType) return;

    // Exactly `Future`, not `FutureOr` — the latter may complete
    // synchronously, so it is a different shape with a different fix.
    if (!_futureChecker.isExactlyType(type)) return;

    final argument = type.typeArguments.singleOrNull;
    if (argument == null) return;
    if (!rule.wrappedChecker.isExactlyType(argument)) return;

    rule.reportAtNode(returnType, arguments: [rule.replacementType]);
  }
}
