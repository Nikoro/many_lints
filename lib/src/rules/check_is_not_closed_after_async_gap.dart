import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../async_guard_utils.dart';
import '../bloc_type_checkers.dart';
import '../many_lints_rule.dart';

class CheckIsNotClosedAfterAsyncGap extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !blocOrCubitChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration) {
        _checkFunctionBody(member.body);
      } else if (member is ConstructorDeclaration) {
        member.body.visitChildren(_HandlerFinder(this));
      }
    }
  }

  void _checkFunctionBody(FunctionBody body) {
    if (body is! BlockFunctionBody) return;
    if (!body.isAsynchronous) return;

    _scanStatements(body.block.statements);
  }

  void _scanStatements(List<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      if (seenAwait && isClosedGuardWithReturn(statement)) {
        seenAwait = false;
        continue;
      }

      // Edge case: `if (!isClosed)` guards only its own body, so the gap stays open after it
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

class _EmitFinder extends RecursiveAstVisitor<void> {
  final CheckIsNotClosedAfterAsyncGap rule;

  _EmitFinder(this.rule);

  bool _emitsState(String name) =>
      name == 'emit' ||
      rule.config.stringListOption('additional_methods').contains(name);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_emitsState(node.methodName.name)) {
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
    // Edge case: a Bloc handler's Emitter is a callable parameter, so `emit(...)` parses here
    if (node.function case SimpleIdentifier(
      name: final name,
    ) when _emitsState(name)) {
      rule.reportAtNode(node);
      return;
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
