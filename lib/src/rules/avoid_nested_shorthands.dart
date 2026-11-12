import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidNestedShorthands extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_nested_shorthands',
    'Dot shorthand is nested inside another dot shorthand.',
    correctionMessage: 'Try writing the type name explicitly.',
  );

  AvoidNestedShorthands()
    : super(
        name: 'avoid_nested_shorthands',
        description:
            'Warns when a dot shorthand is nested inside another dot shorthand '
            'invocation, leaving no type name for the reader to anchor on.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addDotShorthandConstructorInvocation(this, visitor);
    // Edge case: static method calls keep this node type after resolution, constructors do not
    registry.addDotShorthandInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNestedShorthands rule;

  _Visitor(this.rule);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _checkArguments(node.argumentList);

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) =>
      _checkArguments(node.argumentList);

  void _checkArguments(ArgumentList argumentList) {
    final finder = _NestedShorthandFinder();
    argumentList.accept(finder);

    for (final nested in finder.found) {
      rule.reportAtNode(nested);
    }
  }
}

// Edge case: the visits skip super so a deeply nested shorthand is reported once, by its parent
class _NestedShorthandFinder extends RecursiveAstVisitor<void> {
  final List<Expression> found = [];

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => found.add(node);

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) =>
      found.add(node);

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) =>
      found.add(node);
}
