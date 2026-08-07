import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../text_distance.dart';

/// Fix that appends a suffix to a class name.
class AddSuffixFix extends ResolvedCorrectionProducer {
  final String suffix;
  final FixKind _fixKind;

  AddSuffixFix._({
    required super.context,
    required this.suffix,
    required FixKind fixKind,
  }) : _fixKind = fixKind;

  /// Factory for adding "Bloc" suffix.
  static AddSuffixFix blocFix({required CorrectionProducerContext context}) {
    return AddSuffixFix._(
      context: context,
      suffix: 'Bloc',
      fixKind: FixKind(
        'many_lints.fix.addBlocSuffix',
        DartFixKindPriority.standard,
        'Add Bloc suffix',
      ),
    );
  }

  /// Factory for adding "Cubit" suffix.
  static AddSuffixFix cubitFix({required CorrectionProducerContext context}) {
    return AddSuffixFix._(
      context: context,
      suffix: 'Cubit',
      fixKind: FixKind(
        'many_lints.fix.addCubitSuffix',
        DartFixKindPriority.standard,
        'Add Cubit suffix',
      ),
    );
  }

  /// Factory for adding "Notifier" suffix.
  static AddSuffixFix notifierFix({
    required CorrectionProducerContext context,
  }) {
    return AddSuffixFix._(
      context: context,
      suffix: 'Notifier',
      fixKind: FixKind(
        'many_lints.fix.addNotifierSuffix',
        DartFixKindPriority.standard,
        'Add Notifier suffix',
      ),
    );
  }

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The rule reports at the class-name *token*, so the covering node is the
    // declaration, not an identifier. Rename that token directly.
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final nameToken = declaration.namePart.typeName;
    final oldName = nameToken.lexeme;
    final newName = '${_stripMisspelledSuffix(oldName, suffix)}$suffix';
    if (newName == oldName) return;

    // A constructor repeats the class name, so renaming only the declaration
    // would leave `class FooBloc { Foo(); }`, which does not compile.
    final constructorNames = [
      for (final member in _members(declaration))
        if (member is ConstructorDeclaration)
          if (member.typeName case final typeName?)
            if (typeName.name == oldName) typeName,
    ];

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(nameToken), newName);
      for (final returnType in constructorNames) {
        builder.addSimpleReplacement(range.node(returnType), newName);
      }
    });
  }

  /// Returns the members of [declaration], or empty when the body has none.
  List<ClassMember> _members(ClassDeclaration declaration) =>
      switch (declaration.body) {
        BlockClassBody(:final members) => members.toList(),
        _ => const [],
      };

  /// Strips a potentially misspelled suffix from [name].
  ///
  /// Checks trailing substrings of [name] (with length close to [suffix])
  /// and removes them if they look like a typo of [suffix] based on
  /// case-insensitive edit distance.
  static String _stripMisspelledSuffix(String name, String suffix) {
    final suffixLower = suffix.toLowerCase();
    final suffixLen = suffix.length;

    // Check trailing substrings of varying lengths around the suffix length.
    // A misspelling could be shorter or longer by a few characters.
    for (var len = suffixLen + 2; len >= suffixLen - 2; len--) {
      if (len <= 0 || len >= name.length) continue;

      final tail = name.substring(name.length - len);
      final distance = computeEditDistance(tail.toLowerCase(), suffixLower);

      // Allow up to 2 edits for the suffix to be considered a typo.
      if (distance > 0 && distance <= 2) {
        return name.substring(0, name.length - len);
      }
    }

    return name;
  }
}
