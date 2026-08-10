import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when nested `flatMap` callbacks run deeper than a `Do` block would.
///
/// `Do` is sugar over `flatMap` with identical semantics, including the
/// short-circuit. The difference is shape: nested callbacks indent one level
/// per step and push each step's value into a closure, so by the third the
/// reader is tracking which `)` closes what. A `Do` block is flat regardless of
/// step count, and every extracted value is an ordinary local.
///
/// Only *nesting* is counted, not chaining. `a.flatMap(f).flatMap(g)` is
/// already flat and reads fine; it is `a.flatMap((x) => b.flatMap((y) => ...))`
/// that grows sideways.
///
/// **Bad:**
/// ```dart
/// market.buyBanana().flatMap(
///       (banana) => market.buyApple().flatMap(
///             (apple) => market.buyPear().flatMap(
///                   (pear) => Option.of('$banana, $apple, $pear'),
///                 ),
///           ),
///     );
/// ```
///
/// **Good:**
/// ```dart
/// Option.Do(($) {
///   final banana = $(market.buyBanana());
///   final apple = $(market.buyApple());
///   final pear = $(market.buyPear());
///   return '$banana, $apple, $pear';
/// });
/// ```
///
/// ## Options
///
/// - `max_flatmap_depth`: how deeply `flatMap` callbacks may nest before the
///   outermost is reported. Defaults to `3`.
class PreferDoNotation extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_do_notation',
    "These '{0}' nested 'flatMap' callbacks would read flatter as a 'Do' "
        'block.',
    correctionMessage:
        "Use '<Type>.Do((\$) { ... })' and extract each step with '\$', which "
        'has the same short-circuiting but no nesting.',
  );

  PreferDoNotation()
    : super(
        name: 'prefer_do_notation',
        description:
            'Warns when flatMap callbacks nest deeply enough that Do notation '
            'would read better, with identical semantics.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferDoNotation rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isFpdartFlatMap(node)) return;

    // Only the outermost call reports: the nest is one shape with one fix, and
    // reporting each level would produce a diagnostic per step.
    if (_enclosingFlatMapCallback(node) != null) return;

    final depth = _nestingDepth(node);
    if (depth < rule.config.intOption('max_flatmap_depth', defaultValue: 3)) {
      return;
    }

    rule.reportAtNode(node.methodName, arguments: ['$depth']);
  }

  /// Whether [node] is `flatMap` on an fpdart type.
  bool _isFpdartFlatMap(MethodInvocation node) {
    if (node.methodName.name != 'flatMap') return false;

    final targetType = node.realTarget?.staticType;
    return targetType != null &&
        anyFpdartChecker.isAssignableFromType(targetType);
  }

  /// The `flatMap` whose callback lexically contains [node], if any.
  ///
  /// Walking to the callback rather than to any ancestor call is what
  /// distinguishes nesting from chaining: in `a.flatMap(f).flatMap(g)` the
  /// second call's *target* is the first, not its callback, so neither is
  /// nested in the other.
  MethodInvocation? _enclosingFlatMapCallback(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is! FunctionExpression) continue;

      final parent = current.parent;
      if (parent is! ArgumentList) continue;

      final invocation = parent.parent;
      if (invocation is MethodInvocation && _isFpdartFlatMap(invocation)) {
        return invocation;
      }
    }

    return null;
  }

  /// How many `flatMap` levels are nested inside [node]'s callback chain.
  int _nestingDepth(MethodInvocation node) {
    var depth = 1;

    for (final argument in node.argumentList.arguments) {
      final callback = argument.argumentExpression;
      if (callback is! FunctionExpression) continue;

      final inner = _deepestFlatMapIn(callback.body);
      if (inner != null) depth += _nestingDepth(inner);
    }

    return depth;
  }

  /// The first `flatMap` directly inside [body], skipping nested closures that
  /// belong to something else.
  MethodInvocation? _deepestFlatMapIn(FunctionBody body) {
    final finder = _NestedFlatMapFinder(_isFpdartFlatMap);
    body.accept(finder);
    return finder.found;
  }
}

/// Finds the first `flatMap` in a callback body.
class _NestedFlatMapFinder extends RecursiveAstVisitor<void> {
  final bool Function(MethodInvocation) isFlatMap;
  MethodInvocation? found;

  _NestedFlatMapFinder(this.isFlatMap);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (found != null) return;
    if (isFlatMap(node)) {
      found = node;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
