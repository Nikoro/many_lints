import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class ProperSuperCalls extends ManyLintsRule {
  static const LintCode code = LintCode(
    'proper_super_calls',
    "'{0}' should call 'super.{0}()' {1}.",
    correctionMessage: "Move 'super.{0}()' to be the {1} statement.",
  );

  ProperSuperCalls()
    : super(
        name: 'proper_super_calls',
        description:
            'Warns when super lifecycle methods are called in the wrong '
            'order in State subclasses.',
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
  final ProperSuperCalls rule;

  _Visitor(this.rule);

  static const _superFirstMethods = {
    'initState',
    'didUpdateWidget',
    'activate',
    'didChangeDependencies',
    'reassemble',
  };

  static const _superLastMethods = {'deactivate', 'dispose'};

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final methodName = node.name.lexeme;

    final bool shouldBeFirst;
    if (_superFirstMethods.contains(methodName)) {
      shouldBeFirst = true;
    } else if (_superLastMethods.contains(methodName)) {
      shouldBeFirst = false;
    } else {
      return;
    }

    final classBody = node.parent;
    if (classBody is! BlockClassBody) return;
    final classDecl = classBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !isStateElement(rule, element)) return;

    final body = node.body;
    if (body is! BlockFunctionBody) return;

    final statements = body.block.statements;
    if (statements.isEmpty) return;

    final superCallIndex = _findSuperCallIndex(statements, methodName);
    if (superCallIndex == -1) return;

    if (shouldBeFirst && superCallIndex != 0) {
      rule.reportAtNode(
        _reportedSuperCallNode(statements[superCallIndex]),
        arguments: [methodName, 'first'],
      );
    } else if (!shouldBeFirst && superCallIndex != statements.length - 1) {
      rule.reportAtNode(
        _reportedSuperCallNode(statements[superCallIndex]),
        arguments: [methodName, 'last'],
      );
    }
  }

  static int _findSuperCallIndex(
    NodeList<Statement> statements,
    String methodName,
  ) {
    for (var i = 0; i < statements.length; i++) {
      if (_isSuperCall(statements[i], methodName)) return i;
    }
    return -1;
  }

  static bool _isSuperCall(Statement statement, String methodName) {
    if (statement is! ExpressionStatement) return false;
    final expr = statement.expression;
    if (expr is! MethodInvocation) return false;
    return expr.target is SuperExpression && expr.methodName.name == methodName;
  }

  static AstNode _reportedSuperCallNode(Statement statement) {
    if (statement is ExpressionStatement) {
      return statement.expression;
    }
    return statement;
  }
}
