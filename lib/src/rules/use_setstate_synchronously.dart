import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../async_guard_utils.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';

/// Warns when `setState` is called after an `await` without a `mounted` guard.
///
/// This is a real crash, not a style preference. Between the `await` and the
/// line after it the widget can be disposed — the user navigated back, a
/// parent rebuilt without this child, a list item scrolled out of a
/// `ListView`. Calling `setState` on a disposed `State` throws
/// "setState() called after dispose()", and it does so only under the timing
/// that makes it hard to reproduce and easy to ship.
///
/// The guard the framework expects is `if (!mounted) return;` between the
/// `await` and the `setState`.
///
/// This is the `State` counterpart to `use_ref_read_synchronously`, and it
/// shares that rule's async-gap machinery. It applies inside any `State`
/// subclass, including additional bases named through `state_base_classes`.
class UseSetstateSynchronously extends ManyLintsRule {
  static const LintCode code = LintCode(
    'use_setstate_synchronously',
    "'setState' is called after an await without a 'mounted' guard.",
    correctionMessage:
        "Add 'if (!mounted) return;' after the await, so a disposed widget "
        'does not rebuild.',
  );

  UseSetstateSynchronously()
    : super(
        name: 'use_setstate_synchronously',
        description:
            'Warns when setState is called after an await point without a '
            'mounted guard.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseSetstateSynchronously rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (!isStateElement(rule, element)) return;

    node.body.accept(_SetStateAfterAwaitFinder(rule));
  }
}

/// Walks every block in a `State`, reporting a `setState` that follows an
/// `await` with no `mounted` guard in between.
class _SetStateAfterAwaitFinder extends RecursiveAstVisitor<void> {
  _SetStateAfterAwaitFinder(this.rule);

  final UseSetstateSynchronously rule;

  @override
  void visitBlock(Block node) {
    // Statements are scanned in order, so the analysis is "has an await
    // happened above this line, and has nothing re-established mounted since".
    var afterAwait = false;

    for (final statement in node.statements) {
      if (afterAwait && isMountedGuardWithReturn(statement)) {
        afterAwait = false;
        continue;
      }

      if (afterAwait) _reportSetStateIn(statement);

      // Checked after reporting: an `await` on the same line as the setState
      // (`setState(...); await x;`) does not put the setState after a gap.
      if (containsAwait(statement)) afterAwait = true;
    }

    super.visitBlock(node);
  }

  /// Reports a `setState` call anywhere in [statement], excluding one written
  /// inside a nested closure — that closure runs on its own timeline, and its
  /// body is visited as its own block.
  void _reportSetStateIn(Statement statement) {
    final finder = _SetStateFinder();
    statement.accept(finder);

    for (final invocation in finder.invocations) {
      rule.reportAtNode(invocation.methodName);
    }
  }
}

/// Collects unqualified `setState(...)` calls, not descending into closures.
class _SetStateFinder extends RecursiveAstVisitor<void> {
  final invocations = <MethodInvocation>[];

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // `target == null` keeps this to the enclosing State's own setState: an
    // `other.setState(...)` is not this widget's lifecycle to guard.
    if (node.methodName.name == 'setState' && node.target == null) {
      invocations.add(node);
    }

    super.visitMethodInvocation(node);
  }
}
