// Ported from riverpod_lint (MIT, Copyright (c) 2023 Remi Rousselet).
// See the NOTICE file at the repository root.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

/// Warns when a `Notifier`'s protected properties are accessed from outside
/// the notifier itself.
///
/// `state`, `stateOrNull`, `future` and `ref` are part of a notifier's
/// internal API. Reading or writing them from elsewhere couples callers to the
/// notifier's implementation and bypasses the provider system.
///
/// **BAD:**
/// ```dart
/// void fn(MyNotifier notifier) {
///   print(notifier.state); // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void fn(WidgetRef ref) {
///   print(ref.watch(myProvider));
/// }
/// ```
class ProtectedNotifierProperties extends ManyLintsRule {
  static const LintCode code = LintCode(
    'protected_notifier_properties',
    "The property '{0}' should not be used outside of the Notifier itself.",
    correctionMessage:
        'Try reading the value through its provider instead of the notifier.',
  );

  ProtectedNotifierProperties()
    : super(
        name: 'protected_notifier_properties',
        description:
            "Warns when a Notifier's protected properties are accessed from "
            'outside the notifier itself.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPropertyAccess(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
  }
}

/// Members that only the notifier itself should touch.
const _protectedProperties = {'state', 'stateOrNull', 'future', 'ref'};

class _Visitor extends SimpleAstVisitor<void> {
  final ProtectedNotifierProperties rule;

  _Visitor(this.rule);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _check(node, node.target?.staticType, node.propertyName);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // `notifier.state` parses as a prefixed identifier when the target is a
    // simple identifier, which is the common case.
    _check(node, node.prefix.staticType, node.identifier);
  }

  void _check(
    Expression node,
    DartType? targetType,
    SimpleIdentifier property,
  ) {
    if (!_protectedProperties.contains(property.name)) return;
    if (targetType == null) return;

    // Only notifiers have these protected members.
    if (!notifierChecker.isAssignableFromType(targetType)) return;

    // Accessing them from inside the notifier itself is the intended use.
    final enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    final enclosingElement = enclosingClass?.declaredFragment?.element;
    if (enclosingElement != null && targetType == enclosingElement.thisType) {
      return;
    }

    rule.reportAtNode(property, arguments: [property.name]);
  }
}
