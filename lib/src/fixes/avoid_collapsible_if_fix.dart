import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that merges two nested `if` statements into one with `&&`.
class AvoidCollapsibleIfFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidCollapsibleIf',
    DartFixKindPriority.standard,
    "Merge conditions with '&&'",
  );

  AvoidCollapsibleIfFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final outer = node.thisOrAncestorOfType<IfStatement>();
    if (outer == null) return;

    final inner = _soleNestedIf(outer.thenStatement);
    if (inner == null) return;

    final merged =
        '${_operand(outer.expression)} && ${_operand(inner.expression)}';

    await builder.addDartFileEdit(file, (builder) {
      // Replace the outer condition with the conjunction...
      builder.addSimpleReplacement(range.node(outer.expression), merged);
      // ...then replace the whole then-branch with the inner one's body.
      builder.addSimpleReplacement(
        range.node(outer.thenStatement),
        inner.thenStatement.toSource(),
      );
    });
  }

  /// Wraps an operand in parentheses when `&&` would otherwise bind more
  /// tightly than the expression's own operator.
  String _operand(Expression expression) {
    final source = expression.toSource();
    return switch (expression) {
      BinaryExpression(operator: Token(lexeme: '||')) => '($source)',
      ConditionalExpression() => '($source)',
      _ => source,
    };
  }

  IfStatement? _soleNestedIf(Statement statement) => switch (statement) {
    IfStatement() => statement,
    Block(:final statements) when statements.length == 1 =>
      statements.first is IfStatement ? statements.first as IfStatement : null,
    _ => null,
  };
}
