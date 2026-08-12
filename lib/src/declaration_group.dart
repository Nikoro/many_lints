import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

import 'rule_config.dart';
import 'type_checker.dart';

/// A kind of top-level declaration a file can hold.
///
/// Named after the YAML spelling a project writes, so the option value and the
/// enum stay in step: `kinds: [class, mixin]`.
enum DeclarationKind {
  class_('class'),
  mixin_('mixin'),
  enum_('enum'),
  extension_('extension'),
  extensionType('extension_type');

  const DeclarationKind(this.optionName);

  /// How this kind is written in configuration.
  final String optionName;

  /// The kinds counted when a group names none.
  ///
  /// The general form of the rule targets classes,
  /// mixins, extensions, enums and extension types.
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

  /// The kind of [declaration], or `null` for a declaration this rule never
  /// counts (a top-level function, variable or typedef).
  static DeclarationKind? of(
    CompilationUnitMember declaration,
  ) => switch (declaration) {
    ClassDeclaration() => DeclarationKind.class_,
    MixinDeclaration() => DeclarationKind.mixin_,
    EnumDeclaration() => DeclarationKind.enum_,
    ExtensionTypeDeclaration() => DeclarationKind.extensionType,
    // Checked after ExtensionTypeDeclaration, which is *not* a subtype of
    // ExtensionDeclaration in analyzer 14 but reads as one; keeping the order
    // explicit documents that the two are separate kinds on purpose.
    ExtensionDeclaration() => DeclarationKind.extension_,
    _ => null,
  };
}

/// One independently counted set of declarations.
///
/// Each group carries its own one-per-file budget, so a file may hold one
/// declaration from each configured group without either counting against the
/// other. That is the whole reason groups exist: a project that wants "one
/// bloc per file" and "one notifier per file" is stating two separate limits,
/// and folding them into a single count would report a file holding one of
/// each — which is exactly the layout the project asked for.
class DeclarationGroup {
  /// AST kinds this group counts.
  final Set<DeclarationKind> kinds;

  /// Base types this group is narrowed to, matched against a declaration's
  /// full supertype hierarchy. Empty means "any type of the configured kinds",
  /// which is the general form of the rule.
  final Set<String> types;

  /// Whether private (`_`-prefixed) declarations are skipped.
  final bool ignorePrivate;

  /// Whether declarations annotated `@visibleForTesting` are skipped.
  final bool ignoreVisibleForTesting;

  /// A project-specific sentence appended to this group's diagnostics.
  ///
  /// Distinct from the rule-wide `message:` option, which applies to every
  /// diagnostic: with several groups configured, the useful sentence differs
  /// per group ("one bloc per file" vs "one notifier per file").
  final String? message;

  const DeclarationGroup({
    required this.kinds,
    required this.types,
    required this.ignorePrivate,
    required this.ignoreVisibleForTesting,
    required this.message,
  });

  /// Whether this group counts [declaration].
  ///
  /// [element] is the declaration's resolved element, used only for the
  /// [types] narrowing; a declaration that fails to resolve is still counted
  /// by an untyped group, since its kind and name are known from the AST
  /// alone.
  bool counts(CompilationUnitMember declaration, Element? element) {
    final kind = DeclarationKind.of(declaration);
    if (kind == null || !kinds.contains(kind)) return false;

    final name = declarationName(declaration);
    // An unnamed extension cannot be moved to its own file by name and has no
    // identity to report against, so no group counts it.
    if (name == null) return false;

    if (ignorePrivate && name.startsWith('_')) return false;

    if (ignoreVisibleForTesting &&
        declaration.metadata.any((a) => a.name.name == 'visibleForTesting')) {
      return false;
    }

    if (types.isEmpty) return true;
    if (element == null) return false;

    for (final type in types) {
      // No package pin: a configured base type usually lives in the analyzed
      // package and has no `package:` URI to pin against. `isSuperOf` is
      // reflexive, so the base type itself is counted too — correct here, a
      // file declaring `Bloc` plus a subclass holds two blocs.
      if (TypeChecker.fromName(type).isSuperOf(element)) return true;
    }

    return false;
  }
}

/// The name token of [declaration], or `null` when it has none.
///
/// `MixinDeclaration` and `ExtensionDeclaration` expose `.name` directly,
/// while class/enum/extension-type reach it through `.namePart.typeName`.
/// An extension may be genuinely unnamed, hence the nullable result.
String? declarationName(CompilationUnitMember declaration) =>
    declarationNameToken(declaration)?.lexeme;

/// The token to report a diagnostic against, or `null` when there is none.
Token? declarationNameToken(CompilationUnitMember declaration) =>
    switch (declaration) {
      ClassDeclaration() => declaration.namePart.typeName,
      EnumDeclaration() => declaration.namePart.typeName,
      ExtensionTypeDeclaration() => declaration.namePart.typeName,
      MixinDeclaration() => declaration.name,
      ExtensionDeclaration() => declaration.name,
      _ => null,
    };

/// Reads the configured groups from [config].
///
/// Two spellings are accepted, and they are the same feature at two levels of
/// verbosity:
///
/// ```yaml
/// # Flat: one implicit group. The common case.
/// rules:
///   prefer_single_declaration_per_file:
///     types: [Notifier]
///
/// # Grouped: several independent budgets.
/// rules:
///   prefer_single_declaration_per_file:
///     groups:
///       - types: [Bloc, Cubit]
///         message: 'One bloc per file.'
///       - types: [Notifier]
/// ```
///
/// The flat keys are read as a single group so the simple case never has to
/// learn the list syntax, and so the rule with no configuration at all is just
/// the default group. When `groups:` is present the flat keys become that
/// list's defaults, which is what lets `ignore_private: false` be stated once
/// rather than repeated in every group.
///
/// Malformed configuration degrades per entry rather than throwing: a plugin
/// cannot report diagnostics against a YAML file, so a typo costs the user
/// that group and nothing else.
List<DeclarationGroup> readDeclarationGroups(RuleConfig config) {
  final baseKinds = _kinds(config.options['kinds'], DeclarationKind.defaults);
  final baseTypes = _strings(config.options['types']).toSet();
  // Private declarations are invisible outside the file, so they cannot be
  // what forces a reader to open it, and are skipped by default.
  final baseIgnorePrivate = config.boolOption(
    'ignore_private',
    defaultValue: true,
  );
  final baseIgnoreVisibleForTesting = config.boolOption(
    'ignore_visible_for_testing',
    defaultValue: false,
  );

  // The default group, used when no `groups:` are written and as the fallback
  // when every written group is malformed. Its kinds are the recognized
  // defaults rather than `baseKinds`, so a top-level `kinds:` naming nothing
  // valid cannot silence the rule either.
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
    // A group whose `kinds:` are all unrecognized would silently widen back to
    // the defaults and count declarations the project never asked for, so drop
    // it instead.
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

  // Every group being malformed is indistinguishable from none being written,
  // so fall back to the default group rather than silently disabling the rule.
  if (groups.isEmpty) return [defaultGroup()];

  return groups;
}

/// Parses a `kinds:` value, falling back to [defaultValue] when absent.
///
/// An explicit list containing no recognized kind yields an empty set, which
/// callers treat as "drop this group" rather than "use the defaults" — a typo
/// must not quietly widen what a group counts.
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

/// Normalizes a value that may be a single string or a list of strings.
///
/// Accepting a bare scalar (`types: Notifier`) matches how `deny:` behaves on
/// the banned-* family, and removes a recurring "why is my config ignored"
/// confusion.
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
