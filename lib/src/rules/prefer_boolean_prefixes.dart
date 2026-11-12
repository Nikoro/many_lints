import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
      if (_backsAnAccessor(node, variable.name.lexeme)) continue;
      _report(variable.name);
    }
  }

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

    final bare = identifier.startsWith('_')
        ? identifier.substring(1)
        : identifier;
    if (bare.isEmpty) return;

    if (_readsAsQuestion(bare)) return;

    rule.reportAtToken(name, arguments: [identifier]);
  }

  bool _readsAsQuestion(String name) =>
      _hasQuestionVerb(name) || _isThirdPersonVerb(name);

  bool _hasQuestionVerb(String name) =>
      _wordsOf(name).any(_defaultPrefixes.contains);

  Iterable<String> _wordsOf(String name) => name
      .split(RegExp(r'(?=[A-Z])'))
      .map((word) => word.toLowerCase())
      .where((word) => word.isNotEmpty);

  bool _isThirdPersonVerb(String name) =>
      name.endsWith('s') && name.length > 3 && !name.contains(RegExp('[A-Z]'));

  bool _isBool(TypeAnnotation? type) =>
      type is NamedType && type.name.lexeme == 'bool';

  bool _isOverride(NodeList<Annotation> metadata) =>
      metadata.any((annotation) => annotation.name.name == 'override');
}
