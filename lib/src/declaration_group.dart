import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

import 'rule_config.dart';
import 'type_checker.dart';

enum DeclarationKind {
  class_('class'),
  mixin_('mixin'),
  enum_('enum'),
  extension_('extension'),
  extensionType('extension_type');

  const DeclarationKind(this.optionName);

  final String optionName;

  static const defaults = <DeclarationKind>{
    DeclarationKind.class_,
    DeclarationKind.mixin_,
    DeclarationKind.enum_,
    DeclarationKind.extension_,
    DeclarationKind.extensionType,
  };

  static DeclarationKind? parse(String value) {
    for (final kind in DeclarationKind.values) {
      if (kind.optionName == value) return kind;
    }
    return null;
  }

  static DeclarationKind? of(
    CompilationUnitMember declaration,
  ) => switch (declaration) {
    ClassDeclaration() => DeclarationKind.class_,
    MixinDeclaration() => DeclarationKind.mixin_,
    EnumDeclaration() => DeclarationKind.enum_,
    ExtensionTypeDeclaration() => DeclarationKind.extensionType,
    // Edge case: an extension type reads as an extension but is a separate kind
    ExtensionDeclaration() => DeclarationKind.extension_,
    _ => null,
  };
}

class DeclarationGroup {
  final Set<DeclarationKind> kinds;

  final Set<String> types;

  final bool ignorePrivate;

  final bool ignoreVisibleForTesting;

  final String? message;

  const DeclarationGroup({
    required this.kinds,
    required this.types,
    required this.ignorePrivate,
    required this.ignoreVisibleForTesting,
    required this.message,
  });

  bool counts(CompilationUnitMember declaration, Element? element) {
    final kind = DeclarationKind.of(declaration);
    if (kind == null || !kinds.contains(kind)) return false;

    final name = declarationName(declaration);
    if (name == null) return false;

    if (ignorePrivate && name.startsWith('_')) return false;

    if (ignoreVisibleForTesting &&
        declaration.metadata.any((a) => a.name.name == 'visibleForTesting')) {
      return false;
    }

    if (types.isEmpty) return true;
    if (element == null) return false;

    for (final type in types) {
      // Edge case: isSuperOf is reflexive, so a file with `Bloc` plus a subclass holds two blocs
      if (TypeChecker.fromName(type).isSuperOf(element)) return true;
    }

    return false;
  }
}

String? declarationName(CompilationUnitMember declaration) =>
    declarationNameToken(declaration)?.lexeme;

Token? declarationNameToken(CompilationUnitMember declaration) =>
    switch (declaration) {
      ClassDeclaration() => declaration.namePart.typeName,
      EnumDeclaration() => declaration.namePart.typeName,
      ExtensionTypeDeclaration() => declaration.namePart.typeName,
      MixinDeclaration() => declaration.name,
      ExtensionDeclaration() => declaration.name,
      _ => null,
    };

List<DeclarationGroup> readDeclarationGroups(RuleConfig config) {
  final baseKinds = _kinds(config.options['kinds'], DeclarationKind.defaults);
  final baseTypes = _strings(config.options['types']).toSet();
  final baseIgnorePrivate = config.boolOption(
    'ignore_private',
    defaultValue: true,
  );
  final baseIgnoreVisibleForTesting = config.boolOption(
    'ignore_visible_for_testing',
    defaultValue: false,
  );

  DeclarationGroup defaultGroup() => DeclarationGroup(
    kinds: baseKinds.isEmpty ? DeclarationKind.defaults : baseKinds,
    types: baseTypes,
    ignorePrivate: baseIgnorePrivate,
    ignoreVisibleForTesting: baseIgnoreVisibleForTesting,
    message: null,
  );

  final raw = config.entriesOption('groups');
  if (raw.isEmpty) return [defaultGroup()];

  final groups = <DeclarationGroup>[];
  for (final entry in raw) {
    final kinds = _kinds(entry['kinds'], baseKinds);
    // Edge case: an all-unrecognized group would widen to the defaults, so it is dropped
    if (kinds.isEmpty) continue;

    groups.add(
      DeclarationGroup(
        kinds: kinds,
        types: entry.containsKey('types')
            ? _strings(entry['types']).toSet()
            : baseTypes,
        ignorePrivate: _bool(entry['ignore_private']) ?? baseIgnorePrivate,
        ignoreVisibleForTesting:
            _bool(entry['ignore_visible_for_testing']) ??
            baseIgnoreVisibleForTesting,
        message: _nonEmptyString(entry['message']),
      ),
    );
  }

  if (groups.isEmpty) return [defaultGroup()];

  return groups;
}

Set<DeclarationKind> _kinds(Object? value, Set<DeclarationKind> defaultValue) {
  if (value == null) return defaultValue;

  final names = _strings(value);
  if (names.isEmpty) return defaultValue;

  final kinds = <DeclarationKind>{};
  for (final name in names) {
    final kind = DeclarationKind.parse(name);
    if (kind != null) kinds.add(kind);
  }

  return kinds;
}

List<String> _strings(Object? value) {
  if (value is String) return value.isEmpty ? const [] : [value];
  if (value is! List) return const [];

  return [
    for (final item in value)
      if (item is String && item.isNotEmpty) item,
  ];
}

bool? _bool(Object? value) => value is bool ? value : null;

String? _nonEmptyString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
