import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a boolean is a positional parameter rather than a named one.
///
/// A positional boolean is invisible at the call site: `save(true)` says
/// nothing about what is true, and `setVisible(false, true)` is a puzzle every
/// reader has to solve by opening the declaration. `save(force: true)` needs no
/// lookup.
///
/// It is also the parameter most likely to be passed in the wrong order, since
/// swapping two booleans still type-checks.
///
/// An **override is never reported**: the signature belongs to whoever declared
/// it, and changing it in a subclass is not possible. A single positional
/// boolean on a setter-like method is also skipped by default, since
/// `setEnabled(true)` reads acceptably — set `allow_single: false` to report it.
class PreferNamedBooleanParameters extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_named_boolean_parameters',
    "The boolean parameter '{0}' is positional.",
    correctionMessage:
        'Make it named, so the call site says what the boolean means.',
  );

  PreferNamedBooleanParameters()
    : super(
        name: 'prefer_named_boolean_parameters',
        description:
            'Warns when a boolean parameter is positional rather than named.',
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

class _Visitor extends SimpleAstVisitor<void> {
  final PreferNamedBooleanParameters rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.parameters, isOverride: false);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _check(
    node.parameters,
    isOverride: node.metadata.any((a) => a.name.name == 'override'),
  );

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _check(node.parameters, isOverride: false);

  void _check(FormalParameterList? parameters, {required bool isOverride}) {
    if (parameters == null) return;
    // An override cannot change the signature it inherits.
    if (isOverride) return;

    final positional = parameters.parameters
        .where((parameter) => parameter.isPositional)
        .toList(growable: false);

    final allowSingle = rule.config.boolOption(
      'allow_single',
      defaultValue: true,
    );
    // `setEnabled(true)` reads acceptably; `setVisible(false, true)` does not.
    if (allowSingle && positional.length == 1) return;

    for (final parameter in positional) {
      if (!_isBoolean(parameter)) continue;

      final name = parameter.name;
      if (name == null) continue;

      rule.reportAtToken(name, arguments: [name.lexeme]);
    }
  }

  bool _isBoolean(FormalParameter parameter) {
    final type = parameter.declaredFragment?.element.type;
    return type != null && type.isDartCoreBool;
  }
}
