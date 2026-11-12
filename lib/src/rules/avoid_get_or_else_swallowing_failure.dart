import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

class AvoidGetOrElseSwallowingFailure extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_get_or_else_swallowing_failure',
    "This 'getOrElse' discards the failure it was given.",
    correctionMessage:
        'Use the failure parameter, or fold with match, so dropping it is a '
        'visible decision.',
  );

  AvoidGetOrElseSwallowingFailure()
    : super(
        name: 'avoid_get_or_else_swallowing_failure',
        description:
            'Warns when getOrElse on Either or TaskEither ignores the failure '
            'parameter, discarding the reason the pipeline carried.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidGetOrElseSwallowingFailure rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'getOrElse') return;

    if (rule.config.boolOption('ignore_tests', defaultValue: true) &&
        (rule.relativePath?.startsWith('test/') ?? false)) {
      return;
    }

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    // Edge case: Option.getOrElse takes no failure, so there is nothing to discard
    if (!failableFpdartChecker.isAssignableFromType(targetType)) return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.isEmpty) return;

    final parameter = parameters.first;
    final name = parameter.name?.lexeme;
    if (name == null) return;

    // Edge case: naming the failure and then ignoring it is the same discard
    if (!_isWildcard(name) && _isReferencedIn(callback.body, name)) return;

    rule.reportAtNode(node.methodName);
  }

  bool _isWildcard(String name) => RegExp(r'^_+$').hasMatch(name);

  bool _isReferencedIn(FunctionBody body, String name) {
    final finder = _IdentifierFinder(name);
    body.accept(finder);
    return finder.found;
  }
}

class _IdentifierFinder extends RecursiveAstVisitor<void> {
  final String name;
  bool found = false;

  _IdentifierFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) found = true;
  }
}
