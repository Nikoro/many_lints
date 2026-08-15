import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function takes more parameters than the configured budget.
///
/// A long parameter list is usually several values that belong together
/// travelling separately, and every caller has to assemble them in the right
/// order. Grouping them into a record or a small class names the thing they
/// form and makes the call sites read.
///
/// Named parameters are counted separately and given a larger budget, since
/// they are labelled at the call site and do not depend on order — a widget
/// constructor with eight named parameters is not the problem this rule
/// exists for.
class AvoidLongParameterList extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_long_parameter_list',
    'This takes {0} {1} parameters, over the limit of {2}.',
    correctionMessage: 'Group the related ones into a record or a small class.',
  );

  AvoidLongParameterList()
    : super(
        name: 'avoid_long_parameter_list',
        description:
            'Warns when a function takes more parameters than the configured '
            'budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

/// Past four positional arguments, a call site stops being readable.
const _defaultMaxPositional = 4;

/// Named parameters are labelled at the call site, so they scale further.
const _defaultMaxNamed = 10;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidLongParameterList rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.parameters, node.name, null);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // An override cannot change its signature.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _check(node.parameters, node.name, null);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _check(node.parameters, node.name, node);

  void _check(FormalParameterList? parameters, Token? name, AstNode? fallback) {
    if (parameters == null) return;

    final maxPositional = rule.config.intOption(
      'max_positional',
      defaultValue: _defaultMaxPositional,
    );
    final maxNamed = rule.config.intOption(
      'max_named',
      defaultValue: _defaultMaxNamed,
    );

    var positional = 0;
    var named = 0;
    for (final parameter in parameters.parameters) {
      if (parameter.isNamed) {
        named++;
      } else {
        positional++;
      }
    }

    final (count, kind, limit) = switch ((positional, named)) {
      _ when positional > maxPositional => (
        positional,
        'positional',
        maxPositional,
      ),
      _ when named > maxNamed => (named, 'named', maxNamed),
      _ => (0, '', 0),
    };
    if (count == 0) return;

    final arguments = ['$count', kind, '$limit'];
    if (name != null) {
      rule.reportAtToken(name, arguments: arguments);
    } else if (fallback != null) {
      rule.reportAtNode(fallback, arguments: arguments);
    }
  }
}
