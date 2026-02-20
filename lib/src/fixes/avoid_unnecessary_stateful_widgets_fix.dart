import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that converts a StatefulWidget to a StatelessWidget by inlining the
/// build method and removing the State class.
class AvoidUnnecessaryStatefulWidgetsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.convertStatefulToStatelessWidget',
    DartFixKindPriority.standard,
    'Convert to StatelessWidget',
  );

  AvoidUnnecessaryStatefulWidgetsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! SimpleIdentifier) return;

    final widgetClass = targetNode.parent;
    if (widgetClass is! ClassDeclaration) return;

    final superclass = widgetClass.extendsClause?.superclass;
    if (superclass == null) return;

    final widgetName = targetNode.name;

    // Find the companion State class in the same compilation unit
    final compilationUnit = widgetClass.parent;
    if (compilationUnit is! CompilationUnit) return;

    final stateClass = _findStateClass(compilationUnit, widgetName);
    if (stateClass == null) return;

    // Extract build method from state class
    final stateBody = stateClass.body;
    if (stateBody is! BlockClassBody) return;

    final buildMethod = stateBody.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'build');
    if (buildMethod == null) return;

    // Get the widget class body
    final widgetBody = widgetClass.body;
    if (widgetBody is! BlockClassBody) return;

    // Build the replacement for the widget class body
    final buildMethodSource = buildMethod.toSource();

    // Collect non-createState members from the widget (fields, constructors, etc.)
    final existingMembers = <String>[];
    for (final member in widgetBody.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'createState') {
        continue;
      }
      existingMembers.add(member.toSource());
    }

    // Also collect non-build, non-lifecycle members from State class
    // (final fields, static fields, helper methods)
    for (final member in stateBody.members) {
      if (member is MethodDeclaration) {
        final name = member.name.lexeme;
        if (name == 'build') continue;
        // Skip any lifecycle methods (shouldn't exist but be safe)
        if (const {
          'initState',
          'dispose',
          'didChangeDependencies',
          'didUpdateWidget',
          'deactivate',
          'activate',
          'reassemble',
          'createState',
        }.contains(name)) {
          continue;
        }
        existingMembers.add(member.toSource());
      } else if (member is FieldDeclaration) {
        existingMembers.add(member.toSource());
      }
    }

    existingMembers.add(buildMethodSource);

    final newBody = '{\n  ${existingMembers.join('\n\n  ')}\n}';

    // Build the full new class
    final annotations = widgetClass.metadata
        .map((m) => m.toSource())
        .join('\n');
    final annotationsPrefix = annotations.isNotEmpty ? '$annotations\n' : '';
    final abstractKeyword = widgetClass.abstractKeyword != null
        ? 'abstract '
        : '';

    final newClass =
        '$annotationsPrefix${abstractKeyword}class $widgetName extends StatelessWidget $newBody';

    await builder.addDartFileEdit(file, (builder) {
      // Replace the entire widget class
      builder.addSimpleReplacement(range.node(widgetClass), newClass);

      // Delete the State class (including any preceding whitespace/newlines)
      final stateStart = stateClass.offset;
      final stateEnd = stateClass.end;

      // Try to extend deletion to consume surrounding newlines
      final content = unitResult.content;
      var deleteStart = stateStart;
      while (deleteStart > 0 && content[deleteStart - 1] == '\n') {
        deleteStart--;
      }
      // Keep one newline before
      if (deleteStart < stateStart) deleteStart++;

      var deleteEnd = stateEnd;
      while (deleteEnd < content.length && content[deleteEnd] == '\n') {
        deleteEnd++;
      }

      builder.addDeletion(range.startOffsetEndOffset(deleteStart, deleteEnd));
    });
  }

  static ClassDeclaration? _findStateClass(
    CompilationUnit unit,
    String widgetName,
  ) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final superclass = declaration.extendsClause?.superclass;
      if (superclass == null) continue;

      final typeArgs = superclass.typeArguments?.arguments;
      if (typeArgs != null && typeArgs.length == 1) {
        final typeArg = typeArgs.first;
        if (typeArg is NamedType && typeArg.name.lexeme == widgetName) {
          return declaration;
        }
      }
    }
    return null;
  }
}
