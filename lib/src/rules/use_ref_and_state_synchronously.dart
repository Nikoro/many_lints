import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../riverpod_type_checkers.dart';

/// Warns when `ref` or `state` is accessed after an `await` point inside a
/// Riverpod Notifier method without checking `ref.mounted`.
///
/// If the notifier is disposed before the async operation completes, accessing
/// `ref` or `state` will throw an `UnmountedRefException`.
class UseRefAndStateSynchronously extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_ref_and_state_synchronously',
    "Don't use 'ref' or 'state' after an async gap without checking "
        "'ref.mounted'.",
    correctionMessage:
        "Add 'if (!ref.mounted) return;' before accessing 'ref' or 'state' "
        'after an await.',
  );

  UseRefAndStateSynchronously()
    : super(
        name: 'use_ref_and_state_synchronously',
        description:
            'Warns when ref or state is accessed after an await point in '
            'a Riverpod Notifier without a mounted guard.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseRefAndStateSynchronously rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Only check async methods
    if (!node.body.isAsynchronous) return;

    // Navigate to the enclosing class
    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !notifierChecker.isSuperOf(element)) return;

    // Walk the method body to find ref/state usage after await
    final body = node.body;
    if (body is! BlockFunctionBody) return;

    _checkStatements(body.block.statements);
  }

  /// Checks a list of statements for ref/state usage after an await point.
  void _checkStatements(NodeList<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      // Check if this statement contains an await
      if (!seenAwait) {
        seenAwait = _containsAwait(statement);
        if (seenAwait) {
          // Also check this same statement for ref/state usage AFTER the await
          // e.g., `state = await someAsyncFn();` — state is the target, fine
          // e.g., `final x = await foo(); ref.read(p);` — not possible in
          // single expression, but compound statements need checking
        }
        continue;
      }

      // After an await: check for mounted guard that resets context
      if (_isMountedGuardWithReturn(statement)) {
        // A mounted guard resets the "seen await" state —
        // code after this guard is safe until the next await
        seenAwait = false;
        continue;
      }

      // Check if this statement contains another await (resets for next pass)
      if (_containsAwait(statement)) {
        // Report any ref/state usage in this statement before the await
        final finder = _RefStateFinder(rule);
        statement.accept(finder);
        continue;
      }

      // Report ref/state usage after an await without a mounted guard
      final finder = _RefStateFinder(rule);
      statement.accept(finder);

      // If the statement is an if/for/while with its own block, check nested
      if (statement is IfStatement) {
        // The RecursiveAstVisitor in _RefStateFinder handles nested blocks
      }
    }
  }

  /// Returns true if the statement is a mounted guard pattern:
  /// `if (!ref.mounted) return;` or `if (!mounted) return;`
  static bool _isMountedGuardWithReturn(Statement statement) {
    if (statement is! IfStatement) return false;
    final condition = statement.expression;

    // Check for `!ref.mounted` or `!mounted`
    if (condition is! PrefixExpression) return false;
    if (condition.operator.lexeme != '!') return false;

    final operand = condition.operand;
    final isMountedCheck =
        // ref.mounted (PrefixedIdentifier)
        (operand is PrefixedIdentifier &&
            operand.prefix.name == 'ref' &&
            operand.identifier.name == 'mounted') ||
        // ref.mounted (PropertyAccess — e.g., this.ref.mounted)
        (operand is PropertyAccess && operand.propertyName.name == 'mounted') ||
        // bare `mounted`
        (operand is SimpleIdentifier && operand.name == 'mounted');

    if (!isMountedCheck) return false;

    // Check that the then branch contains a return
    final thenStatement = statement.thenStatement;
    if (thenStatement is ReturnStatement) return true;
    if (thenStatement is Block) {
      final stmts = thenStatement.statements;
      if (stmts.length == 1 && stmts.first is ReturnStatement) return true;
    }

    return false;
  }

  /// Returns true if the node contains an `await` expression.
  static bool _containsAwait(AstNode node) {
    final finder = _AwaitFinder();
    node.accept(finder);
    return finder.found;
  }
}

/// Finds `await` expressions, stopping at function boundaries.
class _AwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
    // No need to continue
  }

  // Stop at function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

/// Finds `ref` and `state` usages in AST nodes.
///
/// Reports:
/// - `ref.read(...)`, `ref.watch(...)`, `ref.listen(...)`, etc.
/// - `ref.someProperty` (PrefixedIdentifier)
/// - Bare `ref` identifier
/// - `state = ...` assignment
/// - `state.someProperty` access
/// - Bare `state` identifier
class _RefStateFinder extends RecursiveAstVisitor<void> {
  final UseRefAndStateSynchronously rule;

  _RefStateFinder(this.rule);

  static const _targets = {'ref', 'state'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // ref.read(...), ref.watch(...), state.copyWith(...), etc.
    if (node.target case SimpleIdentifier(
      name: final name,
    ) when _targets.contains(name)) {
      rule.reportAtNode(node);
      return; // Don't recurse — already reported
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // ref.mounted check should NOT be flagged (it's the guard itself)
    if (node.prefix.name == 'ref' && node.identifier.name == 'mounted') {
      return;
    }

    // ref.someProperty, state.someProperty
    if (_targets.contains(node.prefix.name)) {
      rule.reportAtNode(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_targets.contains(node.name)) {
      super.visitSimpleIdentifier(node);
      return;
    }

    // Skip when part of a PrefixedIdentifier, PropertyAccess, or
    // MethodInvocation (those visitors handle reporting instead)
    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.prefix == node) return;
    if (parent is PropertyAccess && parent.target == node) return;
    if (parent is MethodInvocation && parent.target == node) return;

    rule.reportAtNode(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // state = newValue
    if (node.leftHandSide case SimpleIdentifier(name: 'state')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // this.ref.something or chained state.something
    if (node.target case SimpleIdentifier(
      name: final name,
    ) when _targets.contains(name)) {
      // Skip ref.mounted
      if (name == 'ref' && node.propertyName.name == 'mounted') return;
      rule.reportAtNode(node);
      return;
    }
    super.visitPropertyAccess(node);
  }

  // Stop at function boundaries — closures may be stored for later invocation
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
