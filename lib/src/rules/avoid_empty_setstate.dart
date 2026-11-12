import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class AvoidEmptySetstate extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_empty_setstate',
    "'setState' is called with an empty callback.",
    correctionMessage:
        'Move the state mutation inside the callback so the change and the '
        'rebuild request stay together.',
  );

  AvoidEmptySetstate()
    : super(
        name: 'avoid_empty_setstate',
        description:
            'Warns when setState is called with an empty callback, which '
            'hides the state mutation from readers.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEmptySetstate rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;

    final target = node.target;
    if (target != null && target is! ThisExpression) return;

    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) return;
    final element = enclosingClass.declaredFragment?.element;
    if (element == null || !isStateElement(rule, element)) return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final callback = arguments.first;
    if (callback is! FunctionExpression) return;

    if (_isEmptyBody(callback.body)) {
      rule.reportAtNode(node);
    }
  }

  bool _isEmptyBody(FunctionBody body) => switch (body) {
    BlockFunctionBody(:final block) => block.statements.isEmpty,
    _ => false,
  };
}
