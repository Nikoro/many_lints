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

    // Edge case: a constructor repeats the class name, so renaming only the class breaks it
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

  List<ClassMember> _members(ClassDeclaration declaration) =>
      switch (declaration.body) {
        BlockClassBody(:final members) => members.toList(),
        _ => const [],
      };

  static const _maxTypoEdits = 2;

  static String _stripMisspelled(String name, String affix, AffixKind kind) {
    final affixLower = affix.toLowerCase();
    final affixLen = affix.length;

    // Edge case: rank by distance, or `CounterBlok` + `Bloc` strips `rBlok` into `CounteBloc`
    var bestLen = -1;
    var bestDistance = affixLen + 1;

    for (
      var len = affixLen - _maxTypoEdits;
      len <= affixLen + _maxTypoEdits;
      len++
    ) {
      if (len <= 0 || len >= name.length) continue;

      final candidate = switch (kind) {
        AffixKind.suffix => name.substring(name.length - len),
        AffixKind.prefix => name.substring(0, len),
      };
      final distance = computeEditDistance(candidate.toLowerCase(), affixLower);

      if (distance == 0 || distance > _maxTypoEdits) continue;

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
