import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a class member appears before one that should come earlier.
///
/// A class read top to bottom should answer the same questions in the same
/// sequence every time: how it is built, what it holds, what it can do. When
/// the order varies between files, finding a field means scanning the whole
/// class rather than glancing at the top of it, and a diff that adds a method
/// lands in whichever spot happened to be free.
///
/// The order is entirely configurable through `order:`, because the right one
/// is a house style rather than a fact — which is also why this rule only
/// appears in the `pedantic` preset. Against a production Flutter app already
/// following a consistent style it still reported 227 members, every one a
/// real deviation and none of them a bug.
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

/// The member categories a project can order, most specific first.
///
/// Matching walks this list in order and takes the first category that
/// applies, so `public_fields` never swallows a `static_fields`.
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

/// Constructor first, then state, then behaviour.
///
/// The constructor leads because that is how modern Dart and Flutter code is
/// written: `flutter create`, the framework's own widgets, and every sample
/// in the Flutter docs put the constructor at the top, directly under the
/// class header, with the `final` fields it initialises below it. Ordering
/// fields first is the older Java-influenced convention, and a rule shipping
/// it as the default reports most of a modern codebase on day one — measured
/// at 615 of 1091 diagnostics on one production Flutter app.
///
/// Statics lead the constructor because they are not per-instance state and
/// are usually a handful of constants read as part of the class header.
///
/// `build_method` sits last so a Flutter widget's `build` stays at the bottom,
/// which is where the framework's own samples put it.
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
    _checkBody(
      node.body,
      // Only a widget's `build` renders and belongs at the bottom. A Riverpod
      // `Notifier.build` is the state initialiser and idiomatically comes
      // first, so treating it as a widget's would report every helper below it.
      buildBelongsLast: element != null && widgetChecker.isSuperOf(element),
    );
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) => _checkBody(node.body);

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _check(node.body.members, buildBelongsLast: false);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) =>
      _checkBody(node.body);

  /// Only a `BlockClassBody` carries members; `EmptyClassBody` is `;`.
  void _checkBody(ClassBody body, {bool buildBelongsLast = false}) {
    if (body is BlockClassBody) {
      _check(body.members, buildBelongsLast: buildBelongsLast);
    }
  }

  void _check(List<ClassMember> members, {required bool buildBelongsLast}) {
    final order = rule.config.stringListOption(
      'order',
      defaultValue: _defaultOrder,
    );

    // An unknown name would silently order nothing, which reads as the rule
    // being broken. Drop it here rather than matching against it forever.
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
          arguments: [_readable(category), _readable(highestCategory!)],
        );
        // Do not update the high-water mark: one misplaced member should not
        // silence every correctly-placed member after it.
        continue;
      }

      highestRank = rank;
      highestCategory = category;
    }
  }

  /// The first configured category this member belongs to.
  ///
  /// A member whose category the project left out of `order:` is unordered by
  /// definition, so it is skipped rather than forced somewhere.
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

  /// Every category that describes this member, most specific first.
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

        // `==`, `hashCode` and `toString` are written as one block, and Dart
        // forces `hashCode` to be a getter while `==` is an operator — so any
        // order that separates getters from methods would split a trio that
        // belongs together. Operators are unordered for the same reason.
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

      // A primary constructor's body is part of the class header, not a
      // member that can be moved, so it has no place in the order.
      case PrimaryConstructorBody():
        break;
    }
  }

  /// Whether this member belongs to the `==` / `hashCode` / `toString` trio.
  bool _isEqualityMember(String name) =>
      name == '==' || name == 'hashCode' || name == 'toString';

  /// Turns `public_static_fields` into `public static field` for the message.
  String _readable(String category) {
    final words = category.replaceAll('_', ' ');
    return words.endsWith('s') ? words.substring(0, words.length - 1) : words;
  }
}
