import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidDuplicateCascades extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_cascades',
    'Duplicate cascade section found.',
    correctionMessage: 'Remove the duplicate cascade section.',
  );

  AvoidDuplicateCascades()
    : super(
        name: 'avoid_duplicate_cascades',
        description:
            'Warns when a cascade expression has duplicate cascade '
            'sections.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCascadeExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDuplicateCascades rule;

  _Visitor(this.rule);

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final sections = node.cascadeSections;
    if (sections.length < 2) return;

    final seen = <String>{};
    for (final section in sections) {
      final key = _sectionKey(section);
      if (key == null) continue;

      if (!seen.add(key)) {
        rule.reportAtNode(section);
      }
    }
  }

  static String? _sectionKey(Expression section) {
    return switch (section) {
      AssignmentExpression(:final leftHandSide, :final rightHandSide) =>
        'assign:${leftHandSide.toSource()}=${rightHandSide.toSource()}',
      MethodInvocation(:final methodName, :final argumentList) =>
        'call:${methodName.name}(${argumentList.arguments.map((a) => a.toSource()).join(',')})',
      IndexExpression(:final index) => 'index:${index.toSource()}',
      PropertyAccess(:final propertyName) => 'prop:${propertyName.name}',
      _ => null,
    };
  }
}
