import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

const _syncCheckers = TypeChecker.any([eitherChecker, optionChecker]);

class AvoidEitherOfFuture extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_either_of_future',
    "Avoid nesting a 'Future' inside '{0}'.",
    correctionMessage:
        "Convert to the async world with 'toTaskEither()' (or "
        "'toTaskOption()') and keep chaining there, so failures stay in the "
        'error channel.',
  );

  AvoidEitherOfFuture()
    : super(
        name: 'avoid_either_of_future',
        description:
            'Warns when a Future is nested inside the synchronous Either or '
            'Option, where the error channel no longer covers it.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEitherOfFuture rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitNamedType(NamedType node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) return;

    final type = node.type;
    if (type == null) return;
    if (!_syncCheckers.isAssignableFromType(type)) return;

    // Edge case: the success channel is last in both Either<L, R> and Option<T>
    final valueType = typeArguments.last;
    final resolved = valueType.type;
    if (resolved == null) return;
    if (!_futureChecker.isAssignableFromType(resolved)) return;

    rule.reportAtNode(valueType, arguments: [_wrapperName(type)]);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'map') return;

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!_syncCheckers.isAssignableFromType(targetType)) return;

    final resultType = node.staticType;
    if (resultType is! InterfaceType) return;

    final typeArguments = resultType.typeArguments;
    if (typeArguments.isEmpty) return;
    if (!_futureChecker.isAssignableFromType(typeArguments.last)) return;

    rule.reportAtNode(node.methodName, arguments: [_wrapperName(targetType)]);
  }

  String _wrapperName(DartType type) =>
      type is InterfaceType ? type.element.name ?? 'Either' : 'Either';
}
