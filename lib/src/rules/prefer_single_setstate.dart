import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../set_state_collection.dart';
import '../state_base_classes.dart';

class PreferSingleSetstate extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_single_setstate',
    'Multiple setState calls should be merged into a single call.',
    correctionMessage: 'Merge all setState calls into one.',
  );

  PreferSingleSetstate()
    : super(
        name: 'prefer_single_setstate',
        description:
            'Warns when multiple setState calls in the same method could '
            'be merged into a single invocation.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSingleSetstate rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !isStateElement(rule, element)) return;

    final collector = SetStateCollector();
    node.body.visitChildren(collector);

    final calls = collector.calls;
    if (calls.length < 2) return;

    for (final extraCall in calls.skip(1)) {
      rule.reportAtNode(extraCall);
    }
  }
}
