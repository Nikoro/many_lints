import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidSingleFieldDestructuring extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_single_field_destructuring',
    'Avoid single-field destructuring. Use direct property access instead.',
    correctionMessage:
        'Replace destructuring with direct property access on the expression.',
  );

  AvoidSingleFieldDestructuring()
    : super(
        name: 'avoid_single_field_destructuring',
        description:
            'Warns when a pattern variable declaration destructures only a '
            'single field.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPatternVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSingleFieldDestructuring rule;

  _Visitor(this.rule);

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    final pattern = node.pattern;

    if (pattern is ObjectPattern && pattern.fields.length == 1) {
      rule.reportAtNode(node);
      return;
    }

    if (pattern is RecordPattern && pattern.fields.length == 1) {
      rule.reportAtNode(node);
      return;
    }
  }
}
