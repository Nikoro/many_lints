import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

class AvoidUnnecessaryConsumerWidgetsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.convertConsumerWidgetToStatelessWidget',
    DartFixKindPriority.standard,
    'Remove unnecessary Consumer base class',
  );

  AvoidUnnecessaryConsumerWidgetsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final superclass = classDecl.extendsClause?.superclass;
    if (superclass == null) return;

    final superclassName = superclass.name.lexeme;
    // Edge case: its build still calls hooks, so it keeps HookWidget instead of StatelessWidget
    final replacement = switch (superclassName) {
      'ConsumerWidget' => 'StatelessWidget',
      'ConsumerStatefulWidget' => 'StatefulWidget',
      'HookConsumerWidget' => 'HookWidget',
      _ => null,
    };
    if (replacement == null) return;

    final body = classDecl.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'build');

    final refParam = buildMethod?.parameters?.parameters.firstWhereOrNull(
      (p) => p.name?.lexeme == 'ref',
    );

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(superclass), replacement);

      if (refParam != null && buildMethod != null) {
        builder.addDeletion(
          range.nodeInList(buildMethod.parameters!.parameters, refParam),
        );
      }
    });
  }
}
