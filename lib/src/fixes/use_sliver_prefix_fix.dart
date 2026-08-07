import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that adds the 'Sliver' prefix to a widget class name.
class UseSliverPrefixFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useSliverPrefix',
    DartFixKindPriority.standard,
    "Add 'Sliver' prefix",
  );

  UseSliverPrefixFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The rule reports at the class-name token, so there is no identifier
    // node to replace — rename the token on the enclosing declaration.
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final nameToken = declaration.namePart.typeName;
    final newName = 'Sliver${nameToken.lexeme}';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(nameToken), newName);
    });
  }
}
