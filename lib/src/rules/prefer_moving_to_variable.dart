import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferMovingToVariable extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_moving_to_variable',
    "The chain '{0}' is repeated {1} times in this block.",
    correctionMessage: 'Compute it once into a variable and reuse it.',
  );

  static const _defaultAllowedDuplicatedChains = 0;

  static const _defaultMinChainLength = 2;

  PreferMovingToVariable()
    : super(
        name: 'prefer_moving_to_variable',
        description:
            'Warns when a repeated property or invocation chain could be '
            'computed once into a variable.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addBlock(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferMovingToVariable rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    // Edge case: rule instances are reused across package roots, so options are read per visit
    final allowed = rule.config.options.containsKey('max_extra_occurrences')
        ? rule.config.intOption(
            'max_extra_occurrences',
            defaultValue:
                PreferMovingToVariable._defaultAllowedDuplicatedChains,
          )
        : rule.config.intOption(
            'allowed_duplicated_chains',
            defaultValue:
                PreferMovingToVariable._defaultAllowedDuplicatedChains,
          );
    final minChainLength = rule.config.intOption(
      'min_chain_length',
      defaultValue: PreferMovingToVariable._defaultMinChainLength,
    );
    final ignoredInvocations = rule.config
        .stringListOption('ignored_invocations')
        .toSet();
    final ignoredTargets = rule.config
        .stringListOption('ignored_targets')
        .toSet();

    final collector = _ChainCollector(
      ignoredInvocations: ignoredInvocations,
      ignoredTargets: ignoredTargets,
      minChainLength: minChainLength,
    );
    for (final statement in node.statements) {
      statement.accept(collector);
    }

    final repeated = {
      for (final entry in collector.chains.entries)
        if (entry.value.length > allowed + 1) entry.key: entry.value,
    };

    for (final entry in repeated.entries) {
      final isSubsumedByLongerChain = repeated.keys.any(
        (other) =>
            other != entry.key &&
            other.startsWith(entry.key) &&
            repeated[other]!.length == entry.value.length,
      );
      if (isSubsumedByLongerChain) continue;

      rule.reportAtNode(
        entry.value.first,
        arguments: [entry.key, entry.value.length.toString()],
      );
    }
  }
}

class _ChainCollector extends RecursiveAstVisitor<void> {
  final Set<String> ignoredInvocations;
  final Set<String> ignoredTargets;
  final int minChainLength;

  final chains = <String, List<Expression>>{};

  _ChainCollector({
    required this.ignoredInvocations,
    required this.ignoredTargets,
    required this.minChainLength,
  });

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_recordAndShouldStop(node)) return;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_recordAndShouldStop(node)) return;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_recordAndShouldStop(node)) return;
    super.visitPropertyAccess(node);
  }

  // Edge case: a closure may run any number of times, so hoisting out of it moves evaluation
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  bool _recordAndShouldStop(Expression node) {
    final parent = node.parent;
    final isWriteTarget =
        parent is AssignmentExpression && parent.leftHandSide == node;
    if (isWriteTarget) return true;

    final isCalledForEffect =
        parent is ExpressionStatement || node.staticType is VoidType;
    if (isCalledForEffect) return false;

    if (_isIgnored(node)) return false;
    final isWorthNaming =
        _containsInvocation(node) || _chainLength(node) >= minChainLength;
    if (!isWorthNaming) return false;
    if (_isSideEffecting(node)) return false;

    (chains[node.toSource()] ??= []).add(node);
    return false;
  }

  bool _isIgnored(Expression node) {
    if (ignoredInvocations.isEmpty && ignoredTargets.isEmpty) return false;

    for (Expression? link = node; link != null; link = _targetOf(link)) {
      switch (link) {
        case MethodInvocation(:final methodName, :final target):
          if (ignoredInvocations.contains(methodName.name)) return true;
          if (target is SimpleIdentifier &&
              ignoredTargets.contains(target.name)) {
            return true;
          }
        case PrefixedIdentifier(:final prefix):
          if (ignoredTargets.contains(prefix.name)) return true;
        case SimpleIdentifier(:final name):
          if (ignoredTargets.contains(name)) return true;
        default:
          break;
      }
      final reachedTypeName = link.staticType?.element?.name;
      if (reachedTypeName != null && ignoredTargets.contains(reachedTypeName)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsInvocation(Expression node) {
    for (Expression? link = node; link != null; link = _targetOf(link)) {
      if (link is MethodInvocation) return true;
    }
    return false;
  }

  int _chainLength(Expression node) {
    var length = 0;
    for (Expression? link = node; link != null; link = _targetOf(link)) {
      if (link is MethodInvocation ||
          link is PropertyAccess ||
          link is PrefixedIdentifier) {
        length++;
      }
    }
    return length;
  }

  static Expression? _targetOf(Expression node) => switch (node) {
    MethodInvocation(:final target) => target,
    PropertyAccess(:final target) => target,
    PrefixedIdentifier(:final prefix) => prefix,
    _ => null,
  };

  static bool _isSideEffecting(Expression node) {
    for (Expression? link = node; link != null; link = _targetOf(link)) {
      if (link is InstanceCreationExpression || link is AwaitExpression) {
        return true;
      }
      if (link is CascadeExpression) return true;
    }
    return false;
  }
}
