import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

class AvoidUntypedSafeCast extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_untyped_safe_cast',
    "This 'safeCast' has no explicit type argument, so it always succeeds.",
    correctionMessage:
        "Write the target type explicitly, as in "
        "'Either<L, R>.safeCast(...)' or 'Option<T>.safeCast(...)'.",
  );

  AvoidUntypedSafeCast()
    : super(
        name: 'avoid_untyped_safe_cast',
        description:
            'Warns when Either.safeCast or Option.safeCast is written without '
            'explicit type arguments, which infers the target type as dynamic '
            'and makes the cast always succeed.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUntypedSafeCast rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'safeCast') return;

    final element = constructorName.element;
    if (element == null) return;
    if (!_isFpdartCastTarget(element.enclosingElement)) return;

    if (constructorName.type.typeArguments != null) return;

    if (!_castTargetIsDynamic(node.staticType)) return;

    rule.reportAtNode(constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'safeCastStrict') return;
    if (node.typeArguments != null) return;

    final target = node.realTarget;
    if (target is! Identifier) return;
    final targetElement = target.element;
    if (targetElement == null) return;
    if (!_isFpdartCastTarget(targetElement)) return;

    if (!_castTargetIsDynamic(node.staticType)) return;

    rule.reportAtNode(node.methodName);
  }

  bool _isFpdartCastTarget(Element? element) =>
      element != null &&
      (eitherChecker.isExactly(element) || optionChecker.isExactly(element));

  bool _castTargetIsDynamic(DartType? type) {
    if (type is! InterfaceType) return false;

    final castTarget = type.typeArguments.lastOrNull;
    return castTarget is DynamicType;
  }
}
