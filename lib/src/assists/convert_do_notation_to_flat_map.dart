import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../fpdart_do_notation.dart';
import '../fpdart_type_checkers.dart';

typedef _Step = ({String name, String source});

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

    if (steps.isEmpty) return;

    final result = _readResult(invocation, block.result, wrapper);
    if (result == null) return;

    final indent = _leadingWhitespaceOf(invocation.node.offset);
    final body = _buildChain(steps, result, indent);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(invocation.node), body);
    });
  }

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

  String? _extractedSource(DoInvocation invocation, Expression expression) {
    var inner = expression.unParenthesized;

    // Edge case: in async Do blocks the `await` before `$(...)` belongs to the block
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

  String? _readResult(
    DoInvocation invocation,
    Expression result,
    String wrapper,
  ) {
    final extracted = _extractedSource(invocation, result);
    if (extracted != null) return extracted;

    // Edge case: `$` outside a returned extraction mixes extraction with computation
    if (_containsExtractorCall(invocation, result)) return null;

    return '$wrapper.of(${result.toSource()})';
  }

  bool _containsExtractorCall(DoInvocation invocation, Expression expression) {
    final finder = _ExtractorCallFinder(invocation);
    expression.accept(finder);
    return finder.found;
  }

  String? _wrapperName(DartType type) =>
      type is InterfaceType && anyFpdartChecker.isAssignableFromType(type)
      ? type.element.name
      : null;
}

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
