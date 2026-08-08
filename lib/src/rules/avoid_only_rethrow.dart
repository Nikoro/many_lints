import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../rule_config.dart';

/// Warns when a catch clause contains only a `rethrow` statement.
///
/// Such catch clauses are redundant because they don't handle exceptions —
/// they simply re-throw them. Either add meaningful exception handling or
/// remove the catch clause entirely.
///
/// **Bad:**
/// ```dart
/// try {
///   doSomething();
/// } catch (e) {
///   rethrow;
/// }
/// ```
///
/// **Good:**
/// ```dart
/// // Option 1: Add exception handling
/// try {
///   doSomething();
/// } catch (e) {
///   logger.error(e);
///   rethrow;
/// }
///
/// // Option 2: Remove redundant catch clause
/// doSomething();
/// ```
class AvoidOnlyRethrow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_only_rethrow',
    'Catch clause contains only a rethrow statement.',
    correctionMessage: 'Remove the redundant try-catch block.',
  );

  AvoidOnlyRethrow()
    : super(
        name: 'avoid_only_rethrow',
        description:
            'Warns when a catch clause contains only a rethrow statement.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addTryStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidOnlyRethrow rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitTryStatement(TryStatement node) {
    // Resolved per node rather than once at registration time: the lookup
    // needs `RuleContext.currentUnit`, which is null while
    // `registerNodeProcessors` runs.
    final resolved = ResolvedRuleConfig.of(context, rule.name);
    if (resolved.isExcluded) return;

    // `ignore_typed_catches: true` limits the rule to untyped `catch (e)`
    // clauses, leaving `on SomeError catch (e) { rethrow; }` alone — that
    // form narrows which exceptions propagate, so it is not always redundant.
    final ignoreTyped = resolved.config.boolOption(
      'ignore_typed_catches',
      defaultValue: false,
    );

    for (final catchClause in node.catchClauses) {
      if (ignoreTyped && catchClause.exceptionType != null) continue;

      final statements = catchClause.body.statements;
      if (statements.length != 1) continue;

      final statement = statements.first;
      if (statement is! ExpressionStatement) continue;

      if (statement.expression is RethrowExpression) {
        rule.reportAtNode(catchClause);
      }
    }
  }
}
