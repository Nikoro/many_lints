import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferCorrectCallbackFieldName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_callback_field_name',
    "The callback '{0}' should be named 'on...'.",
    correctionMessage:
        "Rename it to start with 'on', such as onTap or onChanged.",
  );

  PreferCorrectCallbackFieldName()
    : super(
        name: 'prefer_correct_callback_field_name',
        description:
            'Warns when a callback field or parameter is not named with the '
            'on... prefix Flutter uses throughout its API.',
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
    registry.addRegularFormalParameter(this, visitor);
  }
}

const _callbackSuffixes = <String>['callback', 'handler', 'listener', 'action'];

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectCallbackFieldName rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!_isCallbackType(node.fields.type)) return;
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    for (final variable in node.fields.variables) {
      _check(variable.name);
    }
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    // Edge case: `this.onTap` is named by its field, which is already reported
    if (node is FieldFormalParameter) return;
    if (node is SuperFormalParameter) return;

    final element = node.declaredFragment?.element;
    if (element == null || element.type is! FunctionType) return;

    if (node.name case final name?) _check(name);
  }

  void _check(Token name) {
    final identifier = name.lexeme;
    final bare = identifier.startsWith('_')
        ? identifier.substring(1)
        : identifier;
    if (bare.isEmpty) return;

    if (_readsAsEvent(bare)) return;

    if (!_looksLikeACallback(bare)) return;

    rule.reportAtToken(name, arguments: [identifier]);
  }

  bool _readsAsEvent(String name) =>
      name.length > 2 && name.startsWith('on') && _beginsWord(name[2]);

  bool _looksLikeACallback(String name) {
    final lower = name.toLowerCase();

    return _callbackSuffixes.any(
      (suffix) => lower.endsWith(suffix) && lower.length > suffix.length,
    );
  }

  bool _isCallbackType(TypeAnnotation? type) {
    if (type is GenericFunctionType) return true;

    final resolved = type?.type;
    return resolved is FunctionType;
  }

  bool _beginsWord(String character) =>
      character == character.toUpperCase() &&
      character != character.toLowerCase();
}
