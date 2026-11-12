import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidUnrunTask extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unrun_task',
    "This '{0}' is discarded without being run, so its work never happens.",
    correctionMessage:
        "Call '.run()' on it and await the result, or return it so the caller "
        'can run it.',
  );

  AvoidUnrunTask()
    : super(
        name: 'avoid_unrun_task',
        description:
            'Warns when a lazy fpdart value (Task, TaskEither, IO, ...) is '
            'discarded without calling run(), so the work it describes never '
            'executes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addExpressionStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnrunTask rule;

  _Visitor(this.rule);

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;

    if (expression is AssignmentExpression) return;

    if (rule.config.boolOption('ignore_cascades', defaultValue: false) &&
        expression is CascadeExpression) {
      return;
    }

    final type = expression.staticType;
    if (type == null) return;

    final name = _lazyTypeName(type);
    if (name == null) return;

    rule.reportAtNode(expression, arguments: [name]);
  }

  String? _lazyTypeName(DartType type) {
    if (lazyFpdartChecker.isAssignableFromType(type)) {
      return type is InterfaceType ? type.element.name : 'lazy value';
    }

    for (final extra in rule.config.stringListOption('additional_types')) {
      if (TypeChecker.fromName(extra).isAssignableFromType(type)) return extra;
    }

    return null;
  }
}
