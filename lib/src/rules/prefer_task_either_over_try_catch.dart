import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

const _defaultSuffixes = {'Repository', 'Service', 'DataSource', 'Client'};

class PreferTaskEitherOverTryCatch extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_task_either_over_try_catch',
    "'{0}' handles failure with 'try'/'catch' instead of returning a "
        "'TaskEither'.",
    correctionMessage:
        "Return 'TaskEither<Failure, T>' built with 'TaskEither.tryCatch', so "
        'the failure is part of the signature.',
  );

  PreferTaskEitherOverTryCatch()
    : super(
        name: 'prefer_task_either_over_try_catch',
        description:
            'Warns when a repository or service method handles failure with '
            'try/catch rather than returning a TaskEither.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTaskEitherOverTryCatch rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;

    if (rule.config.boolOption('ignore_private', defaultValue: true) &&
        name.startsWith('_')) {
      return;
    }

    final enclosing = enclosingClassDeclaration(node);
    if (enclosing == null) return;
    if (!_isBoundaryClass(enclosing.namePart.typeName.lexeme)) return;

    final returnType = node.returnType?.type;
    if (returnType == null) return;
    if (!_futureChecker.isAssignableFromType(returnType)) return;

    if (anyFpdartChecker.isAssignableFromType(returnType)) return;

    final body = node.body;
    if (!_containsTryCatch(body)) return;

    rule.reportAtToken(node.name, arguments: [name]);
  }

  bool _isBoundaryClass(String className) {
    final suffixes = rule.config.nameSetOption(
      'class_suffixes',
      defaultValue: _defaultSuffixes,
    );

    return suffixes.any(className.endsWith);
  }

  bool _containsTryCatch(FunctionBody body) {
    final finder = _TryCatchFinder();
    body.accept(finder);
    return finder.foundCatch;
  }
}

class _TryCatchFinder extends RecursiveAstVisitor<void> {
  bool foundCatch = false;

  // Edge case: a try in a closure is not part of the method's contract.
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitTryStatement(TryStatement node) {
    if (node.catchClauses.isNotEmpty) foundCatch = true;
    super.visitTryStatement(node);
  }
}
