import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../magic_literal_context.dart';
import '../many_lints_rule.dart';

class NoMagicString extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_magic_string',
    "The string '{0}' is repeated {1} times without a name.",
    correctionMessage:
        'Move it to a named constant so it changes in one place.',
  );

  NoMagicString()
    : super(
        name: 'no_magic_string',
        description:
            'Warns when the same string literal is repeated without a name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoMagicString rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (rule.config.boolOption('ignore_tests', defaultValue: true) &&
        (rule.relativePath?.startsWith('test/') ?? false)) {
      return;
    }

    final minLength = rule.config.intOption('min_length', defaultValue: 3);
    final minOccurrences = rule.config.intOption(
      'min_occurrences',
      defaultValue: 3,
    );
    final ignoredInvocations = rule.config.nameSetOption(
      'ignored_invocations',
      defaultValue: const {},
    );

    final collector = _StringCollector(
      minLength: minLength,
      ignoredInvocations: ignoredInvocations,
    );
    node.accept(collector);

    for (final entry in collector.occurrences.entries) {
      if (entry.value.length < minOccurrences) continue;

      for (final literal in entry.value) {
        rule.reportAtNode(
          literal,
          arguments: [entry.key, '${entry.value.length}'],
        );
      }
    }
  }
}

class _StringCollector extends RecursiveAstVisitor<void> {
  final int minLength;
  final Set<String> ignoredInvocations;
  final Map<String, List<SimpleStringLiteral>> occurrences = {};

  _StringCollector({required this.minLength, required this.ignoredInvocations});

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final value = node.value;
    if (value.trim().length < minLength) return;

    if (initialisesADeclaration(node)) return;
    if (isInExemptContext(node)) return;
    if (isArgumentToIgnoredInvocation(node, ignoredInvocations)) return;

    occurrences.putIfAbsent(value, () => []).add(node);
  }
}
