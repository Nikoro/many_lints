import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';
import '../rule_config.dart';

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
/// Prefixing the declaring library, `package:uri#name` or
/// `package:uri#Type.member` as in `avoid_banned_types`, bans one library's
/// declaration only, which is the way to ban a top-level function or variable
/// without also banning every member that shares its name.
///
/// Each entry may carve paths back out with `except:`, lifting that entry
/// alone where the rule-wide `exclude:` would lift them all.
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
///       - deny: ['package:app/core/clock.dart#systemClock']
///         in: ['lib/**']
///         except: ['lib/core/clock.dart', 'lib/main.dart']
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
    // Every reference to a method, getter, setter or static member names it
    // with a SimpleIdentifier: a call, a tear-off, a read, a write, a dot
    // shorthand, or an unqualified use inside the declaring class. Visiting
    // the identifier rather than each enclosing node keeps one report per
    // reference however the expression is shaped.
    registry.addSimpleIdentifier(this, visitor);
    // Constructors are the exception: the unnamed one has no identifier of its
    // own (`Random()`, `super()`), so they are visited through the nodes that
    // carry their element. ConstructorName covers creation, tear-offs
    // (`DateTime.now` as a value, `Random.new`) and redirecting factories.
    registry.addConstructorName(this, visitor);
    registry.addDotShorthandConstructorInvocation(this, visitor);
    registry.addSuperConstructorInvocation(this, visitor);
    registry.addRedirectingConstructorInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final BannedUsage rule;

  _Visitor(this.rule);

  RuleConfig? _entriesConfig;
  List<BannedEntry> _entries = const [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = switch (node.parent) {
      // Constructor names are reported by the constructor visitors below.
      ConstructorName() ||
      DotShorthandConstructorInvocation() ||
      SuperConstructorInvocation() ||
      RedirectingConstructorInvocation() => null,
      // `show x` and `hide x` name a member without using it.
      Combinator() => null,
      _ => _writtenElement(node) ?? node.element,
    };
    _check(element, node);
  }

  /// The setter [node] writes through, when it is the target of `=`, `+=`,
  /// `++` and the like.
  ///
  /// A written identifier has no element of its own; the setter is recorded
  /// on the enclosing assignment.
  Element? _writtenElement(SimpleIdentifier node) {
    final parent = node.parent;
    final target = switch (parent) {
      PrefixedIdentifier(:final identifier) when identifier == node => parent,
      PropertyAccess(:final propertyName) when propertyName == node => parent,
      _ => node,
    };

    return switch (target.parent) {
      AssignmentExpression(:final leftHandSide, :final writeElement)
          when leftHandSide == target =>
        writeElement,
      PrefixExpression(:final operand, :final writeElement)
          when operand == target =>
        writeElement,
      PostfixExpression(:final operand, :final writeElement)
          when operand == target =>
        writeElement,
      _ => null,
    };
  }

  @override
  void visitConstructorName(ConstructorName node) => _check(node.element, node);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _check(node.element, node.constructorName);

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      _check(node.element, node.constructorName ?? node);

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) => _check(node.element, node.constructorName ?? node);

  /// Reports [node] when [element] resolves to a banned member.
  void _check(Element? element, AstNode node) {
    if (element == null || !_isMember(element)) return;

    final entries = _entriesFor(rule.config);
    if (entries.isEmpty) return;

    final memberName = _memberNameOf(element);
    if (memberName == null || memberName.isEmpty) return;

    // Most specific first, so an entry naming the library is preferred over a
    // `Type.member` one, and that over a bare `member` one. Library spellings
    // match `deny:` only: a `deny_pattern:` written before they existed must
    // not start matching them.
    final banned =
        _find(
          entries,
          _libraryQualifiedNamesOf(element, memberName),
          patterns: false,
        ) ??
        _find(entries, _qualifiedNamesOf(element, memberName)) ??
        _find(entries, [memberName]);
    if (banned == null) return;

    // A `[DateTime.now]` doc reference names the member without using it.
    if (node.thisOrAncestorOfType<CommentReference>() != null) return;

    rule.reportAtNode(
      node,
      arguments: [_displayNameOf(element, memberName), messageSuffix(banned)],
    );
  }

  /// The entries for [config], parsed once per file rather than once per
  /// identifier.
  List<BannedEntry> _entriesFor(RuleConfig config) {
    if (!identical(config, _entriesConfig)) {
      _entriesConfig = config;
      _entries = readBannedEntries(config);
    }
    return _entries;
  }

  /// Whether [element] is a member of a type or extension, or a top-level
  /// function or variable.
  ///
  /// Locals, parameters, local functions, types and import prefixes share
  /// names with members (`now`, `random`) but are declared in the file being
  /// read; banning those is `avoid_banned_names`' job.
  bool _isMember(Element element) => switch (element) {
    ConstructorElement() => true,
    ExecutableElement(:final enclosingElement) ||
    PropertyInducingElement(:final enclosingElement) =>
      enclosingElement is InstanceElement || enclosingElement is LibraryElement,
    _ => false,
  };

  BannedEntry? _find(
    List<BannedEntry> entries,
    List<String> candidates, {
    bool patterns = true,
  }) {
    for (final candidate in candidates) {
      final banned = findBannedEntry(
        entries: entries,
        value: candidate,
        relativePath: rule.relativePath,
        patterns: patterns,
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
  /// The declaring type comes first, then, for an instance member, its
  /// supertypes, so banning `Iterable.first` also catches a `List` receiver —
  /// the member is one declaration however it is reached. Constructors and
  /// static members are not inherited, so `Random.new` never matches a
  /// subtype's constructor. An extension member is qualified by
  /// the extension's name.
  List<String> _qualifiedNamesOf(Element element, String memberName) {
    final enclosing = element.enclosingElement;
    if (enclosing is! InstanceElement) return const [];

    final names = <String>[];
    final ownName = enclosing.name;
    if (ownName != null && ownName.isNotEmpty) {
      names.add('$ownName.$memberName');
    }
    if (enclosing is! InterfaceElement || !_isInherited(element)) return names;

    for (final supertype in enclosing.allSupertypes) {
      final name = supertype.element.name;
      if (name == null || name.isEmpty) continue;
      names.add('$name.$memberName');
    }

    return names;
  }

  /// Whether [element] is an instance member, the only kind a subtype
  /// inherits: a constructor or static member belongs to its own type alone.
  bool _isInherited(Element element) => switch (element) {
    ConstructorElement() => false,
    ExecutableElement(:final isStatic) => !isStatic,
    PropertyInducingElement(:final isStatic) => !isStatic,
    _ => false,
  };

  /// Every `uri#name` spelling that should match [element]: the declaring
  /// library's URI before a top-level name, or before each `Type.member` of
  /// [_qualifiedNamesOf] with the library declaring that type.
  ///
  /// The `#` separator is the one `avoid_banned_types` already reads, so a
  /// project pins a library the same way in both rules.
  List<String> _libraryQualifiedNamesOf(Element element, String memberName) {
    final enclosing = element.enclosingElement;
    if (enclosing is LibraryElement) {
      return ['${enclosing.identifier}#$memberName'];
    }
    if (enclosing is! InstanceElement) return const [];

    final names = <String>[];
    final ownName = enclosing.name;
    if (ownName != null && ownName.isNotEmpty) {
      names.add('${enclosing.library.identifier}#$ownName.$memberName');
    }
    if (enclosing is! InterfaceElement || !_isInherited(element)) return names;

    for (final supertype in enclosing.allSupertypes) {
      final type = supertype.element;
      final name = type.name;
      if (name == null || name.isEmpty) continue;
      names.add('${type.library.identifier}#$name.$memberName');
    }

    return names;
  }

  /// How the member is named in the diagnostic.
  String _displayNameOf(Element element, String memberName) {
    final enclosing = element.enclosingElement;
    if (enclosing is! InstanceElement) return memberName;

    final ownName = enclosing.name;
    return ownName == null || ownName.isEmpty
        ? memberName
        : '$ownName.$memberName';
  }
}
