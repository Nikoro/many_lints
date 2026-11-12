import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

const _removedApi = {
  'Tuple2': 'a Dart record, (a, b)',
  'Tuple3': 'a Dart record, (a, b, c)',
  'Predicate': 'the function extensions (negate, and, or, contramap)',
  'idFuture': 'identity',
  'concatMap': 'flatMap',
  'bindWithIndex': 'flatMapWithIndex',
  'plus': 'concat',
};

class AvoidRemovedFpdartApi extends ManyLintsRule {
  static const LintCode code = LintCode(
    "avoid_removed_fpdart_api",
    "'{0}' was removed in fpdart 1.0.0.",
    correctionMessage: 'Use {1} instead.',
  );

  AvoidRemovedFpdartApi()
    : super(
        name: 'avoid_removed_fpdart_api',
        description:
            'Warns when code uses an fpdart name that was removed in 1.0.0, '
            'such as Tuple2 or the Predicate class.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRemovedFpdartApi rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final importsFpdart = node.directives.any(
      (directive) =>
          directive is ImportDirective &&
          (directive.uri.stringValue?.startsWith('package:fpdart/') ?? false),
    );
    if (!importsFpdart) return;

    node.accept(_IdentifierVisitor(rule));
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final AvoidRemovedFpdartApi rule;

  _IdentifierVisitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;

    final replacement = _removedApi[name];
    final isConfigured = rule.config
        .stringListOption('additional_removed')
        .contains(name);

    if (replacement == null && !isConfigured) return;

    final resolves = node.element != null;
    // Edge case: a configured name still resolves, to a 1.x API whose meaning changed
    if (!isConfigured && resolves) return;
    if (_isDeclaredName(node)) return;

    rule.reportAtNode(
      node,
      arguments: [name, replacement ?? 'the 1.x replacement'],
    );
  }

  // Edge case: an initializer also hangs off VariableDeclaration, so only the name token counts
  bool _isDeclaredName(SimpleIdentifier node) => switch (node.parent) {
    VariableDeclaration(:final name) ||
    NamedType(:final name) => name == node.token,
    _ => false,
  };
}
