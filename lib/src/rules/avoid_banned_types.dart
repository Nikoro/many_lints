import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

/// Warns when a banned type is named in a file.
///
/// Useful for retiring a deprecated model, keeping a platform type out of
/// shared code, or confining a design-system widget to the layer that owns it.
/// Nothing is banned until you configure it.
///
/// Matching is on the type's declared name, so an import prefix or type
/// arguments do not hide a usage: `p.LegacyUser` and `List<LegacyUser>` both
/// match `LegacyUser`. Qualify with `package:` when a bare name is ambiguous.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   avoid_banned_types:
///     banned:
///       - deny: ['LegacyUser']
///         message: 'Use User instead; LegacyUser is removed in v3.'
///       - deny: ['Scaffold']
///         in: ['lib/design_system/atoms/**']
///         message: 'Atoms must not depend on page-level layout.'
/// ```
///
/// **BAD:**
/// ```dart
/// void f(LegacyUser user) {}  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// void f(User user) {}
/// ```
class AvoidBannedTypes extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_types',
    "The type '{0}' is banned here.{1}",
    correctionMessage: 'Use a permitted type instead.',
  );

  AvoidBannedTypes()
    : super(
        name: 'avoid_banned_types',
        description: 'Warns when a banned type is named in a file.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    // `NamedType` covers every written type annotation — parameters, fields,
    // return types, type arguments, `extends`/`implements`, and the type of a
    // constructor call — so one callback catches every place a type is named.
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedTypes rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final element = node.element;
    if (element == null) return;

    // The declared name, not the written one, so an import prefix cannot
    // smuggle a banned type past the rule.
    final typeName = element.name;
    if (typeName == null || typeName.isEmpty) return;

    final banned = _findBanned(entries, element, typeName);
    if (banned == null) return;

    // Report at the name token only: highlighting type arguments too would
    // span code that is not itself banned.
    rule.reportAtToken(node.name, arguments: [typeName, messageSuffix(banned)]);
  }

  /// Finds an entry banning [typeName], accepting either the bare name or a
  /// `package:uri#Name` qualified form.
  ///
  /// The qualified form disambiguates a common name that several packages
  /// declare — banning `Border` from Flutter should not also ban a local
  /// `Border`.
  BannedEntry? _findBanned(
    List<BannedEntry> entries,
    Element element,
    String typeName,
  ) {
    final byName = findBannedEntry(
      entries: entries,
      value: typeName,
      relativePath: rule.relativePath,
    );
    if (byName != null) return byName;

    final uri = element.library?.identifier;
    if (uri == null) return null;

    return findBannedEntry(
      entries: entries,
      value: '$uri#$typeName',
      relativePath: rule.relativePath,
    );
  }
}
