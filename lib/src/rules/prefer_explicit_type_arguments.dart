import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a generic call this project cannot see through is written
/// without explicit type arguments.
///
/// Inference is usually right and usually invisible, which is exactly the
/// problem for a handful of APIs: `showDialog(...)` infers its return type
/// from the builder's `Navigator.pop(value)`, so a `pop()` with no argument
/// silently makes it `Future<Null>` and the `await` at the call site yields a
/// null the code did not plan for. Writing `showDialog<bool>(...)` moves that
/// decision into the signature, where a mismatch is a compile error.
///
/// **This rule reports nothing until configured**, because the set of APIs
/// worth pinning is a house style — for most generic calls inference is
/// correct and explicit arguments are noise:
///
/// ```yaml
/// rules:
///   prefer_explicit_type_arguments:
///     methods: [showDialog, showModalBottomSheet, push, pushNamed]
/// ```
class PreferExplicitTypeArguments extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_explicit_type_arguments',
    "The call to '{0}' has no explicit type arguments.",
    correctionMessage:
        'Write them, so inference cannot pick a surprising type.',
  );

  PreferExplicitTypeArguments()
    : super(
        name: 'prefer_explicit_type_arguments',
        description:
            'Warns when a configured generic call omits its type arguments.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExplicitTypeArguments rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Silent until the project names the APIs it wants pinned: for most
    // generic calls inference is right and explicit arguments are noise.
    final methods = rule.config.nameSetOption(
      'methods',
      defaultValue: const {},
    );
    if (methods.isEmpty) return;

    final name = node.methodName.name;
    if (!methods.contains(name)) return;
    if (node.typeArguments != null) return;

    // A call that resolves to no type parameters cannot take arguments, so
    // asking for them would be asking for a compile error.
    final element = node.methodName.element;
    if (element is! ExecutableElement) return;
    if (element.typeParameters.isEmpty) return;

    rule.reportAtNode(node.methodName, arguments: [name]);
  }
}
