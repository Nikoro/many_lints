import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
// ignore_for_file: implementation_imports
import 'package:analyzer/src/util/glob.dart';

import '../many_lints_rule.dart';

class AvoidExitOutsideEntrypoint extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_exit_outside_entrypoint',
    "Calling 'exit' here terminates the process, including a test running "
        'this code.',
    correctionMessage:
        'Throw a typed error instead and let the entrypoint map it to an '
        'exit code.',
  );

  AvoidExitOutsideEntrypoint()
    : super(
        name: 'avoid_exit_outside_entrypoint',
        description: 'Warns when `exit()` is called outside the entrypoint.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _defaultAllowIn = {'bin/**'};

  final AvoidExitOutsideEntrypoint rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.realTarget != null) return;
    _check(node.methodName);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Edge case: a tear-off such as onFailure(exit) exits too, just one call later
    if (node.parent is MethodInvocation) return;
    if (node.inDeclarationContext()) return;
    _check(node);
  }

  void _check(SimpleIdentifier identifier) {
    if (identifier.name != 'exit') return;

    final element = identifier.element;
    if (element is! TopLevelFunctionElement) return;
    if (element.library.uri.toString() != 'dart:io') return;

    if (_isInEntrypoint()) return;

    rule.reportAtNode(identifier);
  }

  bool _isInEntrypoint() {
    final path = rule.relativePath;
    // Edge case: a file outside the package root cannot be matched against allow_in
    if (path == null) return true;

    final allowIn = rule.config.nameSetOption(
      'allow_in',
      defaultValue: _defaultAllowIn,
    );

    return allowIn.any((pattern) => Glob('/', pattern).matches(path));
  }
}
