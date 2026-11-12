import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferSwitchExpression extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_switch_expression',
    'This switch statement can be converted to a switch expression.',
    correctionMessage: 'Try using a switch expression instead.',
  );

  PreferSwitchExpression()
    : super(
        name: 'prefer_switch_expression',
        description:
            'Suggests converting switch statements to switch expressions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSwitchExpression rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    final members = node.members;
    if (members.isEmpty) return;
    if (!_canConvertToExpression(members)) return;

    rule.reportAtToken(node.switchKeyword);
  }

  bool _canConvertToExpression(List<SwitchMember> members) {
    final allowFallthrough = rule.config.boolOption(
      'allow_fallthrough_cases',
      defaultValue: false,
    );
    String? assignmentTarget;
    bool hasReturn = false;
    bool fallthroughAwaitsBody = false;

    for (final member in members) {
      final statements = member.statements;

      if (statements.isEmpty) {
        if (!allowFallthrough) return false;
        fallthroughAwaitsBody = true;
        continue;
      }
      fallthroughAwaitsBody = false;

      if (statements.length != 1) return false;

      switch (statements.first) {
        case ReturnStatement(expression: _?):
          if (assignmentTarget != null) return false;
          hasReturn = true;
        case ExpressionStatement(
          expression: AssignmentExpression(
            leftHandSide: SimpleIdentifier(name: final target),
          ),
        ):
          if (hasReturn) return false;
          assignmentTarget ??= target;
          if (assignmentTarget != target) return false;
        default:
          return false;
      }
    }

    // Edge case: a trailing fallthrough has no body to merge its pattern into.
    return !fallthroughAwaitsBody;
  }
}
