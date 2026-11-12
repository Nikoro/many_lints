import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';
import '../rule_config.dart';

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
    registry.addSimpleIdentifier(this, visitor);
    // Edge case: the unnamed constructor has no identifier of its own, as in `Random()` or `super()`
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
      ConstructorName() ||
      DotShorthandConstructorInvocation() ||
      SuperConstructorInvocation() ||
      RedirectingConstructorInvocation() => null,
      Combinator() => null,
      _ => _writtenElement(node) ?? node.element,
    };
    _check(element, node);
  }

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

  void _check(Element? element, AstNode node) {
    if (element == null || !_isMember(element)) return;

    final entries = _entriesFor(rule.config);
    if (entries.isEmpty) return;

    final memberName = _memberNameOf(element);
    if (memberName == null || memberName.isEmpty) return;

    // Edge case: library spellings skip deny_pattern, so patterns written before them keep their reach
    final banned =
        _find(
          entries,
          _libraryQualifiedNamesOf(element, memberName),
          matchPatterns: false,
        ) ??
        _find(entries, _qualifiedNamesOf(element, memberName)) ??
        _find(entries, [memberName]);
    if (banned == null) return;

    final isDocReference =
        node.thisOrAncestorOfType<CommentReference>() != null;
    if (isDocReference) return;

    rule.reportAtNode(
      node,
      arguments: [_displayNameOf(element, memberName), messageSuffix(banned)],
    );
  }

  List<BannedEntry> _entriesFor(RuleConfig config) {
    if (!identical(config, _entriesConfig)) {
      _entriesConfig = config;
      _entries = readBannedEntries(config);
    }
    return _entries;
  }

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
    bool matchPatterns = true,
  }) {
    for (final candidate in candidates) {
      final banned = findBannedEntry(
        entries: entries,
        value: candidate,
        relativePath: rule.relativePath,
        patterns: matchPatterns,
      );
      if (banned != null) return banned;
    }

    return null;
  }

  String? _memberNameOf(Element element) {
    if (element is ConstructorElement) {
      final name = element.name;
      return name == null || name.isEmpty ? 'new' : name;
    }

    return element.name;
  }

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

  bool _isInherited(Element element) => switch (element) {
    ConstructorElement() => false,
    ExecutableElement(:final isStatic) => !isStatic,
    PropertyInducingElement(:final isStatic) => !isStatic,
    _ => false,
  };

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

  String _displayNameOf(Element element, String memberName) {
    final enclosing = element.enclosingElement;
    if (enclosing is! InstanceElement) return memberName;

    final ownName = enclosing.name;
    return ownName == null || ownName.isEmpty
        ? memberName
        : '$ownName.$memberName';
  }
}
