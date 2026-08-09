import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an extension declares a member that the extended type already
/// has.
///
/// Extension members are resolved statically and lose to instance members
/// every time. An extension method whose name matches one on the type it
/// extends can therefore never be called through normal syntax — the instance
/// member always wins, silently.
///
/// The result is code that reads as if the extension applies and behaves as if
/// it does not.
///
/// **Bad:**
/// ```dart
/// extension on String {
///   String toUpperCase() => '!'; // never called; String.toUpperCase wins
/// }
/// ```
class AvoidShadowedExtensionMethods extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_shadowed_extension_methods',
    "'{0}' is already declared on '{1}', so this extension member is never "
        'used.',
    correctionMessage:
        'Rename the extension member, since an instance member always takes '
        'precedence over an extension one.',
  );

  AvoidShadowedExtensionMethods()
    : super(
        name: 'avoid_shadowed_extension_methods',
        description:
            'Warns when an extension declares a member that already exists '
            'on the extended type, making it unreachable.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addExtensionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidShadowedExtensionMethods rule;

  _Visitor(this.rule);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final extendedType = node.onClause?.extendedType.type;
    if (extendedType is! InterfaceType) return;

    // An extension's body is a `BlockClassBody`, the same sealed type a class
    // uses — there is no separate extension-body type.
    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      switch (member) {
        case MethodDeclaration(:final name, isStatic: false):
          if (_declaredOn(extendedType, name.lexeme)) {
            rule.reportAtToken(
              name,
              arguments: [name.lexeme, extendedType.getDisplayString()],
            );
          }
        case FieldDeclaration(isStatic: false, :final fields):
          for (final variable in fields.variables) {
            if (_declaredOn(extendedType, variable.name.lexeme)) {
              rule.reportAtToken(
                variable.name,
                arguments: [
                  variable.name.lexeme,
                  extendedType.getDisplayString(),
                ],
              );
            }
          }
        default:
          continue;
      }
    }
  }

  /// Whether [type] or any of its supertypes already declares [name].
  bool _declaredOn(InterfaceType type, String name) {
    if (_hasMember(type.element, name)) return true;

    return type.element.allSupertypes.any(
      (supertype) =>
          !supertype.isDartCoreObject && _hasMember(supertype.element, name),
    );
  }

  bool _hasMember(InterfaceElement element, String name) =>
      element.methods.any((m) => m.name == name) ||
      element.getters.any((g) => g.name == name) ||
      element.setters.any((s) => s.name == name);
}
