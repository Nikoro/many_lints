import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a class declares a constructor identical to the default one.
///
/// `class A { A(); }` writes out exactly what Dart provides when no
/// constructor is declared at all: no parameters, no initializers, no body,
/// no documentation. The line adds nothing a reader can act on.
///
/// A constructor that is `const`, named, private, or annotated is doing
/// something the implicit one cannot, and is left alone — as is any class with
/// a second constructor, where declaring the unnamed one is what keeps it
/// available.
class AvoidUnnecessaryConstructor extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_constructor',
    'This constructor is identical to the default one.',
    correctionMessage: 'Remove it; Dart provides this constructor already.',
  );

  AvoidUnnecessaryConstructor()
    : super(
        name: 'avoid_unnecessary_constructor',
        description:
            'Warns when a class declares an empty unnamed constructor that '
            'matches the one Dart would provide anyway.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryConstructor rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final constructors = body.members.whereType<ConstructorDeclaration>();

    // With a second constructor present, the unnamed one has to be declared to
    // exist at all — Dart only supplies it when no constructor is written.
    if (constructors.length != 1) return;

    final constructor = constructors.first;

    // A named constructor is never the implicit one.
    if (constructor.name != null) return;

    // `const A();` lets callers write `const A()`, which the implicit
    // constructor does not allow.
    if (constructor.constKeyword != null) return;

    if (constructor.factoryKeyword != null) return;
    if (constructor.parameters.parameters.isNotEmpty) return;
    if (constructor.initializers.isNotEmpty) return;
    if (constructor.redirectedConstructor != null) return;

    // A documented or annotated constructor carries information, even empty.
    if (constructor.documentationComment != null) return;
    if (constructor.metadata.isNotEmpty) return;

    // Both spellings of "does nothing" count: `A();` and `A() {}`.
    final hasNoBody = switch (constructor.body) {
      EmptyFunctionBody() => true,
      BlockFunctionBody(:final block) => block.statements.isEmpty,
      _ => false,
    };
    if (!hasNoBody) return;

    rule.reportAtNode(constructor);
  }
}
