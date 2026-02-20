import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../hook_detection.dart';
import '../type_checker.dart';

/// Warns when hooks are called inside conditional branches.
///
/// Hooks rely on call order to maintain state correctly. Calling hooks
/// conditionally can cause hooks to be called in a different order between
/// builds, leading to unexpected behavior.
class AvoidConditionalHooks extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_conditional_hooks',
    'Hooks should not be called conditionally.',
    correctionMessage:
        'Move the conditional logic inside the hook callback instead.',
  );

  AvoidConditionalHooks()
    : super(
        name: 'avoid_conditional_hooks',
        description: 'Warns when hooks are called inside conditional branches.',
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
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidConditionalHooks rule;

  _Visitor(this.rule);

  static const _hookWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final superclassElement = superclass?.element;
    if (superclass == null || superclassElement == null) return;

    if (!_hookWidgetChecker.isExactly(superclassElement)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((member) => member.name.lexeme == 'build');
    if (buildMethod == null) return;

    _checkBody(buildMethod.body);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body == null) return;

    _checkBody(body);
  }

  void _checkBody(AstNode body) {
    final finder = _ConditionalHookFinder(rule);
    body.accept(finder);
  }
}

/// Recursively visits a build body to find hook calls inside conditional
/// branches. Tracks whether the current position is "conditional" via a depth
/// counter that increments when entering if/else/switch/ternary branches.
class _ConditionalHookFinder extends RecursiveAstVisitor<void> {
  final AvoidConditionalHooks rule;
  int _conditionalDepth = 0;

  _ConditionalHookFinder(this.rule);

  static final _isHookRegex = hookNameRegex;

  void _checkHookCall(AstNode node) {
    if (_conditionalDepth > 0 &&
        _isHookRegex.hasMatch(node.beginToken.lexeme)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkHookCall(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkHookCall(node);
    super.visitFunctionExpressionInvocation(node);
  }

  // Stop at HookBuilder boundaries (they create a new hook context)
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body != null) {
      // This is a HookBuilder — don't recurse into its builder body
      return;
    }
    _checkHookCall(node);
    super.visitInstanceCreationExpression(node);
  }

  // --- Conditional branches ---

  @override
  void visitIfStatement(IfStatement node) {
    // The condition itself is NOT conditional — hooks in condition would be fine
    // (though unusual). The then and else branches are conditional.
    node.expression.accept(this);

    _conditionalDepth++;
    node.thenStatement.accept(this);
    node.elseStatement?.accept(this);
    _conditionalDepth--;
  }

  @override
  void visitIfElement(IfElement node) {
    node.expression.accept(this);

    _conditionalDepth++;
    node.thenElement.accept(this);
    node.elseElement?.accept(this);
    _conditionalDepth--;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);

    _conditionalDepth++;
    for (final member in node.members) {
      member.accept(this);
    }
    _conditionalDepth--;
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    node.expression.accept(this);

    _conditionalDepth++;
    for (final caseNode in node.cases) {
      caseNode.accept(this);
    }
    _conditionalDepth--;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    // condition is not conditional, but then/else are
    node.condition.accept(this);

    _conditionalDepth++;
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
    _conditionalDepth--;
  }

  // Short-circuit operators: `condition && useHook()` — the right operand
  // is conditionally executed
  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.lexeme;
    if (op == '&&' || op == '||') {
      node.leftOperand.accept(this);
      _conditionalDepth++;
      node.rightOperand.accept(this);
      _conditionalDepth--;
    } else {
      super.visitBinaryExpression(node);
    }
  }

  // Stop at nested function boundaries — closures define their own scope
  // but we still want to check them if they're immediately invoked.
  // However, hooks inside passed callbacks are a different concern.
  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't recurse into nested closures/functions — they are a different
    // invocation context and hooks inside them are their own concern.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Don't recurse into nested function declarations.
  }
}
