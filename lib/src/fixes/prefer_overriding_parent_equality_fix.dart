import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that generates `==` and `hashCode` overrides for a class whose parent
/// already defines custom equality.
class PreferOverridingParentEqualityFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferOverridingParentEquality',
    DartFixKindPriority.standard,
    'Override == and hashCode',
  );

  PreferOverridingParentEqualityFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ClassDeclaration) return;

    final element = targetNode.declaredFragment?.element;
    if (element == null) return;

    final className = targetNode.namePart.typeName.lexeme;

    // Gather instance fields
    final instanceFields = element.fields
        .where((f) => !f.isStatic && f.isOriginDeclaration)
        .toList();

    final fieldNames = instanceFields.map((f) => f.name).toList();

    // Build the override code
    final equalsBody = _buildEqualsBody(className, fieldNames);
    final hashCodeBody = _buildHashCodeBody(fieldNames);

    final body = targetNode.body;
    if (body is! BlockClassBody) return;

    // Check which overrides are already present
    final hasEquals = body.members.any(
      (m) => m is MethodDeclaration && m.isOperator && m.name.lexeme == '==',
    );
    final hasHashCode = body.members.any(
      (m) =>
          m is MethodDeclaration && m.isGetter && m.name.lexeme == 'hashCode',
    );

    if (hasEquals && hasHashCode) return;

    // Insert before the closing brace
    final insertOffset = body.rightBracket.offset;

    final buffer = StringBuffer();
    if (!hasEquals) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.write(equalsBody);
    }
    if (!hasHashCode) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.write(hashCodeBody);
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(insertOffset, buffer.toString());
    });
  }

  static String _buildEqualsBody(String className, List<String?> fieldNames) {
    final buffer = StringBuffer();
    buffer.writeln('  bool operator ==(Object other) {');
    buffer.writeln('    if (identical(this, other)) return true;');
    buffer.write('    return other is $className');

    for (final name in fieldNames) {
      if (name == null) continue;
      buffer.write(' &&\n        $name == other.$name');
    }
    buffer.writeln(';');
    buffer.writeln('  }');
    return buffer.toString();
  }

  static String _buildHashCodeBody(List<String?> fieldNames) {
    final buffer = StringBuffer();
    final validNames = fieldNames.whereType<String>().toList();

    if (validNames.isEmpty) {
      buffer.writeln('  int get hashCode => runtimeType.hashCode;');
    } else if (validNames.length == 1) {
      buffer.writeln('  int get hashCode => ${validNames.first}.hashCode;');
    } else {
      buffer.write('  int get hashCode => Object.hash(');
      buffer.write(validNames.join(', '));
      buffer.writeln(');');
    }
    return buffer.toString();
  }
}
