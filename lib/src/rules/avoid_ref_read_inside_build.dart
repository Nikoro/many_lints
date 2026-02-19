import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `ref.read()` is called inside a `build()` method of a
/// Riverpod consumer widget or consumer state class.
///
/// `ref.read` reads the provider value once and does not listen for changes.
/// Using it inside `build()` means the widget won't rebuild when the
/// provider's value changes. Use `ref.watch()` instead.
class AvoidRefReadInsideBuild extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_ref_read_inside_build',
    "Avoid using 'ref.read' inside the build method.",
    correctionMessage:
        "Use 'ref.watch' instead so the widget rebuilds when the "
        "provider's value changes.",
  );

  AvoidRefReadInsideBuild()
    : super(
        name: 'avoid_ref_read_inside_build',
        description:
            'Warns when ref.read() is used inside the build method of a '
            'Riverpod consumer widget or state.',
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
  final AvoidRefReadInsideBuild rule;

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

    // Search for ref.read() calls inside the build body (excluding closures)
    final finder = _RefReadFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Recursively searches for `ref.read(...)` calls inside a build body.
///
/// Stops at function boundaries (closures/lambdas) because `ref.read()`
/// inside event handlers like `onPressed: () => ref.read(...)` is intentional.
class _RefReadFinder extends RecursiveAstVisitor<void> {
  final AvoidRefReadInsideBuild rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      if (node.target case SimpleIdentifier(name: 'ref')) {
        rule.reportAtNode(node);
        return; // Don't recurse — already reported
      }
    }
    super.visitMethodInvocation(node);
  }

  // Stop at function boundaries — closures are intentional (e.g., onPressed)
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
