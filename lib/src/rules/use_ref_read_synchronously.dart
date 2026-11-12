import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../async_guard_utils.dart';
import '../riverpod_type_checkers.dart';

class UseRefReadSynchronously extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    if (!consumerWidgetChecker.isSuperOf(element) &&
        !consumerStateChecker.isSuperOf(element)) {
      return;
    }

    final finder = _AsyncCallbackFinder(rule);
    node.body.visitChildren(finder);
  }
}

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
      return;
    }
    super.visitFunctionExpression(node);
  }

  void _checkStatements(NodeList<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      if (!seenAwait) {
        seenAwait = containsAwait(statement);
        continue;
      }

      if (isMountedGuardWithReturn(statement)) {
        seenAwait = false;
        continue;
      }

      final finder = _RefReadFinder(rule);
      statement.accept(finder);
    }
  }
}

class _RefReadFinder extends RecursiveAstVisitor<void> {
  final UseRefReadSynchronously rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      if (_isRefTarget(node.target)) {
        rule.reportAtNode(node);
        return;
      }
    }
    super.visitMethodInvocation(node);
  }

  static bool _isRefTarget(Expression? target) {
    if (target case SimpleIdentifier(name: 'ref')) {
      return true;
    }
    if (target case PostfixExpression(operand: SimpleIdentifier(name: 'ref'))) {
      return true;
    }
    return false;
  }

  // Edge case: a nested closure may be stored and run later, after its own mounted check
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
