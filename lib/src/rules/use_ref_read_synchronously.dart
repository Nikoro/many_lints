import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `ref.read()` is called after an `await` point inside an async
/// callback within a ConsumerWidget or ConsumerState build method without
/// checking if the widget is still mounted.
///
/// After an `await`, the widget may have been unmounted, making `ref.read()`
/// return stale or unintended state.
class UseRefReadSynchronously extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_ref_read_synchronously',
    "Avoid calling 'ref.read' after an await point without checking "
        "if the widget is mounted.",
    correctionMessage:
        "Add a 'if (!mounted) return;' or 'if (!context.mounted) return;' "
        "guard before calling 'ref.read' after an await.",
  );

  UseRefReadSynchronously()
    : super(
        name: 'use_ref_read_synchronously',
        description:
            'Warns when ref.read() is called after an await point in a '
            'ConsumerWidget or ConsumerState without a mounted guard.',
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
  final UseRefReadSynchronously rule;

  _Visitor(this.rule);

  static const _consumerWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerWidget', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  static const _consumerStateChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    // Navigate to the enclosing class
    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    // Check if it's a ConsumerWidget, ConsumerState, or Hook variants
    if (!_consumerWidgetChecker.isSuperOf(element) &&
        !_consumerStateChecker.isSuperOf(element)) {
      return;
    }

    // Find async callbacks inside the build method and check for ref.read
    // after await points
    final finder = _AsyncCallbackFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Finds async function expressions (callbacks) inside the build method
/// and checks each for `ref.read()` usage after `await` points.
class _AsyncCallbackFinder extends RecursiveAstVisitor<void> {
  final UseRefReadSynchronously rule;

  _AsyncCallbackFinder(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.body.isAsynchronous) {
      final body = node.body;
      if (body is BlockFunctionBody) {
        _checkStatements(body.block.statements);
      }
      // Don't recurse into this async body — it's been handled
      return;
    }
    // Continue recursing into non-async lambdas
    super.visitFunctionExpression(node);
  }

  /// Checks a list of statements for ref.read() usage after an await point.
  void _checkStatements(NodeList<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      if (!seenAwait) {
        seenAwait = _containsAwait(statement);
        continue;
      }

      // After an await: check for mounted guard that resets context
      if (_isMountedGuardWithReturn(statement)) {
        seenAwait = false;
        continue;
      }

      // Report ref.read() usage after an await without a mounted guard
      final finder = _RefReadFinder(rule);
      statement.accept(finder);
    }
  }

  /// Returns true if the statement is a mounted guard pattern:
  /// `if (!mounted) return;` or `if (!context.mounted) return;`
  static bool _isMountedGuardWithReturn(Statement statement) {
    if (statement is! IfStatement) return false;
    final condition = statement.expression;

    // Check for `!mounted` or `!context.mounted`
    if (condition is! PrefixExpression) return false;
    if (condition.operator.lexeme != '!') return false;

    final operand = condition.operand;
    final isMountedCheck =
        // context.mounted (PrefixedIdentifier)
        (operand is PrefixedIdentifier &&
            operand.identifier.name == 'mounted') ||
        // context.mounted (PropertyAccess — e.g., this.context.mounted)
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
  }

  // Stop at function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

/// Finds `ref.read(...)` calls in AST nodes.
class _RefReadFinder extends RecursiveAstVisitor<void> {
  final UseRefReadSynchronously rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      if (_isRefTarget(node.target)) {
        rule.reportAtNode(node);
        return; // Don't recurse — already reported
      }
    }
    super.visitMethodInvocation(node);
  }

  /// Checks if the target is `ref` or `ref!`.
  static bool _isRefTarget(Expression? target) {
    if (target case SimpleIdentifier(name: 'ref')) {
      return true;
    }
    // Handle ref! (PostfixExpression with ! operator)
    if (target case PostfixExpression(operand: SimpleIdentifier(name: 'ref'))) {
      return true;
    }
    return false;
  }

  // Stop at function boundaries — nested closures may be stored for later
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
