import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../disposal_utils.dart';
import '../type_checker.dart';

/// Warns when a widget State field that has a disposal method (`dispose`,
/// `close`, or `cancel`) is not cleaned up in the `dispose()` method.
///
/// Disposable resources such as `AnimationController`, `TextEditingController`,
/// `StreamController`, `StreamSubscription`, `FocusNode`, `Timer`, etc. must
/// be properly disposed/closed/cancelled in `dispose()` to prevent memory
/// leaks.
class DisposeFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'dispose_fields',
    "Field '{0}' is not disposed. Call '{0}.{1}()' in dispose().",
    correctionMessage:
        "Add '{0}.{1}()' in the dispose() method to prevent memory leaks.",
  );

  DisposeFields()
    : super(
        name: 'dispose_fields',
        description:
            'Warns when a State field with a disposal method is not '
            'cleaned up in dispose().',
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
  final DisposeFields rule;

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

    final members = body.members;

    // Collect all cleanup calls made in dispose()
    final disposeMethod = members
        .whereType<MethodDeclaration>()
        .where((m) => m.name.lexeme == 'dispose')
        .firstOrNull;

    final cleanedUpTargets = <String, Set<String>>{};
    if (disposeMethod != null) {
      final collector = _CleanupCallCollector();
      disposeMethod.body.visitChildren(collector);
      for (final call in collector.calls) {
        cleanedUpTargets
            .putIfAbsent(call.targetSource, () => {})
            .add(call.methodName);
      }
    }

    // Check each field declaration
    for (final fieldDecl in members.whereType<FieldDeclaration>()) {
      if (fieldDecl.isStatic) continue;

      for (final variable in fieldDecl.fields.variables) {
        final type = variable.declaredFragment?.element.type;
        if (type == null) continue;

        final expectedCleanup = findCleanupMethod(type);
        if (expectedCleanup == null) continue;

        final fieldName = variable.name.lexeme;

        // Check if the field is cleaned up in dispose()
        final calledMethods = cleanedUpTargets[fieldName];
        if (calledMethods != null && calledMethods.contains(expectedCleanup)) {
          continue;
        }

        // Also check with `this.` prefix
        final thisCalledMethods = cleanedUpTargets['this.$fieldName'];
        if (thisCalledMethods != null &&
            thisCalledMethods.contains(expectedCleanup)) {
          continue;
        }

        rule.reportAtToken(
          variable.name,
          arguments: [fieldName, expectedCleanup],
        );
      }
    }
  }
}

/// Represents a cleanup call like `fieldName.dispose()`.
class _CleanupCall {
  final String targetSource;
  final String methodName;

  _CleanupCall({required this.targetSource, required this.methodName});
}

/// Collects all dispose/close/cancel calls within a method body.
class _CleanupCallCollector extends RecursiveAstVisitor<void> {
  final List<_CleanupCall> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (cleanupMethods.contains(methodName)) {
      final target = node.realTarget;
      if (target != null) {
        calls.add(
          _CleanupCall(targetSource: target.toSource(), methodName: methodName),
        );
      }
    }
    super.visitMethodInvocation(node);
  }

  // Stop at function boundaries to avoid false positives from nested closures
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
