import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../async_guard_utils.dart';
import '../type_checker.dart';

/// Warns when a bloc emits state after an `await` without checking
/// `isClosed`.
///
/// A bloc can be closed while an asynchronous handler is suspended — the
/// user navigates away, the provider disposes. Emitting into a closed bloc
/// throws a `StateError`, and because the throw happens inside a detached
/// future it usually surfaces as an unhandled error rather than a crash at
/// the call site.
///
/// Guard the emit with `if (isClosed) return;` after each await.
class CheckIsNotClosedAfterAsyncGap extends AnalysisRule {
  static const LintCode code = LintCode(
    'check_is_not_closed_after_async_gap',
    "State is emitted after an await without checking 'isClosed'.",
    correctionMessage:
        "Add 'if (isClosed) return;' after the await, since the bloc may "
        'have been closed while this handler was suspended.',
  );

  CheckIsNotClosedAfterAsyncGap()
    : super(
        name: 'check_is_not_closed_after_async_gap',
        description:
            'Warns when a bloc emits state after an async gap without '
            'checking isClosed first.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final CheckIsNotClosedAfterAsyncGap rule;

  _Visitor(this.rule);

  static const _blocBaseChecker = TypeChecker.any([
    TypeChecker.fromName('Bloc', packageName: 'bloc'),
    TypeChecker.fromName('Cubit', packageName: 'bloc'),
  ]);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_blocBaseChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration) {
        _checkFunctionBody(member.body);
      } else if (member is ConstructorDeclaration) {
        // Handlers registered via `on<E>((event, emit) async { ... })`.
        member.body.visitChildren(_HandlerFinder(this));
      }
    }
  }

  /// Scans [body]'s statements in order, tracking whether an await has been
  /// seen without an intervening `isClosed` guard.
  void _checkFunctionBody(FunctionBody body) {
    if (body is! BlockFunctionBody) return;
    if (!body.isAsynchronous) return;

    _scanStatements(body.block.statements);
  }

  void _scanStatements(List<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      // An early-return guard resets the tracking: past this point the
      // bloc is known to be open.
      if (seenAwait && isClosedGuardWithReturn(statement)) {
        seenAwait = false;
        continue;
      }

      // `if (!isClosed) { ... }` guards its own body instead. Skip the
      // statement entirely, but keep the flag set for whatever follows it.
      if (seenAwait && isNegatedClosedGuard(statement)) {
        continue;
      }

      if (seenAwait) {
        statement.visitChildren(_EmitFinder(rule));
      }

      if (containsAwait(statement)) {
        seenAwait = true;
      }
    }
  }
}

/// Finds `on<E>(...)` handler callbacks so their bodies can be scanned.
class _HandlerFinder extends RecursiveAstVisitor<void> {
  final _Visitor visitor;

  _HandlerFinder(this.visitor);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    if (node.methodName.name != 'on') return;

    final target = node.target;
    if (target != null && target is! ThisExpression) return;

    for (final argument in node.argumentList.arguments) {
      final expression = argument is NamedArgument
          ? argument.argumentExpression
          : argument;
      if (expression is FunctionExpression) {
        visitor._checkFunctionBody(expression.body);
      }
    }
  }
}

/// Finds `emit(...)` calls, which are the operations that throw on a closed
/// bloc.
///
/// Stops at function boundaries: a nested closure runs on its own schedule
/// and its guards cannot be reasoned about from here.
class _EmitFinder extends RecursiveAstVisitor<void> {
  final CheckIsNotClosedAfterAsyncGap rule;

  _EmitFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Cubit form: `emit(...)` resolves to the inherited method.
    if (node.methodName.name == 'emit') {
      final target = node.target;
      if (target == null || target is ThisExpression) {
        rule.reportAtNode(node);
        return;
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // Bloc form: `emit` is the handler's Emitter parameter, so calling it
    // parses as an invocation of a function-typed expression.
    if (node.function case SimpleIdentifier(name: 'emit')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
