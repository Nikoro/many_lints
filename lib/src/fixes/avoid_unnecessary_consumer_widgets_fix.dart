import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:many_lints/src/ast_node_analysis.dart';

/// Fix that converts ConsumerWidget to StatelessWidget
/// or ConsumerStatefulWidget to StatefulWidget and removes unused ref parameter.
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
    final targetNode = node;
    if (targetNode is! SimpleIdentifier) return;

    final classDecl = targetNode.parent;
    if (classDecl is! ClassDeclaration) return;

    final superclass = classDecl.extendsClause?.superclass;
    if (superclass == null) return;

    final superclassName = superclass.name.lexeme;
    final String replacement;
    if (superclassName == 'ConsumerWidget') {
      replacement = 'StatelessWidget';
    } else if (superclassName == 'ConsumerStatefulWidget') {
      replacement = 'StatefulWidget';
    } else {
      return;
    }

    // Find the build method and its ref parameter
    final body = classDecl.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'build');

    final refParam = buildMethod?.parameters?.parameters.firstWhereOrNull(
      (p) => p is SimpleFormalParameter && p.name?.lexeme == 'ref',
    );

    await builder.addDartFileEdit(file, (builder) {
      // Replace superclass name
      builder.addSimpleReplacement(range.node(superclass), replacement);

      // Remove ref parameter if found
      if (refParam != null && buildMethod != null) {
        builder.addDeletion(
          range.nodeInList(buildMethod.parameters!.parameters, refParam),
        );
      }
    });
  }
}
