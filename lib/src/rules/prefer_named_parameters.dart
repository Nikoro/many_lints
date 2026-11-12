import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferNamedParameters extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_named_parameters',
    'This declaration takes {0} positional parameters.',
    correctionMessage: 'Name them, so the call site says what they mean.',
  );

  PreferNamedParameters()
    : super(
        name: 'prefer_named_parameters',
        description:
            'Warns when a declaration takes more than a few positional '
            'parameters.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferNamedParameters rule;

  _Visitor(this.rule);

  static const _defaultIgnoredNames = {'main', 'onRequest', 'middleware'};

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isOperator) return;
    if (node.isSetter) return;
    if (_isOverride(node.metadata)) return;
    if (_isIgnoredName(node.name.lexeme)) return;

    _check(node.parameters);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isOverride(node.metadata)) return;
    if (_isIgnoredName(node.name.lexeme)) return;

    _check(node.functionExpression.parameters);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final ignorePrivateConstructors = rule.config.boolOption(
      'ignore_private_constructors',
      defaultValue: true,
    );
    final isPrivateConstructor = node.name?.lexeme.startsWith('_') ?? false;
    if (ignorePrivateConstructors && isPrivateConstructor) return;

    _check(node.parameters);
  }

  bool _isIgnoredName(String name) {
    final ignored = rule.config.nameSetOption(
      'ignored_names',
      defaultValue: _defaultIgnoredNames,
    );

    return ignored.contains(name);
  }

  void _check(FormalParameterList? parameters) {
    if (parameters == null) return;

    final maxPositional = rule.config.intOption(
      'max_positional',
      defaultValue: 2,
    );

    final positional = parameters.parameters
        .where((p) => p.isPositional)
        .length;
    if (positional <= maxPositional) return;

    rule.reportAtNode(parameters, arguments: ['$positional']);
  }

  bool _isOverride(NodeList<Annotation> metadata) =>
      metadata.any((a) => a.name.name == 'override');
}
