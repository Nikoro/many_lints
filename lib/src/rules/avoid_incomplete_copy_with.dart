import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidIncompleteCopyWith extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_incomplete_copy_with',
    'copyWith is missing constructor parameters: {0}.',
    correctionMessage:
        'Add the missing parameters to copyWith so all fields can be copied.',
  );

  AvoidIncompleteCopyWith()
    : super(
        name: 'avoid_incomplete_copy_with',
        description:
            'Warns when a copyWith method does not include all parameters '
            'from the class constructor.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidIncompleteCopyWith rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final constructor = body.members
        .whereType<ConstructorDeclaration>()
        .where((c) => c.name == null)
        .firstOrNull;
    if (constructor == null) return;

    final constructorParams = <String>{};
    for (final param in constructor.parameters.parameters) {
      final name = param.name?.lexeme;
      if (name != null) constructorParams.add(name);
    }

    if (constructorParams.isEmpty) return;

    final copyWithMethod = body.members
        .whereType<MethodDeclaration>()
        .where((m) => m.name.lexeme == 'copyWith')
        .firstOrNull;
    if (copyWithMethod == null) return;

    final copyWithParams = <String>{};
    final parameters = copyWithMethod.parameters?.parameters;
    if (parameters != null) {
      for (final param in parameters) {
        final name = param.name?.lexeme;
        if (name != null) copyWithParams.add(name);
      }
    }

    final missing = constructorParams.difference(copyWithParams);
    if (missing.isEmpty) return;

    rule.reportAtToken(copyWithMethod.name, arguments: [missing.join(', ')]);
  }
}
