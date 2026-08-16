import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function-typed parameter or typedef declares unnamed
/// parameters.
///
/// `void Function(String, int)` tells a reader the types and nothing else. At
/// the point where someone writes the callback, `(String, int)` gives them two
/// anonymous values to guess at — is the `int` an index, a count, an id?
/// `void Function(String label, int count)` answers that in the signature,
/// where the answer belongs, and IDEs echo those names into the closure they
/// generate.
///
/// A single-parameter function type is exempt by default: `void Function(T)`
/// is unambiguous from the type alone, and naming it adds nothing. Set
/// `min_parameters: 1` to report those too.
class PreferExplicitParameterNames extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_explicit_parameter_names',
    'This function type declares unnamed parameters.',
    correctionMessage: 'Name them, so a caller knows what to pass.',
  );

  PreferExplicitParameterNames()
    : super(
        name: 'prefer_explicit_parameter_names',
        description: 'Warns when a function type declares unnamed parameters.',
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
  final PreferExplicitParameterNames rule;

  _Visitor(this.rule);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    final minParameters = rule.config.intOption(
      'min_parameters',
      defaultValue: 2,
    );

    final parameters = node.parameters.parameters;
    if (parameters.length < minParameters) return;

    // A parameter with no name has an empty one rather than a null one, so the
    // emptiness of the token is the test.
    final unnamed = parameters.where((p) => p.name?.lexeme.isEmpty ?? true);
    if (unnamed.isEmpty) return;

    rule.reportAtNode(node.parameters);
  }
}
