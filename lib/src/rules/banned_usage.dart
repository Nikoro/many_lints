import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

/// Warns when a banned member is used.
///
/// Where [avoid_banned_types] bans a whole type, this bans one member of it —
/// the common need being `DateTime.now()` and `Random()` in code that should
/// take an injected clock or seed so it can be tested deterministically.
/// Nothing is banned until you configure it.
///
/// Members are written `Type.member`, matched on the type that *declares* the
/// member, so a subclass cannot slip past: with `Iterable.first` banned, a
/// `List` receiver still reports. A bare `member` name bans it on any type.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   banned_usage:
///     banned:
///       - deny: ['DateTime.now', 'Random.new']
///         in: ['lib/domain/**']
///         message: 'Inject a clock so this stays testable.'
/// ```
///
/// **BAD:**
/// ```dart
/// final at = DateTime.now();  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// final at = clock.now();
/// ```
class BannedUsage extends ManyLintsRule {
  static const LintCode code = LintCode(
    'banned_usage',
    "Use of '{0}' is banned here.{1}",
    correctionMessage: 'Use a permitted member instead.',
  );

  BannedUsage()
    : super(
        name: 'banned_usage',
        description: 'Warns when a banned member is used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    // A `target.member` read parses as PropertyAccess, except when the target
    // is a simple identifier, which parses as PrefixedIdentifier — both shapes
    // are needed or `DateTime.now` as a tear-off is missed.
    registry.addPropertyAccess(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final BannedUsage rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) =>
      _check(node.methodName.element, node.methodName);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // A constructor's member name is its own for a named constructor, and
    // `new` for the unnamed one — so `Random.new` bans the default form.
    _check(node.constructorName.element, node.constructorName);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) =>
      _check(node.propertyName.element, node.propertyName);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _check(node.identifier.element, node.identifier);

  /// Reports [node] when [element] resolves to a banned member.
  void _check(Element? element, AstNode node) {
    if (element == null) return;

    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final memberName = _memberNameOf(element);
    if (memberName == null || memberName.isEmpty) return;

    // Try the qualified form first so a `Type.member` entry is preferred over
    // a bare `member` one when both could match.
    final banned =
        _find(entries, _qualifiedNamesOf(element, memberName)) ??
        _find(entries, [memberName]);
    if (banned == null) return;

    rule.reportAtNode(
      node,
      arguments: [_displayNameOf(element, memberName), messageSuffix(banned)],
    );
  }

  BannedEntry? _find(List<BannedEntry> entries, List<String> candidates) {
    for (final candidate in candidates) {
      final banned = findBannedEntry(
        entries: entries,
        value: candidate,
        relativePath: rule.relativePath,
      );
      if (banned != null) return banned;
    }

    return null;
  }

  /// The member's own name, normalizing the unnamed constructor to `new`.
  String? _memberNameOf(Element element) {
    if (element is ConstructorElement) {
      final name = element.name;
      return name == null || name.isEmpty ? 'new' : name;
    }

    return element.name;
  }

  /// Every `Type.member` spelling that should match [element].
  ///
  /// The declaring type comes first, then its supertypes, so banning
  /// `Iterable.first` also catches a `List` receiver — the member is one
  /// declaration however it is reached.
  List<String> _qualifiedNamesOf(Element element, String memberName) {
    final enclosing = element.enclosingElement;
    if (enclosing is! InterfaceElement) return const [];

    final names = <String>[];
    final ownName = enclosing.name;
    if (ownName != null && ownName.isNotEmpty) {
      names.add('$ownName.$memberName');
    }

    for (final supertype in enclosing.allSupertypes) {
      final name = supertype.element.name;
      if (name == null || name.isEmpty) continue;
      names.add('$name.$memberName');
    }

    return names;
  }

  /// How the member is named in the diagnostic.
  String _displayNameOf(Element element, String memberName) {
    final enclosing = element.enclosingElement;
    if (enclosing is! InterfaceElement) return memberName;

    final ownName = enclosing.name;
    return ownName == null || ownName.isEmpty
        ? memberName
        : '$ownName.$memberName';
  }
}
