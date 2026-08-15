import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a callback field or parameter is not named `onSomething`.
///
/// `onTap`, `onChanged` and `onPressed` run through the whole Flutter API, so
/// `on...` is what a reader recognises as "this fires when something happens".
/// A field called `tapCallback` or `submitHandler` carries the same meaning in
/// a spelling every codebase invents differently, and at the call site
/// `MyWidget(tapCallback: ...)` reads as a value where `onTap:` reads as an
/// event.
///
/// Only fields and parameters whose type is a function are considered.
/// Overrides are skipped, since the name belongs to whoever declared it.
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

/// Names that describe a callback without saying when it fires.
///
/// A field carrying one of these is the case the rule exists for: it is
/// clearly a callback, and clearly not named as an event.
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
    // A field-initialising parameter (`this.onTap`) takes its name from the
    // field, which is checked above; reporting both would double up.
    if (node is FieldFormalParameter) return;
    if (node is SuperFormalParameter) return;

    // The resolved type covers every spelling at once: an inline
    // `void Function()`, a named typedef, and an inferred type.
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

    // Only report a name that positively looks like a callback. A function
    // field named `builder`, `comparator` or `parse` describes what it
    // computes rather than when it fires, and renaming it to `on...` would be
    // wrong.
    if (!_looksLikeACallback(bare)) return;

    rule.reportAtToken(name, arguments: [identifier]);
  }

  /// Whether the name already announces an event, as `onTap` does.
  bool _readsAsEvent(String name) =>
      name.length > 2 && name.startsWith('on') && _beginsWord(name[2]);

  /// Whether the name ends in a word that means "a callback".
  ///
  /// The suffix must follow something. A parameter named exactly `handler`,
  /// `listener` or `action` is the thing itself rather than a callback for an
  /// event — `Handler middleware(Handler handler)` in dart_frog is the request
  /// handler, and `onHandler` would be nonsense.
  bool _looksLikeACallback(String name) {
    final lower = name.toLowerCase();

    return _callbackSuffixes.any(
      (suffix) => lower.endsWith(suffix) && lower.length > suffix.length,
    );
  }

  /// Whether this type annotation denotes a function.
  ///
  /// Covers both spellings: an inline `void Function()` and a named typedef
  /// resolving to a function type.
  bool _isCallbackType(TypeAnnotation? type) {
    if (type is GenericFunctionType) return true;

    final resolved = type?.type;
    return resolved is FunctionType;
  }

  bool _beginsWord(String character) =>
      character == character.toUpperCase() &&
      character != character.toLowerCase();
}
