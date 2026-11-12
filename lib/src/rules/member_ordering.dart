import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

class MemberOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'member_ordering',
    "A {0} should come before the {1} above it.",
    correctionMessage: 'Move it up to keep the class in the configured order.',
  );

  MemberOrdering()
    : super(
        name: 'member_ordering',
        description:
            'Warns when class members are declared out of the configured '
            'order, such as a field after a method.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionDeclaration(this, visitor);
  }
}

const _knownCategories = <String>{
  'public_static_fields',
  'private_static_fields',
  'public_fields',
  'private_fields',
  'constructors',
  'named_constructors',
  'factory_constructors',
  'public_getters',
  'private_getters',
  'public_setters',
  'private_setters',
  'public_methods',
  'private_methods',
  'static_methods',
  'overridden_methods',
  'build_method',
};

const _defaultOrder = <String>[
  'public_static_fields',
  'private_static_fields',
  'constructors',
  'named_constructors',
  'factory_constructors',
  'public_fields',
  'private_fields',
  'public_getters',
  'private_getters',
  'public_setters',
  'private_setters',
  'public_methods',
  'private_methods',
  'build_method',
];

class _Visitor extends SimpleAstVisitor<void> {
  final MemberOrdering rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    _reportMisplacedBodyMembers(
      node.body,
      buildBelongsLast: element != null && widgetChecker.isSuperOf(element),
    );
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _reportMisplacedBodyMembers(node.body);

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _reportMisplacedMembers(node.body.members, buildBelongsLast: false);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) =>
      _reportMisplacedBodyMembers(node.body);

  void _reportMisplacedBodyMembers(
    ClassBody body, {
    bool buildBelongsLast = false,
  }) {
    if (body is BlockClassBody) {
      _reportMisplacedMembers(body.members, buildBelongsLast: buildBelongsLast);
    }
  }

  void _reportMisplacedMembers(
    List<ClassMember> members, {
    required bool buildBelongsLast,
  }) {
    final order = rule.config.stringListOption(
      'order',
      defaultValue: _defaultOrder,
    );

    final ranks = <String, int>{};
    for (final (index, category) in order.indexed) {
      if (_knownCategories.contains(category)) {
        ranks[category] = index;
      }
    }
    if (ranks.isEmpty) return;

    int? highestRank;
    String? highestCategory;

    for (final member in members) {
      final category = _categoryOf(
        member,
        ranks.keys.toSet(),
        buildBelongsLast: buildBelongsLast,
      );
      if (category == null) continue;

      final rank = ranks[category]!;

      if (highestRank != null && rank < highestRank) {
        rule.reportAtNode(
          member,
          arguments: [
            _singularLabel(category),
            _singularLabel(highestCategory!),
          ],
        );
        // Edge case: the mark stays, so one misplaced member does not silence the ones after it
        continue;
      }

      highestRank = rank;
      highestCategory = category;
    }
  }

  String? _categoryOf(
    ClassMember member,
    Set<String> configured, {
    required bool buildBelongsLast,
  }) {
    for (final candidate in _candidatesFor(
      member,
      buildBelongsLast: buildBelongsLast,
    )) {
      if (configured.contains(candidate)) return candidate;
    }
    return null;
  }

  Iterable<String> _candidatesFor(
    ClassMember member, {
    required bool buildBelongsLast,
  }) sync* {
    switch (member) {
      case FieldDeclaration(:final isStatic, :final fields):
        final isPrivate = fields.variables.any(
          (variable) => variable.name.lexeme.startsWith('_'),
        );
        if (isStatic) {
          yield isPrivate ? 'private_static_fields' : 'public_static_fields';
        }
        yield isPrivate ? 'private_fields' : 'public_fields';

      case ConstructorDeclaration(:final factoryKeyword, :final name):
        if (factoryKeyword != null) yield 'factory_constructors';
        if (name != null) yield 'named_constructors';
        yield 'constructors';

      case MethodDeclaration(:final name, :final isStatic, :final isGetter):
        final identifier = name.lexeme;
        final isPrivate = identifier.startsWith('_');

        if (_isEqualityMember(identifier) || member.isOperator) return;

        if (buildBelongsLast && identifier == 'build') yield 'build_method';
        if (member.metadata.any((a) => a.name.name == 'override')) {
          yield 'overridden_methods';
        }
        if (isStatic) yield 'static_methods';

        if (isGetter) {
          yield isPrivate ? 'private_getters' : 'public_getters';
        } else if (member.isSetter) {
          yield isPrivate ? 'private_setters' : 'public_setters';
        } else {
          yield isPrivate ? 'private_methods' : 'public_methods';
        }

      case PrimaryConstructorBody():
        break;
    }
  }

  bool _isEqualityMember(String name) =>
      name == '==' || name == 'hashCode' || name == 'toString';

  String _singularLabel(String category) {
    final words = category.replaceAll('_', ' ');
    return words.endsWith('s') ? words.substring(0, words.length - 1) : words;
  }
}
