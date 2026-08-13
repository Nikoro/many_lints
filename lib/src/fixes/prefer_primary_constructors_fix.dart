import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that collapses a class of final fields plus a field-assigning
/// constructor into a primary constructor.
///
/// ```dart
/// class Point {
///   final int x;
///   final int y;
///   Point(this.x, this.y);
/// }
/// // becomes
/// class Point(final int x, final int y);
/// ```
///
/// The parameter order follows the **constructor**, not the field
/// declarations: the primary constructor keeps the old constructor's public
/// signature, so reordering would silently break every positional call site.
class PreferPrimaryConstructorsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferPrimaryConstructors',
    DartFixKindPriority.standard,
    'Convert to a primary constructor',
  );

  PreferPrimaryConstructorsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) return;

    final body = classDeclaration.body;
    if (body is! BlockClassBody) return;

    final constructor = body.members
        .whereType<ConstructorDeclaration>()
        .firstWhereOrNull((_) => true);
    if (constructor == null) return;

    // Index the field declarations by name so each parameter can find its
    // declared type. Decline outright when a field carries documentation or
    // an annotation: neither has a home in a parameter list, and dropping
    // them silently is worse than leaving the diagnostic for the author.
    final fieldTypes = <String, String>{};
    for (final member in body.members.whereType<FieldDeclaration>()) {
      if (member.metadata.isNotEmpty) return;
      if (member.documentationComment != null) return;

      final typeSource = member.fields.type?.toSource();
      for (final field in member.fields.variables) {
        if (field.documentationComment != null) return;
        // An untyped `final x;` has no type to move into the header; `final`
        // alone is a valid declaring parameter, so record the empty string.
        fieldTypes[field.name.lexeme] = typeSource ?? '';
      }
    }

    // Rebuild the parameter list in the constructor's own order.
    final parameters = constructor.parameters.parameters;
    final rendered = <String>[];
    var sawNamed = false;
    var sawOptionalPositional = false;

    for (final parameter in parameters) {
      if (parameter is! FieldFormalParameter) return;
      if (parameter.metadata.isNotEmpty) return;

      final name = parameter.name.lexeme;
      final type = fieldTypes[name];
      if (type == null) return;

      final buffer = StringBuffer();
      if (parameter.requiredKeyword != null) buffer.write('required ');
      buffer.write(type.isEmpty ? 'final ' : 'final $type ');
      buffer.write(name);
      if (parameter.defaultClause case final defaultClause?) {
        buffer.write(
          ' ${defaultClause.separator.lexeme} '
          '${defaultClause.value.toSource()}',
        );
      }

      sawNamed |= parameter.isNamed;
      sawOptionalPositional |= parameter.isOptionalPositional;
      rendered.add(buffer.toString());
    }

    if (rendered.isEmpty) return;

    // Optional groups have to keep their brackets. Mixing the two is not
    // expressible, and the rule never reports it, but guard anyway.
    if (sawNamed && sawOptionalPositional) return;

    final String parameterList;
    if (sawNamed) {
      parameterList = '({${rendered.join(', ')}})';
    } else if (sawOptionalPositional) {
      // A leading required run may precede the optional group; the rule only
      // admits all-or-nothing here, so render the whole list as optional.
      parameterList = '([${rendered.join(', ')}])';
    } else {
      parameterList = '(${rendered.join(', ')})';
    }

    // `const` moves from the constructor onto the class header, where the
    // spelling is `class const Point(...)`.
    final constPrefix = constructor.constKeyword != null ? 'const ' : '';

    final namePart = classDeclaration.namePart;
    final typeParameters = namePart.typeParameters?.toSource() ?? '';
    final header =
        '$constPrefix${namePart.typeName.lexeme}$typeParameters$parameterList';

    await builder.addDartFileEdit(file, (builder) {
      // One replacement from the start of the name part through the end of the
      // body. Editing the two separately would leave the whitespace between
      // the header and the `{` behind, producing `class Point(...) ;`.
      builder.addSimpleReplacement(range.startEnd(namePart, body), '$header;');
    });
  }
}
