import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';

/// One extracted step of a would-be `Do` block.
typedef _Step = ({String name, String source});

/// Converts a chain of nested `flatMap` callbacks into a `Do` block.
///
/// **Example**:
///
/// ```dart
/// goToShoppingCenter().flatMap(
///   (market) => market.buyBanana().flatMap(
///         (banana) => market.buyApple().flatMap(
///               (apple) => Option.of('$banana, $apple'),
///             ),
///       ),
/// );
/// ```
///
/// With the cursor on any `flatMap` in that nest, the assist produces:
///
/// ```dart
/// Option.Do(($) {
///   final market = $(goToShoppingCenter());
///   final banana = $(market.buyBanana());
///   final apple = $(market.buyApple());
///   return '$banana, $apple';
/// });
/// ```
///
/// ## Why an assist rather than a quick fix
///
/// The generated names come from the callbacks' own parameters, which are
/// usually good but occasionally single letters. Every one is emitted as a
/// linked edit position, so accepting the assist drops the cursor on the first
/// name with the rest reachable by Tab — the rename is part of applying it,
/// not a follow-up chore.
///
/// That interaction only exists because the user invoked this deliberately. As
/// a fix hanging off [PreferDoNotation] it would invite "apply all", which is
/// the one way to get a file full of `final a = ...` in a single keystroke.
class ConvertFlatMapToDoNotation extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToDoNotation',
    30,
    "Convert to 'Do' notation",
  );

  ConvertFlatMapToDoNotation({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final outermost = _outermostFlatMap();
    if (outermost == null) return;

    final target = outermost.realTarget;
    if (target == null) return;

    final wrapperType = outermost.staticType;
    if (wrapperType == null) return;

    final wrapper = _wrapperName(wrapperType);
    if (wrapper == null) return;

    // The chain's first step is whatever the outermost `flatMap` was called
    // on; every later step is one callback deeper.
    final steps = <_Step>[];
    final firstName = _parameterNameOf(outermost);
    if (firstName == null) return;
    steps.add((name: firstName, source: target.toSource()));

    final returned = _collectSteps(outermost, steps);
    if (returned == null) return;
    // Fewer than two steps is not a nest; `Do` would only add ceremony.
    if (steps.length < 2) return;

    // The nest usually starts mid-line (`goShopping() => x.flatMap(`), so the
    // block's body has to be indented relative to that line's *leading
    // whitespace* — not to everything before the node, which `indentOf`
    // returns and which would prefix every generated line with the code that
    // happened to precede the call.
    final indent = _leadingWhitespaceOf(outermost.offset);
    final body = StringBuffer('$wrapper.Do((\$) {\n');
    for (final step in steps) {
      body.write('$indent  final ${step.name} = \$(${step.source});\n');
    }
    body.write('$indent  return $returned;\n');
    body.write('$indent})');

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outermost), body.toString());

      // Offer every generated name for renaming in one pass. Offsets are
      // computed against the replacement text, which starts at the node's own
      // offset.
      var cursor = outermost.offset + '$wrapper.Do((\$) {\n'.length;
      for (final step in steps) {
        final nameOffset = cursor + indent.length + 2 + 'final '.length;
        builder.addLinkedPosition(
          SourceRange(nameOffset, step.name.length),
          step.name,
        );
        cursor +=
            indent.length +
            2 +
            'final ${step.name} = \$(${step.source});\n'.length;
      }
    });
  }

  /// The leading whitespace of the line containing [offset].
  String _leadingWhitespaceOf(int offset) {
    final content = unitResult.content;
    if (offset <= 0) return '';

    final lineStart = content.lastIndexOf('\n', offset - 1) + 1;

    var end = lineStart;
    while (end < content.length &&
        (content[end] == ' ' || content[end] == '\t')) {
      end++;
    }

    return content.substring(lineStart, end);
  }

  /// The outermost `flatMap` of the nest the cursor sits in.
  MethodInvocation? _outermostFlatMap() {
    MethodInvocation? outermost;

    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is MethodInvocation && _isFpdartFlatMap(current)) {
        outermost = current;
      }
    }

    return outermost;
  }

  /// Whether [node] is `flatMap` on an fpdart type.
  bool _isFpdartFlatMap(MethodInvocation node) {
    if (node.methodName.name != 'flatMap') return false;

    final targetType = node.realTarget?.staticType;
    return targetType != null &&
        anyFpdartChecker.isAssignableFromType(targetType);
  }

  /// The single parameter name of [node]'s callback.
  String? _parameterNameOf(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return null;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.length != 1) return null;

    return parameters.first.name?.lexeme;
  }

  /// The body [node]'s callback evaluates to.
  Expression? _callbackBodyOf(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return null;

    return maybeGetSingleReturnExpression(callback.body);
  }

  /// Walks the nest, appending each step, and returns the source of what the
  /// innermost callback produces.
  ///
  /// The innermost step is the one place this cannot be purely mechanical: a
  /// callback ending in `Option.of(x)` becomes `return x`, because `Do` wraps
  /// the block's result itself. Anything else stays a step and is extracted —
  /// `return $(market.buyPear())`.
  String? _collectSteps(MethodInvocation node, List<_Step> steps) {
    final body = _callbackBodyOf(node);
    if (body == null) return null;

    final inner = body.unParenthesized;
    if (inner is MethodInvocation && _isFpdartFlatMap(inner)) {
      final name = _parameterNameOf(inner);
      final target = inner.realTarget;
      if (name == null || target == null) return null;

      steps.add((name: name, source: target.toSource()));
      return _collectSteps(inner, steps);
    }

    return _unwrapLift(inner);
  }

  /// `Option.of(x)` → `x`; anything else → `$(expr)`.
  String? _unwrapLift(Expression expression) {
    if (expression is InstanceCreationExpression) {
      final constructorName = expression.constructorName;
      final element = constructorName.element;
      if (element != null &&
          anyFpdartChecker.isExactly(element.enclosingElement)) {
        final name = constructorName.name?.name;
        if (name == 'of' || name == 'right') {
          final arguments = expression.argumentList.arguments;
          if (arguments.length == 1) {
            final argument = arguments.first;
            if (argument is Expression) return argument.toSource();
          }
        }
      }
    }

    return '\$(${expression.toSource()})';
  }

  /// The fpdart wrapper's name, for the `<Type>.Do` the block opens with.
  String? _wrapperName(DartType type) =>
      type is InterfaceType && anyFpdartChecker.isAssignableFromType(type)
      ? type.element.name
      : null;
}
