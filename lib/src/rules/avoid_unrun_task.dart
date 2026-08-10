import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when a lazy fpdart value is discarded without being run.
///
/// `Task`, `TaskEither`, `IO`, `IOEither`, `TaskOption` and `IOOption` are
/// *descriptions* of work, not the work itself: nothing happens until `.run()`
/// is called. Dropping one on the floor therefore skips the operation
/// entirely — no request is sent, no file is written, no exception is thrown.
/// Nothing about the program looks wrong, which is what makes this worse than
/// a discarded `Future`: a `Future` at least ran.
///
/// This is the fpdart counterpart to `unawaited_futures`, and the one mistake
/// in this family the type system cannot catch on its own.
///
/// **Bad:**
/// ```dart
/// void save(User user) {
///   repository.save(user); // returns TaskEither — never runs
/// }
/// ```
///
/// **Good:**
/// ```dart
/// Future<void> save(User user) async {
///   await repository.save(user).run();
/// }
/// ```
///
/// ## Options
///
/// - `additional_types`: extra type names to treat as lazy, for projects that
///   wrap fpdart's types in their own. Defaults to none.
/// - `ignore_cascades`: when `true`, a lazy value discarded as the target of a
///   cascade is not reported. Defaults to `false`.
class AvoidUnrunTask extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unrun_task',
    "This '{0}' is discarded without being run, so its work never happens.",
    correctionMessage:
        "Call '.run()' on it and await the result, or return it so the caller "
        'can run it.',
  );

  AvoidUnrunTask()
    : super(
        name: 'avoid_unrun_task',
        description:
            'Warns when a lazy fpdart value (Task, TaskEither, IO, ...) is '
            'discarded without calling run(), so the work it describes never '
            'executes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addExpressionStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnrunTask rule;

  _Visitor(this.rule);

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;

    // An assignment consumes the value: `final t = buildTask();` hands it to
    // something that may still run it. Only a bare expression discards it.
    if (expression is AssignmentExpression) return;

    if (rule.config.boolOption('ignore_cascades', defaultValue: false) &&
        expression is CascadeExpression) {
      return;
    }

    final type = expression.staticType;
    if (type == null) return;

    final name = _lazyTypeName(type);
    if (name == null) return;

    rule.reportAtNode(expression, arguments: [name]);
  }

  /// The display name of [type] when it is a lazy fpdart type, else null.
  String? _lazyTypeName(DartType type) {
    if (lazyFpdartChecker.isAssignableFromType(type)) {
      return type is InterfaceType ? type.element.name : 'lazy value';
    }

    // A project may wrap fpdart's types in its own; those wrappers are just as
    // lazy and just as silent when dropped, but cannot be pinned to a package.
    for (final extra in rule.config.stringListOption('additional_types')) {
      if (TypeChecker.fromName(extra).isAssignableFromType(type)) return extra;
    }

    return null;
  }
}
