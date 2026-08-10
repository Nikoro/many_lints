import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../fpdart_do_notation.dart';
import '../fpdart_type_checkers.dart';

/// One extracted step of a `Do` block: `final <name> = $(<source>);`.
typedef _Step = ({String name, String source});

/// Converts a `Do` block back into a chain of nested `flatMap` callbacks.
///
/// The inverse of [ConvertFlatMapToDoNotation]. Given:
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
/// with the cursor anywhere in the block, the assist produces:
///
/// ```dart
/// goToShoppingCenter().flatMap(
///   (market) => market.buyBanana().flatMap(
///     (banana) => market.buyApple().flatMap(
///       (apple) => Option.of('$banana, $apple'),
///     ),
///   ),
/// );
/// ```
///
/// ## Why only the straight-line shape converts
///
/// `Do` is imperative: its body may branch, loop, or extract conditionally,
/// and `$` may be called anywhere an expression is allowed. `flatMap` is a
/// fixed chain of continuations, so translating the general case would mean a
/// CPS transform — turning `if`/`for` into combinator calls and duplicating the
/// continuation into every arm.
///
/// This assist therefore recognises exactly the shape [ConvertFlatMapToDoNotation]
/// emits — a run of `final <name> = $(<expr>);` bindings followed by a single
/// `return` — and declines everything else rather than silently mangling it.
/// That covers round-tripping and the great majority of hand-written blocks; a
/// block that does more is one where `Do` is genuinely the better notation.
///
/// ## Why an assist rather than a quick fix
///
/// There is no rule to hang it on. `Do` notation is the *preferred* form here —
/// `prefer_do_notation` pushes the other way — so going back to `flatMap` is a
/// deliberate, situational choice (matching surrounding code, or stepping out
/// of a block whose imperative shape was never needed), never a diagnostic.
class ConvertDoNotationToFlatMap extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertDoNotationToFlatMap',
    30,
    "Convert to 'flatMap' chain",
  );

  ConvertDoNotationToFlatMap({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = _outermostDo();
    if (invocation == null) return;

    final wrapperType = invocation.node.staticType;
    if (wrapperType == null) return;

    final wrapper = _wrapperName(wrapperType);
    if (wrapper == null) return;

    final block = _statementsOf(invocation);
    if (block == null) return;

    final steps = <_Step>[];
    for (final statement in block.bindings) {
      final step = _readBinding(invocation, statement);
      if (step == null) return;
      steps.add(step);
    }

    // A single step is `Type.Do(($) => ...)` in disguise; rewriting it as a
    // `flatMap` chain of length one has no chain to speak of.
    if (steps.isEmpty) return;

    final result = _readResult(invocation, block.result, wrapper);
    if (result == null) return;

    final indent = _leadingWhitespaceOf(invocation.node.offset);
    final body = _buildChain(steps, result, indent);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(invocation.node), body);
    });
  }

  /// Builds the nested `flatMap` chain, one level of indentation per step.
  String _buildChain(List<_Step> steps, String result, String indent) {
    final buffer = StringBuffer();

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final inner = '$indent${'  ' * (i + 1)}';
      buffer.write(step.source);
      buffer.write('.flatMap(\n$inner(${step.name}) => ');
    }

    buffer.write(result);

    for (var i = steps.length - 1; i >= 0; i--) {
      buffer.write(',\n$indent${'  ' * i})');
    }

    return buffer.toString();
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

  /// The outermost `Do` block the cursor sits in.
  ///
  /// Walking up rather than taking the innermost match mirrors
  /// [ConvertFlatMapToDoNotation]: converting an inner block first would leave
  /// the outer one holding a `flatMap` chain it cannot re-flatten, so the whole
  /// nest is the unit of work.
  DoInvocation? _outermostDo() {
    DoInvocation? outermost;

    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is InstanceCreationExpression) {
        final invocation = DoInvocation.tryRead(current);
        if (invocation != null) outermost = invocation;
      }
    }

    return outermost;
  }

  /// Splits the block body into its bindings and its single trailing `return`.
  ///
  /// Returns null unless the body is a block of statements ending in a
  /// `return` with a value — an expression-bodied callback has no bindings to
  /// unfold, and a body without a final `return` produces nothing to chain to.
  ({List<Statement> bindings, Expression result})? _statementsOf(
    DoInvocation invocation,
  ) {
    final body = invocation.body;
    if (body is! BlockFunctionBody) return null;

    final statements = body.block.statements;
    if (statements.isEmpty) return null;

    final last = statements.last;
    if (last is! ReturnStatement) return null;

    final result = last.expression;
    if (result == null) return null;

    return (
      bindings: statements.sublist(0, statements.length - 1),
      result: result,
    );
  }

  /// Reads `final <name> = $(<expr>);` out of [statement].
  ///
  /// Anything else — a plain expression statement, a multi-variable
  /// declaration, a binding whose initialiser is not an extraction — makes the
  /// block unconvertible, so this returns null and the assist declines.
  _Step? _readBinding(DoInvocation invocation, Statement statement) {
    if (statement is! VariableDeclarationStatement) return null;

    final variables = statement.variables.variables;
    if (variables.length != 1) return null;

    final variable = variables.first;
    final initializer = variable.initializer;
    if (initializer == null) return null;

    final source = _extractedSource(invocation, initializer);
    if (source == null) return null;

    return (name: variable.name.lexeme, source: source);
  }

  /// The pipeline inside `$(<expr>)`, or `await $(<expr>)` in an async block.
  ///
  /// Returns null when [expression] is not a bare extraction — `$(a()) + 1`
  /// mixes extraction with computation, which has no direct `flatMap`
  /// equivalent as a chain step.
  String? _extractedSource(DoInvocation invocation, Expression expression) {
    var inner = expression.unParenthesized;

    // `TaskEither.Do` and `Task.Do` take an async callback whose extractions
    // read `await $(...)`; the `await` belongs to the block, not to the step.
    if (inner is AwaitExpression) {
      if (!invocation.isAsync) return null;
      inner = inner.expression.unParenthesized;
    }

    if (!invocation.isExtractorCall(inner)) return null;

    final arguments = switch (inner) {
      FunctionExpressionInvocation() => inner.argumentList.arguments,
      MethodInvocation() => inner.argumentList.arguments,
      _ => null,
    };
    if (arguments == null || arguments.length != 1) return null;

    final argument = arguments.first;
    return argument is Expression ? argument.toSource() : null;
  }

  /// The chain's innermost expression, re-wrapped when the block returned a
  /// plain value.
  ///
  /// `Do` lifts its own result, so `return x` has to become `Type.of(x)` to
  /// keep the chain well-typed — the exact inverse of the forward assist's
  /// unwrapping. A `return $(pipeline())` is already wrapped and passes
  /// through unchanged.
  String? _readResult(
    DoInvocation invocation,
    Expression result,
    String wrapper,
  ) {
    final extracted = _extractedSource(invocation, result);
    if (extracted != null) return extracted;

    // A returned extraction is the only legal use of `$` in the result; if `$`
    // appears anywhere else in there, the expression mixes extraction with
    // computation and cannot become a chain step.
    if (_containsExtractorCall(invocation, result)) return null;

    return '$wrapper.of(${result.toSource()})';
  }

  /// Whether [expression] contains a call to the block's extraction function.
  bool _containsExtractorCall(DoInvocation invocation, Expression expression) {
    final finder = _ExtractorCallFinder(invocation);
    expression.accept(finder);
    return finder.found;
  }

  /// The fpdart wrapper's name, for the `<Type>.of` the chain may end with.
  String? _wrapperName(DartType type) =>
      type is InterfaceType && anyFpdartChecker.isAssignableFromType(type)
      ? type.element.name
      : null;
}

/// Reports whether a subtree calls the block's extraction function anywhere.
class _ExtractorCallFinder extends DoBodyVisitor {
  bool found = false;

  _ExtractorCallFinder(super.invocation);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (invocation.isExtractorCall(node)) found = true;
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (invocation.isExtractorCall(node)) found = true;
    super.visitMethodInvocation(node);
  }
}
