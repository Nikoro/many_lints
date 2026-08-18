import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
// ignore_for_file: implementation_imports
import 'package:analyzer/src/util/glob.dart';

import '../many_lints_rule.dart';

/// Warns when `exit()` is called outside the program's entrypoint.
///
/// `exit()` in domain code destroys testability outright: the test process
/// disappears mid-assertion. There is nothing to catch, nothing to assert on,
/// and the failure mode is a runner that reports *nothing* rather than a red
/// test — which reads as a passing suite in CI far more often than it should.
///
/// The split that fixes it is small: domain code throws a typed error, and one
/// thin entrypoint maps errors onto exit codes. That is also what makes the
/// error taxonomy testable — you assert on the thrown type, and the mapping
/// lives in one place you can read.
///
/// By default `bin/**` is allowed, since that is where a Dart entrypoint
/// lives. `allow_in` replaces that list for projects that put the entrypoint
/// elsewhere.
///
/// **BAD:**
/// ```dart
/// // lib/src/core/upload.dart
/// if (response.statusCode == 403) {
///   stderr.writeln('Permission denied');
///   exit(3);                                        // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // lib/src/core/upload.dart
/// if (response.statusCode == 403) {
///   throw const AuthFailure('Permission denied');   // caller picks the code
/// }
/// ```
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
    // A tear-off — `onFailure(exit)` — reaches the same place, one call later.
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// The default entrypoint location, matching the Dart package layout.
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
    // Only the tear-off shape is handled here; the invocation callback above
    // already covers `exit(1)`, whose `methodName` is also a
    // SimpleIdentifier but whose parent is the invocation.
    if (node.parent is MethodInvocation) return;
    if (node.inDeclarationContext()) return;
    _check(node);
  }

  void _check(SimpleIdentifier identifier) {
    if (identifier.name != 'exit') return;

    // Resolving guards against a same-named method of the project's own: this
    // must be `dart:io`'s top-level function, not `Process.exit` or a
    // `Terminal.exit()` someone wrote.
    final element = identifier.element;
    if (element is! TopLevelFunctionElement) return;
    if (element.library.uri.toString() != 'dart:io') return;

    if (_isInEntrypoint()) return;

    rule.reportAtNode(identifier);
  }

  /// Whether the file being analyzed is an allowed entrypoint.
  bool _isInEntrypoint() {
    final path = rule.relativePath;
    // A file outside the package root cannot be classified, so err toward
    // silence: reporting on a path we cannot check against `allow_in` would
    // flag the entrypoint itself.
    if (path == null) return true;

    final allowIn = rule.config.nameSetOption(
      'allow_in',
      defaultValue: _defaultAllowIn,
    );

    return allowIn.any((pattern) => Glob('/', pattern).matches(path));
  }
}
