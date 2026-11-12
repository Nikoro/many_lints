import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferVoidCallback extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_void_callback',
    "Use 'VoidCallback' instead of 'void Function()'.",
    correctionMessage: "Replace with 'VoidCallback' from 'dart:ui'.",
  );

  PreferVoidCallback()
    : super(
        name: 'prefer_void_callback',
        description:
            'Warns when void Function() is used instead of VoidCallback.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addGenericFunctionType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferVoidCallback rule;

  _Visitor(this.rule);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    final isTypedefBody = node.parent is GenericTypeAlias;
    if (isTypedefBody) return;

    final isGeneric = node.typeParameters != null;
    final hasParameters = node.parameters.parameters.isNotEmpty;
    if (isGeneric || hasParameters) return;

    final returnType = node.returnType;
    if (returnType is! NamedType || returnType.name.lexeme != 'void') return;

    rule.reportAtNode(node);
  }
}
