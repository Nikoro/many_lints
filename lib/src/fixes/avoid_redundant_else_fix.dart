import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AvoidRedundantElseFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidRedundantElse',
    DartFixKindPriority.standard,
    "Remove redundant 'else'",
  );

  AvoidRedundantElseFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final ifStatement = node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement == null) return;

    final elseStatement = ifStatement.elseStatement;
    if (elseStatement == null) return;

    final parentBlock = ifStatement.parent;
    if (parentBlock is! Block) return;

    final bodySource = _hoistedSource(elseStatement);
    if (bodySource == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.endEnd(ifStatement.thenStatement, elseStatement),
        '\n$bodySource',
      );
    });
  }

  String? _hoistedSource(Statement elseStatement) {
    if (elseStatement is! Block) {
      // Edge case: a hoisted declaration would leak into the enclosing scope
      if (elseStatement is VariableDeclarationStatement) return null;
      return elseStatement.toSource();
    }

    final statements = elseStatement.statements;
    if (statements.isEmpty) return '';

    // Edge case: a hoisted declaration may collide with a name in the enclosing scope
    if (statements.any((s) => s is VariableDeclarationStatement)) return null;

    return statements.map((s) => s.toSource()).join('\n');
  }
}
