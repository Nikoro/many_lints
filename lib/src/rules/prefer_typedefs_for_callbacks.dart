import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an inline function type is written where a typedef would name it.
///
/// `void Function(String, int, bool)` at a parameter tells the reader the
/// shape and nothing else — what the `String` is, what the `bool` means, and
/// whether two such parameters are the same concept. A typedef gives the
/// signature a name that can be reused, documented and searched for.
///
/// Only function types with at least `min_parameters` parameters (default 2)
/// are reported: `void Function()` and `void Function(String)` are already
/// readable, and naming them adds indirection without adding information.
/// Flutter's own `VoidCallback` and `ValueChanged<T>` exist for exactly the
/// shapes that clear this bar.
class PreferTypedefsForCallbacks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_typedefs_for_callbacks',
    'This inline function type has {0} parameters.',
    correctionMessage:
        'Give it a typedef, so the signature has a name that can be reused.',
  );

  PreferTypedefsForCallbacks()
    : super(
        name: 'prefer_typedefs_for_callbacks',
        description:
            'Warns when an inline function type would be clearer as a named '
            'typedef.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addGenericFunctionType(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTypedefsForCallbacks rule;

  _Visitor(this.rule);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // A typedef's own body is the named form this rule asks for.
    if (node.parent is GenericTypeAlias) return;

    final minParameters = rule.config.intOption(
      'min_parameters',
      defaultValue: 2,
    );

    final count = node.parameters.parameters.length;
    if (count < minParameters) return;

    rule.reportAtNode(node, arguments: ['$count']);
  }
}
