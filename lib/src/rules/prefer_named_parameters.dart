import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a declaration takes more than a few positional parameters.
///
/// `move(3, 4, 5, 6)` tells the reader nothing, and swapping two arguments of
/// the same type compiles cleanly and fails at runtime. Named parameters put
/// the meaning at the call site, where it is read.
///
/// The threshold matters more than the principle: one or two positional
/// parameters are usually the subject of the call (`substring(0, 4)`,
/// `Point(x, y)`) and naming them is noise, so the default budget is 2.
///
/// Exempt by default: an `@override`, whose signature belongs to the
/// supertype; an operator, whose parameters cannot be named; and a
/// single-parameter constructor of the type it wraps.
class PreferNamedParameters extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_named_parameters',
    'This declaration takes {0} positional parameters.',
    correctionMessage: 'Name them, so the call site says what they mean.',
  );

  PreferNamedParameters()
    : super(
        name: 'prefer_named_parameters',
        description:
            'Warns when a declaration takes more than a few positional '
            'parameters.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferNamedParameters rule;

  _Visitor(this.rule);

  /// Names whose positional signature a framework dictates.
  ///
  /// `onRequest` and `middleware` are dart_frog's route contract, where the
  /// parameters are the URL's path segments in order — naming them is not the
  /// author's to decide. `main` takes its arguments from the platform.
  static const _defaultIgnoredNames = {'main', 'onRequest', 'middleware'};

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isOperator) return;
    if (node.isSetter) return;
    if (_isOverride(node.metadata)) return;
    if (_isIgnoredName(node.name.lexeme)) return;

    _check(node.parameters);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isOverride(node.metadata)) return;
    if (_isIgnoredName(node.name.lexeme)) return;

    _check(node.functionExpression.parameters);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // A private constructor is not an API: it is reached from one place in the
    // same library, usually a factory assembling injected dependencies
    // (`Pipeline._(this._storage, this._adapter, this._policy)`). Naming those
    // adds ceremony at the one call site that already knows the order. With
    // `onRequest`, these were 22 of 28 reports on a real codebase.
    if (rule.config.boolOption(
          'ignore_private_constructors',
          defaultValue: true,
        ) &&
        (node.name?.lexeme.startsWith('_') ?? false)) {
      return;
    }

    _check(node.parameters);
  }

  bool _isIgnoredName(String name) {
    final ignored = rule.config.nameSetOption(
      'ignored_names',
      defaultValue: _defaultIgnoredNames,
    );

    return ignored.contains(name);
  }

  void _check(FormalParameterList? parameters) {
    if (parameters == null) return;

    final maxPositional = rule.config.intOption(
      'max_positional',
      defaultValue: 2,
    );

    final positional = parameters.parameters
        .where((p) => p.isPositional)
        .length;
    if (positional <= maxPositional) return;

    rule.reportAtNode(parameters, arguments: ['$positional']);
  }

  bool _isOverride(NodeList<Annotation> metadata) =>
      metadata.any((a) => a.name.name == 'override');
}
