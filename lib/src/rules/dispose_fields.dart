import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../disposal_utils.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class DisposeFields extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (!isStateElement(rule, element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final members = body.members;

    final disposeMethod = members
        .whereType<MethodDeclaration>()
        .where((m) => m.name.lexeme == 'dispose')
        .firstOrNull;

    final cleanupMethods = resolveCleanupMethods(rule);

    final cleanedUpTargets = <String, Set<String>>{};
    if (disposeMethod != null) {
      final collector = _CleanupCallCollector(cleanupMethods);
      disposeMethod.body.visitChildren(collector);
      for (final call in collector.calls) {
        cleanedUpTargets
            .putIfAbsent(call.targetSource, () => {})
            .add(call.methodName);
      }
    }

    for (final fieldDecl in members.whereType<FieldDeclaration>()) {
      if (fieldDecl.isStatic) continue;

      for (final variable in fieldDecl.fields.variables) {
        final type = variable.declaredFragment?.element.type;
        if (type == null) continue;

        final expectedCleanup = findCleanupMethod(
          type,
          methods: cleanupMethods,
        );
        if (expectedCleanup == null) continue;

        final fieldName = variable.name.lexeme;

        final calledMethods = cleanedUpTargets[fieldName];
        if (calledMethods != null && calledMethods.contains(expectedCleanup)) {
          continue;
        }

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

class _CleanupCall {
  final String targetSource;
  final String methodName;

  _CleanupCall({required this.targetSource, required this.methodName});
}

class _CleanupCallCollector extends RecursiveAstVisitor<void> {
  final List<_CleanupCall> calls = [];

  final List<String> methods;

  _CleanupCallCollector(this.methods);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methods.contains(methodName)) {
      final target = node.realTarget;
      if (target != null) {
        calls.add(
          _CleanupCall(targetSource: target.toSource(), methodName: methodName),
        );
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
