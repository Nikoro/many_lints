import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when a `State` class contains method overrides that only call the
/// super implementation without any additional logic.
class AvoidUnnecessaryOverridesInState extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_overrides_in_state',
    'This method override only calls super.{0}() without additional logic.',
    correctionMessage: 'Remove this unnecessary override.',
  );

  AvoidUnnecessaryOverridesInState()
    : super(
        name: 'avoid_unnecessary_overrides_in_state',
        description:
            'Warns when a State class contains method overrides that only '
            'call super without additional logic.',
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
  final AvoidUnnecessaryOverridesInState rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (!_stateChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (!hasOverrideAnnotation(member)) continue;

      final methodName = member.name.lexeme;

      if (_isOnlySuperCall(member, methodName)) {
        rule.reportAtNode(member, arguments: [methodName]);
      }
    }
  }

  /// Checks if the method body only contains a call to super.methodName().
  static bool _isOnlySuperCall(MethodDeclaration method, String methodName) {
    final body = method.body;

    // Expression body: => super.methodName();
    if (body is ExpressionFunctionBody) {
      return _isSuperMethodCall(body.expression, methodName);
    }

    // Block body: { super.methodName(); }
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length != 1) return false;

      final statement = statements.first;
      if (statement is! ExpressionStatement) return false;

      return _isSuperMethodCall(statement.expression, methodName);
    }

    return false;
  }

  static bool _isSuperMethodCall(Expression expression, String methodName) {
    if (expression is! MethodInvocation) return false;

    return expression.target is SuperExpression &&
        expression.methodName.name == methodName &&
        expression.argumentList.arguments.isEmpty;
  }
}
