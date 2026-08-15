import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a boolean is named as though it were a value rather than a
/// question.
///
/// `if (user.admin)` reads as though `admin` might be an object; `if
/// (user.isAdmin)` can only be a yes-or-no. The prefix is what tells a reader
/// at the call site that no further work is needed to get a condition out of
/// it, and it is why `isEmpty`, `hasListeners` and `canPop` read the way they
/// do throughout the SDK.
///
/// Only declarations the project owns are reported: a field, getter, or
/// method returning `bool`. Overrides are skipped, since the name belongs to
/// whoever declared it.
class PreferBooleanPrefixes extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_boolean_prefixes',
    "The boolean '{0}' does not read as a question.",
    correctionMessage:
        "Start the name with a verb such as 'is', 'has' or 'can'.",
  );

  PreferBooleanPrefixes()
    : super(
        name: 'prefer_boolean_prefixes',
        description:
            'Warns when a boolean field, getter or method is not named as a '
            'question, such as isActive or hasItems.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

/// The verbs that turn a name into a question.
///
/// Deliberately a broad list: `should`, `will` and `was` all read
/// as questions and appear throughout Flutter's own API
/// (`shouldRepaint`, `wasFocused`).
const _defaultPrefixes = <String>{
  'is',
  'are',
  'was',
  'were',
  'has',
  'have',
  'had',
  'can',
  'should',
  'will',
  'would',
  'does',
  'do',
  'did',
  'must',
  'needs',
  'allows',
  'contains',
  'supports',
  'enables',
  'requires',
  'wants',
  'shows',
  'hides',
  'accepts',
};

class _Visitor extends SimpleAstVisitor<void> {
  final PreferBooleanPrefixes rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!_isBool(node.fields.type)) return;
    if (_isOverride(node.metadata)) return;

    for (final variable in node.fields.variables) {
      // A private field backing a getter or setter takes its name from that
      // accessor, which the rule judges on its own.
      if (_backsAnAccessor(node, variable.name.lexeme)) continue;
      _report(variable.name);
    }
  }

  /// Whether a private field exists only to store an accessor's value.
  ///
  /// `bool _value` beside `set enabled(...)` is named after the storage, not
  /// after a question; the accessor carries the readable name.
  bool _backsAnAccessor(FieldDeclaration node, String fieldName) {
    if (!fieldName.startsWith('_')) return false;

    final body = node.parent;
    final members = switch (body) {
      BlockClassBody(:final members) => members,
      MixinDeclaration(body: BlockClassBody(:final members)) => members,
      _ => null,
    };
    if (members == null) return false;

    return members.whereType<MethodDeclaration>().any(
      (member) => member.isGetter || member.isSetter,
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // A setter takes a bool, it does not answer a question, and its name is
    // fixed by the getter it pairs with.
    if (node.isSetter) return;
    if (node.isOperator) return;
    if (!_isBool(node.returnType)) return;
    if (_isOverride(node.metadata)) return;

    _report(node.name);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.isSetter) return;
    if (!_isBool(node.returnType)) return;

    _report(node.name);
  }

  void _report(Token name) {
    final identifier = name.lexeme;

    // A private name carries the same information as its public counterpart,
    // so `_isReady` should read the same way once the underscore is dropped.
    final bare = identifier.startsWith('_')
        ? identifier.substring(1)
        : identifier;
    if (bare.isEmpty) return;

    if (_readsAsQuestion(bare)) return;

    rule.reportAtToken(name, arguments: [identifier]);
  }

  /// Whether [name] reads as a yes-or-no question.
  bool _readsAsQuestion(String name) =>
      _hasQuestionVerb(name) || _isThirdPersonVerb(name);

  /// Whether one of the question verbs appears as a whole word.
  ///
  /// The verb does not have to lead: `localeIsDefault` asks the same question
  /// as `isDefaultLocale`, and naming the subject first is a normal way to
  /// keep related settings sorting together.
  ///
  /// Matching is done on the camelCase words rather than on raw substrings,
  /// which is what keeps `island` from counting as `is` and `hasty` from
  /// counting as `has`.
  bool _hasQuestionVerb(String name) =>
      _wordsOf(name).any(_defaultPrefixes.contains);

  /// Splits a camelCase identifier into its lowercased words.
  ///
  /// `localeIsDefault` becomes `[locale, is, default]`.
  Iterable<String> _wordsOf(String name) => name
      .split(RegExp(r'(?=[A-Z])'))
      .map((word) => word.toLowerCase())
      .where((word) => word.isNotEmpty);

  /// Whether the name is a bare third-person verb such as `involves` or
  /// `matches`, which is already a question and needs no prefix.
  ///
  /// Only a single lowercase word qualifies, so `emailSent` is still reported.
  bool _isThirdPersonVerb(String name) =>
      name.endsWith('s') && name.length > 3 && !name.contains(RegExp('[A-Z]'));

  bool _isBool(TypeAnnotation? type) =>
      type is NamedType && type.name.lexeme == 'bool';

  bool _isOverride(NodeList<Annotation> metadata) =>
      metadata.any((annotation) => annotation.name.name == 'override');
}
