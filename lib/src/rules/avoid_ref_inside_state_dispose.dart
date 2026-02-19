import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `ref` is accessed inside the `dispose()` method of a
/// `ConsumerState` (or similar Riverpod state) class.
///
/// At disposal time, providers may already be disposed and accessing them can
/// lead to unexpected errors or inconsistent behaviour.
class AvoidRefInsideStateDispose extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_ref_inside_state_dispose',
    "Avoid accessing 'ref' inside the dispose() method.",
    correctionMessage:
        'Providers may already be disposed at this point. '
        'Remove the ref access or move it to an earlier lifecycle method.',
  );

  AvoidRefInsideStateDispose()
    : super(
        name: 'avoid_ref_inside_state_dispose',
        description:
            'Warns when ref is accessed inside the dispose() method '
            'of a ConsumerState class.',
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
  final AvoidRefInsideStateDispose rule;

  _Visitor(this.rule);

  static const _consumerStateChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'dispose') return;

    // Navigate to the enclosing class
    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_consumerStateChecker.isSuperOf(element)) return;

    // Search for any `ref` usage inside dispose body
    final finder = _RefUsageFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Recursively searches for `ref` usages inside a dispose body.
///
/// Detects:
/// - `ref.read(...)`, `ref.watch(...)`, `ref.listen(...)`, etc.
/// - Bare `ref` identifier
/// - `ref` as a property access target
///
/// Stops at nested function boundaries to avoid false positives from closures
/// that may be invoked outside of dispose.
class _RefUsageFinder extends RecursiveAstVisitor<void> {
  final AvoidRefInsideStateDispose rule;

  _RefUsageFinder(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'ref') {
      super.visitSimpleIdentifier(node);
      return;
    }

    // Skip when `ref` is part of a PrefixedIdentifier or PropertyAccess
    // (those visitors handle reporting instead)
    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.prefix == node) return;
    if (parent is PropertyAccess && parent.target == node) return;
    if (parent is MethodInvocation && parent.target == node) return;

    rule.reportAtNode(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // ref.read(...), ref.watch(...), ref.listen(...)
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return; // Don't recurse into children — already reported
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // ref.someProperty
    if (node.prefix.name == 'ref') {
      rule.reportAtNode(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // this.ref or other chained property access
    if (node.target case SimpleIdentifier(name: 'ref')) {
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
