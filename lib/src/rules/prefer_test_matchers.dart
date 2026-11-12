import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferTestMatchers extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_test_matchers',
    'Prefer using a Matcher instead of a literal value in expect().',
    correctionMessage:
        'Use a Matcher such as equals(), isTrue, or '
        'hasLength() instead of a literal value.',
  );

  PreferTestMatchers()
    : super(
        name: 'prefer_test_matchers',
        description:
            'Warns when expect() or expectLater() second argument is not a '
            'Matcher.',
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
  final PreferTestMatchers rule;

  _Visitor(this.rule);

  static const _expectFunctions = {'expect', 'expectLater'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_expectFunctions.contains(node.methodName.name)) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final matcherExpr = args[1];
    if (matcherExpr is NamedArgument) return;

    final matcherType = matcherExpr.argumentExpression.staticType;
    if (matcherType == null || matcherType is DynamicType) return;
    if (_isMatcherType(matcherType)) return;

    rule.reportAtNode(matcherExpr);
  }

  static bool _isMatcherType(DartType type) {
    if (type is! InterfaceType) return false;

    if (type.element.name == 'Matcher') return true;

    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == 'Matcher') return true;
    }

    return false;
  }
}
