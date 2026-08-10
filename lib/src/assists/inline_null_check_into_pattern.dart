import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../null_check_pattern_conversion.dart';

/// Converts `if (x != null)` into an object pattern that also destructures a
/// field the branch asserts is non-null.
///
/// **Example**:
///
/// ```dart
/// if (userData != null) {
///   sendEvent(userData!.name!);
/// }
/// ```
///
/// becomes
///
/// ```dart
/// if (userData case UserData(:final name?)) {
///   sendEvent(name);
/// }
/// ```
///
/// ## This changes behaviour, deliberately
///
/// The object pattern adds a second condition: the branch now runs only when
/// `name` is also non-null. Given
///
/// ```dart
/// userData != null && userData.name == null
/// ```
///
/// the original enters the branch and the rewritten form skips it.
///
/// That is why this is a separate assist from
/// [ConvertNullCheckToPattern], which preserves semantics exactly, and why it
/// is offered **only** when the branch contains `x!.field!` — asserting the
/// field non-null is the author stating that a null there was never a case
/// they intended to handle. Turning that assertion into a condition is the
/// point of the refactor, but it stays an explicit choice rather than
/// something the safe conversion does silently.
///
/// It is never a quick fix, for the same reason: "apply all" must not be able
/// to narrow conditions across a file.
class InlineNullCheckIntoPattern extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.inlineNullCheckIntoPattern',
    31,
    'Convert null check to destructuring pattern',
  );

  InlineNullCheckIntoPattern({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final guard = NullCheckGuard.tryRead(node);
    if (guard == null) return;

    // The type has to be nameable to write `UserData(...)`.
    final typeName = _typeNameOf(guard.checked);
    if (typeName == null) return;

    final asserted = _assertedField(guard);
    if (asserted == null) return;

    final (fieldName, accesses) = asserted;

    final prefix = '${guard.checkedSource} case $typeName(:final ';
    final replacement = '$prefix$fieldName?)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(guard.condition.offset, guard.condition.length),
        replacement,
      );

      // Every `x!.field!` collapses to the destructured name.
      for (final access in accesses) {
        builder.addSimpleReplacement(
          SourceRange(access.offset, access.length),
          fieldName,
        );
      }

      builder.addLinkedPosition(
        SourceRange(guard.condition.offset + prefix.length, fieldName.length),
        fieldName,
      );
    });
  }

  /// The written name of [expression]'s type, or `null` when it cannot be
  /// spelled in a pattern.
  ///
  /// Read from the resolved element rather than the annotation, because the
  /// checked expression is often a field whose type is written elsewhere. A
  /// type with arguments is declined: `UserData<String>(...)` would need the
  /// arguments spelled out, and getting them wrong produces code that does not
  /// compile.
  String? _typeNameOf(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return null;
    if (type.typeArguments.isNotEmpty) return null;

    return type.element.name;
  }

  /// The single field the guarded branch asserts non-null, with every access
  /// to rewrite.
  ///
  /// Returns `null` unless exactly one field is asserted. Two different
  /// asserted fields would need two destructured names, and choosing which one
  /// to inline would be arbitrary — the author can apply the assist again
  /// after the first conversion.
  (String, List<AstNode>)? _assertedField(NullCheckGuard guard) {
    final accessesByField = <String, List<AstNode>>{};

    for (final bang in guard.bangsInGuardedBranch) {
      // `x!` on its own is the plain conversion's job, not this one.
      final parent = bang.parent;

      // `x!.field` reads as a PropertyAccess whose target is the bang.
      if (parent is! PropertyAccess) return null;
      if (parent.target != bang) return null;

      // Only `x!.field!` counts: without the inner bang the branch is not
      // asserting the field is non-null, so narrowing the condition would
      // change behaviour without the author having said so.
      final outer = parent.parent;
      if (outer is! PostfixExpression) return null;
      if (outer.operator.lexeme != '!') return null;

      accessesByField
          .putIfAbsent(parent.propertyName.name, () => [])
          .add(outer);
    }

    if (accessesByField.length != 1) return null;

    final entry = accessesByField.entries.first;
    return (entry.key, entry.value);
  }
}
