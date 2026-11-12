import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferExplicitFunctionType extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_explicit_function_type',
    "This 'Function' type does not specify a return type or parameter list.",
    correctionMessage: 'Try adding explicit return type and parameter list.',
  );

  PreferExplicitFunctionType()
    : super(
        name: 'prefer_explicit_function_type',
        description:
            'Warns when a Function type does not specify the return type and arguments.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExplicitFunctionType rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    // Edge case: an explicit `void Function()` is a GenericFunctionType, not visited here
    final typeName = node.name;
    if (typeName.lexeme != 'Function') return;

    final element = node.element;
    if (element == null) return;

    final library = element.library;
    if (library?.isDartCore != true) return;

    rule.reportAtNode(node);
  }
}
