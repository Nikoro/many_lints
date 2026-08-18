import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a throw does not name a type a caller could catch selectively.
///
/// A bare `Exception('upload failed')` cannot be caught by kind. Every
/// `catch` downstream either swallows everything or re-inspects the message
/// string, and message matching breaks the moment somebody improves the
/// wording — a silent break, since the `catch` still compiles and still runs.
///
/// This is concrete for anything that maps failures onto behaviour: a CLI
/// choosing an exit code, a client deciding whether to retry, a UI choosing
/// between "check your connection" and "that file is not valid". None of those
/// questions can be answered about a value whose only distinguishing feature
/// is prose.
///
/// The SDK's `only_throw_errors` covers the adjacent case — throwing a value
/// that is neither `Error` nor `Exception`, like a bare string — but it is
/// satisfied by `Exception(...)`, which is where most of the real damage is.
/// This rule covers both, so enabling it alone is sufficient.
///
/// A handful of SDK types are allowed by default because their type already
/// says what went wrong: [ArgumentError] and friends are as specific as a
/// hand-written class would be. `allow` replaces that list.
///
/// **BAD:**
/// ```dart
/// throw Exception('upload failed');   // LINT — nothing can catch just this
/// throw 'upload failed';              // LINT — not even an Exception
/// ```
///
/// **GOOD:**
/// ```dart
/// throw const UploadFailure('upload failed');
/// throw ArgumentError.value(port, 'port', 'must be positive');
/// ```
class PreferTypedExceptions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_typed_exceptions',
    "Throwing '{0}' gives callers nothing to catch selectively.",
    correctionMessage:
        'Throw a named type so callers can catch this failure and no other.',
  );

  PreferTypedExceptions()
    : super(
        name: 'prefer_typed_exceptions',
        description:
            'Warns when a throw does not name a type a caller could catch '
            'selectively.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// SDK types whose own name already identifies the failure.
  ///
  /// Each of these is as catchable as a hand-written class, so demanding a
  /// wrapper around them would add a type without adding information.
  static const _defaultAllow = {
    'ArgumentError',
    'AssertionError',
    'ConcurrentModificationError',
    'FormatException',
    'IndexError',
    'RangeError',
    'StateError',
    'UnimplementedError',
    'UnsupportedError',
  };

  /// The types that carry no information beyond their message.
  static const _untypedThrows = {'Exception', 'Error'};

  final PreferTypedExceptions rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    // `rethrow` is its own node, so anything reaching here is a value being
    // thrown for the first time.
    final type = node.expression.staticType;
    if (type == null || type is DynamicType) return;

    final element = type.element;
    if (element is! InterfaceElement) {
      rule.reportAtNode(node, arguments: [type.getDisplayString()]);
      return;
    }

    final name = element.name;
    // A type declared by the project is as specific as it chose to be, and
    // naming it is exactly what this rule asks for.
    if (!element.library.isDartCore) {
      if (!_isThrowable(element)) {
        rule.reportAtNode(node, arguments: [type.getDisplayString()]);
      }
      return;
    }

    // Everything below is an SDK type, where the question is whether its own
    // name identifies the failure. `allow` is the list of those that do; the
    // rest — `Exception`, `Error`, and non-throwables like `String` — leave
    // the caller nothing to catch by.
    final allow = rule.config.nameSetOption(
      'allow',
      defaultValue: _defaultAllow,
    );
    if (name != null && allow.contains(name)) return;

    rule.reportAtNode(node, arguments: [name ?? type.getDisplayString()]);
  }

  /// Whether [element] is, or implements, `Error` or `Exception`.
  bool _isThrowable(InterfaceElement element) {
    if (_isCoreThrowable(element)) return true;

    return element.allSupertypes.any(
      (supertype) => _isCoreThrowable(supertype.element),
    );
  }

  bool _isCoreThrowable(InterfaceElement element) =>
      element.library.isDartCore && _untypedThrows.contains(element.name);
}
