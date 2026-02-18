import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `mounted` is checked inside a `setState` callback.
///
/// Checking `mounted` inside `setState` is too late — if the widget has been
/// disposed, `setState` itself will throw before the callback runs. The
/// `mounted` check should be placed *before* calling `setState`.
class AvoidMountedInSetstate extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_mounted_in_setstate',
    'Checking mounted inside setState is too late and can lead to an exception.',
    correctionMessage: 'Check mounted before calling setState instead.',
  );

  AvoidMountedInSetstate()
    : super(
        name: 'avoid_mounted_in_setstate',
        description:
            'Warns when mounted is checked inside a setState callback.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMountedInSetstate rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName(
    'State',
    packageName: 'flutter',
  );

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;

    // Verify we're inside a State subclass
    if (!_isInsideState(node)) return;

    // Get the callback argument
    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    final FunctionBody? body;

    if (callback is FunctionExpression) {
      body = callback.body;
    } else {
      // Not an inline callback (e.g. a method reference) — nothing to check
      return;
    }

    // Search for mounted references inside the callback
    final finder = _MountedFinder(rule);
    body.visitChildren(finder);
  }

  bool _isInsideState(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final element = current.declaredFragment?.element;
        if (element != null && _stateChecker.isSuperOf(element)) {
          return true;
        }
        return false;
      }
      current = current.parent;
    }
    return false;
  }
}

/// Recursively searches for `mounted` or `context.mounted` references.
class _MountedFinder extends RecursiveAstVisitor<void> {
  final AvoidMountedInSetstate rule;

  _MountedFinder(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Bare `mounted` (inherited from State)
    if (node.name == 'mounted') {
      // Exclude `context.mounted` which is handled by visitPrefixedIdentifier
      // and property access which is handled by visitPropertyAccess
      final parent = node.parent;
      if (parent is PrefixedIdentifier && parent.identifier == node) return;
      if (parent is PropertyAccess && parent.propertyName == node) return;

      rule.reportAtNode(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // `context.mounted`
    if (node.identifier.name == 'mounted') {
      rule.reportAtNode(node);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // `this.mounted` or complex expressions like `widget.context.mounted`
    if (node.propertyName.name == 'mounted') {
      rule.reportAtNode(node);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Continue into nested closures — mounted check is still inside setState
    super.visitFunctionExpression(node);
  }
}
