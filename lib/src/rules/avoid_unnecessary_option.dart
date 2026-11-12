import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

const _composingCombinators = {
  'map',
  'flatMap',
  'andThen',
  'alt',
  'match',
  'fold',
  'toEither',
  'filter',
};

class AvoidUnnecessaryOption extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_option',
    "This 'Option' is never composed, so a nullable type would read better.",
    correctionMessage:
        "Use 'T?' and Dart's null-aware operators, or use one of Option's "
        'combinators to earn the wrapper.',
  );

  AvoidUnnecessaryOption()
    : super(
        name: 'avoid_unnecessary_option',
        description:
            'Warns when a local Option is wrapped and unwrapped without any '
            'combinator in between, where a nullable type reads better.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryOption rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredFragment?.element is! LocalVariableElement) return;

    final initializer = node.initializer;
    if (initializer == null) return;

    final type = initializer.staticType;
    if (type == null) return;
    if (!optionChecker.isAssignableFromType(type)) return;

    if (rule.config.boolOption('ignore_public_api', defaultValue: true) &&
        _escapesToPublicApi(node)) {
      return;
    }

    final body = node.thisOrAncestorOfType<FunctionBody>();
    if (body == null) return;

    final name = node.name.lexeme;
    final usage = _CombinatorUsageFinder(name);
    body.accept(usage);

    if (usage.reads == 0) return;
    if (usage.composed) return;

    rule.reportAtToken(node.name);
  }

  bool _escapesToPublicApi(AstNode node) {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method != null) return !method.name.lexeme.startsWith('_');

    final function = node.thisOrAncestorOfType<FunctionDeclaration>();
    if (function != null) return !function.name.lexeme.startsWith('_');

    return false;
  }
}

class _CombinatorUsageFinder extends RecursiveAstVisitor<void> {
  final String name;
  int reads = 0;
  bool composed = false;

  _CombinatorUsageFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != name) return;

    reads++;

    final parent = node.parent;
    if (parent is MethodInvocation && parent.realTarget == node) {
      if (_composingCombinators.contains(parent.methodName.name)) {
        composed = true;
      }
      return;
    }

    final isPassedOnAsValue =
        parent is! PropertyAccess && parent is! PrefixedIdentifier;
    if (isPassedOnAsValue) composed = true;
  }
}
