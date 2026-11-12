import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferExplicitTypeArguments extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_explicit_type_arguments',
    "The call to '{0}' has no explicit type arguments.",
    correctionMessage:
        'Write them, so inference cannot pick a surprising type.',
  );

  PreferExplicitTypeArguments()
    : super(
        name: 'prefer_explicit_type_arguments',
        description:
            'Warns when a configured generic call omits its type arguments.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExplicitTypeArguments rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methods = rule.config.nameSetOption(
      'methods',
      defaultValue: const {},
    );
    if (methods.isEmpty) return;

    final name = node.methodName.name;
    if (!methods.contains(name)) return;
    if (node.typeArguments != null) return;

    // Edge case: type arguments on a non-generic call would not compile
    final element = node.methodName.element;
    if (element is! ExecutableElement) return;
    if (element.typeParameters.isEmpty) return;

    rule.reportAtNode(node.methodName, arguments: [name]);
  }
}
