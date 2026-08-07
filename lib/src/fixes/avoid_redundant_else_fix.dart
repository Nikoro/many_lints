import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that removes a redundant `else`, hoisting its body to the enclosing
/// scope.
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

    // The if must sit directly in a block, otherwise there is no enclosing
    // scope to hoist the else body into.
    final parentBlock = ifStatement.parent;
    if (parentBlock is! Block) return;

    final bodySource = _hoistedSource(elseStatement);
    if (bodySource == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Drop everything from the end of the then-branch to the end of the
      // else branch, then re-emit the else body at the outer level.
      builder.addSimpleReplacement(
        range.endEnd(ifStatement.thenStatement, elseStatement),
        '\n$bodySource',
      );
    });
  }

  /// The else body rendered for the enclosing scope, or `null` when
  /// hoisting it would change meaning.
  String? _hoistedSource(Statement elseStatement) {
    if (elseStatement is! Block) {
      // A single statement can be emitted as-is unless it declares a
      // variable, which would then leak into the outer scope.
      if (elseStatement is VariableDeclarationStatement) return null;
      return elseStatement.toSource();
    }

    final statements = elseStatement.statements;
    if (statements.isEmpty) return '';

    // A declaration inside the block would be hoisted into the enclosing
    // scope, where the name may already be taken. Leave those to the user.
    if (statements.any((s) => s is VariableDeclarationStatement)) return null;

    return statements.map((s) => s.toSource()).join('\n');
  }
}
