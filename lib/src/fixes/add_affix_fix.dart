import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../class_affix_validator.dart';
import '../rule_config.dart';
import '../text_distance.dart';

/// Fix that adds the configured prefix or suffix to a class name.
///
/// The affix is not known at registration time — it comes from the user's
/// `entries:` — so this fix re-resolves the rule's configuration from the file
/// being edited and re-runs the same entry matching the rule used. Deriving it
/// this way rather than parsing the diagnostic message keeps the fix correct
/// if the message is ever reworded, and mirrors `dispose_fields_fix.dart`.
class AddAffixFix extends ResolvedCorrectionProducer {
  final AffixKind kind;
  final String ruleName;
  final FixKind _fixKind;

  AddAffixFix._({
    required super.context,
    required this.kind,
    required this.ruleName,
    required FixKind fixKind,
  }) : _fixKind = fixKind;

  /// Factory for `use_class_suffix`.
  static AddAffixFix suffixFix({required CorrectionProducerContext context}) =>
      AddAffixFix._(
        context: context,
        kind: AffixKind.suffix,
        ruleName: 'use_class_suffix',
        fixKind: FixKind(
          'many_lints.fix.addClassSuffix',
          DartFixKindPriority.standard,
          'Add the required suffix',
        ),
      );

  /// Factory for `use_class_prefix`.
  static AddAffixFix prefixFix({required CorrectionProducerContext context}) =>
      AddAffixFix._(
        context: context,
        kind: AffixKind.prefix,
        ruleName: 'use_class_prefix',
        fixKind: FixKind(
          'many_lints.fix.addClassPrefix',
          DartFixKindPriority.standard,
          'Add the required prefix',
        ),
      );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The rule reports at the class-name *token*, so the covering node is the
    // declaration, not an identifier.
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final element = declaration.declaredFragment?.element;
    if (element == null) return;

    final nameToken = declaration.namePart.typeName;
    final oldName = nameToken.lexeme;

    final affix = _resolveAffix(element: element, className: oldName);
    if (affix == null) return;

    final newName = switch (kind) {
      AffixKind.suffix => '${_stripMisspelled(oldName, affix, kind)}$affix',
      AffixKind.prefix => '$affix${_stripMisspelled(oldName, affix, kind)}',
    };
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

  /// Re-resolves the rule's `entries:` for this file and returns the affix of
  /// the entry this class violates.
  String? _resolveAffix({
    required InterfaceElement element,
    required String className,
  }) {
    final resolved = ResolvedRuleConfig.forPath(
      packageRoot: unitResult.session.analysisContext.contextRoot.root,
      path: unitResult.path,
      ruleName: ruleName,
    );

    final entries = readAffixEntries(resolved.config, kind);
    if (entries.isEmpty) return null;

    return findViolatedEntry(
      entries: entries,
      element: element,
      className: className,
      kind: kind,
    )?.affix;
  }

  /// Returns the members of [declaration], or empty when the body has none.
  List<ClassMember> _members(ClassDeclaration declaration) =>
      switch (declaration.body) {
        BlockClassBody(:final members) => members.toList(),
        _ => const [],
      };

  /// Strips a potentially misspelled [affix] from [name].
  ///
  /// Checks leading/trailing substrings of [name] (with length close to
  /// [affix]) and removes them if they look like a typo of [affix] based on
  /// case-insensitive edit distance — so `CounterBlok` becomes `CounterBloc`
  /// rather than `CounterBlokBloc`.
  static String _stripMisspelled(String name, String affix, AffixKind kind) {
    final affixLower = affix.toLowerCase();
    final affixLen = affix.length;

    // A misspelling could be shorter or longer by a few characters, so try a
    // window of lengths and keep the *closest* match rather than the first.
    //
    // Taking the first hit of a descending scan is wrong: for `CounterBlok`
    // + `Bloc` the 5-char tail `rBlok` is within 2 edits, so it would be
    // stripped along with the `r` that belongs to the name, giving
    // `CounteBloc`. Ranking by edit distance keeps the 4-char `Blok`.
    var bestLen = -1;
    var bestDistance = affixLen + 1;

    for (var len = affixLen - 2; len <= affixLen + 2; len++) {
      if (len <= 0 || len >= name.length) continue;

      final candidate = switch (kind) {
        AffixKind.suffix => name.substring(name.length - len),
        AffixKind.prefix => name.substring(0, len),
      };
      final distance = computeEditDistance(candidate.toLowerCase(), affixLower);

      // Allow up to 2 edits for the affix to be considered a typo. Distance 0
      // means it is already spelled correctly, so there is nothing to strip.
      if (distance == 0 || distance > 2) continue;

      // Ties go to the length closest to the affix's own.
      if (distance < bestDistance ||
          (distance == bestDistance &&
              (len - affixLen).abs() < (bestLen - affixLen).abs())) {
        bestDistance = distance;
        bestLen = len;
      }
    }

    if (bestLen >= 0) {
      return switch (kind) {
        AffixKind.suffix => name.substring(0, name.length - bestLen),
        AffixKind.prefix => name.substring(bestLen),
      };
    }

    return name;
  }
}
