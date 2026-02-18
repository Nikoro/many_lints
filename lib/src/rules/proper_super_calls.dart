import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `super` lifecycle methods are called in the wrong order
/// inside a `State` subclass.
///
/// **Early-execution methods** (`initState`, `didUpdateWidget`, `activate`,
/// `didChangeDependencies`, `reassemble`) must call `super` first.
///
/// **Late-execution methods** (`deactivate`, `dispose`) must call `super` last.
///
/// Calling `super` at the wrong position can lead to bugs where properties
/// are not yet initialized or have already been disposed.
class ProperSuperCalls extends AnalysisRule {
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
  void registerNodeProcessors(
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

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  /// Methods where super must be called first.
  static const _superFirstMethods = {
    'initState',
    'didUpdateWidget',
    'activate',
    'didChangeDependencies',
    'reassemble',
  };

  /// Methods where super must be called last.
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

    // Verify we're inside a State subclass
    final enclosingClass = node.parent;
    if (enclosingClass is! BlockClassBody) return;
    final classDecl = enclosingClass.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

    // Must have a block body
    final body = node.body;
    if (body is! BlockFunctionBody) return;

    final statements = body.block.statements;
    if (statements.isEmpty) return;

    // Find the super call
    final superCallIndex = _findSuperCallIndex(statements, methodName);
    if (superCallIndex == -1) return; // No super call found — not our concern

    if (shouldBeFirst && superCallIndex != 0) {
      rule.reportAtNode(
        _extractSuperStatement(statements[superCallIndex]),
        arguments: [methodName, 'first'],
      );
    } else if (!shouldBeFirst && superCallIndex != statements.length - 1) {
      rule.reportAtNode(
        _extractSuperStatement(statements[superCallIndex]),
        arguments: [methodName, 'last'],
      );
    }
  }

  /// Returns the index of the statement containing `super.<methodName>()`,
  /// or -1 if not found.
  static int _findSuperCallIndex(
    NodeList<Statement> statements,
    String methodName,
  ) {
    for (var i = 0; i < statements.length; i++) {
      if (_isSuperCall(statements[i], methodName)) return i;
    }
    return -1;
  }

  /// Checks if a statement is `super.<methodName>(...);`
  static bool _isSuperCall(Statement statement, String methodName) {
    if (statement is! ExpressionStatement) return false;
    final expr = statement.expression;
    if (expr is! MethodInvocation) return false;
    return expr.target is SuperExpression && expr.methodName.name == methodName;
  }

  /// Returns the node to report — the MethodInvocation inside the statement.
  static AstNode _extractSuperStatement(Statement statement) {
    if (statement is ExpressionStatement) {
      return statement.expression;
    }
    return statement;
  }
}
