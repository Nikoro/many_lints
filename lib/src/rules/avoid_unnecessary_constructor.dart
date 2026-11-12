import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidUnnecessaryConstructor extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_constructor',
    'This constructor is identical to the default one.',
    correctionMessage: 'Remove it; Dart provides this constructor already.',
  );

  AvoidUnnecessaryConstructor()
    : super(
        name: 'avoid_unnecessary_constructor',
        description:
            'Warns when a class declares an empty unnamed constructor that '
            'matches the one Dart would provide anyway.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryConstructor rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final constructors = body.members.whereType<ConstructorDeclaration>();

    // Edge case: with a second constructor, Dart no longer supplies the unnamed one
    if (constructors.length != 1) return;

    final constructor = constructors.first;

    if (constructor.name != null) return;

    if (constructor.constKeyword != null) return;

    if (constructor.factoryKeyword != null) return;
    if (constructor.parameters.parameters.isNotEmpty) return;
    if (constructor.initializers.isNotEmpty) return;
    if (constructor.redirectedConstructor != null) return;

    if (constructor.documentationComment != null) return;
    if (constructor.metadata.isNotEmpty) return;

    final hasNoBody = switch (constructor.body) {
      EmptyFunctionBody() => true,
      BlockFunctionBody(:final block) => block.statements.isEmpty,
      _ => false,
    };
    if (!hasNoBody) return;

    rule.reportAtNode(constructor);
  }
}
