import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when the same property-access or invocation chain is repeated within
/// one block, and could be computed once into a variable.
///
/// ```dart
/// // Bad
/// return Container(
///   color: Theme.of(context).colorScheme.secondary,
///   child: Text('...', style: Theme.of(context).textTheme.bodyMedium),
/// );
///
/// // Good
/// final theme = Theme.of(context);
/// return Container(
///   color: theme.colorScheme.secondary,
///   child: Text('...', style: theme.textTheme.bodyMedium),
/// );
/// ```
///
/// This is the inverse of [UseExistingVariable]: that rule fires when a
/// variable already exists and an expression repeats its initializer, while
/// this one fires when no variable exists yet.
class PreferMovingToVariable extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_moving_to_variable',
    "The chain '{0}' is repeated {1} times in this block.",
    correctionMessage: 'Compute it once into a variable and reuse it.',
  );

  /// How many *extra* repetitions are tolerated before reporting.
  ///
  /// `0` reports the second occurrence, which is the default.
  static const _defaultAllowedDuplicatedChains = 0;

  /// The shortest chain worth naming, in links.
  ///
  /// `a.b` is one link and reads no worse than a variable, so the default of 2
  /// starts at `a.b.c` / `f(x).y`. Without it a linter reports every
  /// repeated chain, including trivial ones.
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
    // Resolved per visit, not cached: rule instances are reused across
    // package roots.
    final allowed = rule.config.intOption(
      'allowed_duplicated_chains',
      defaultValue: PreferMovingToVariable._defaultAllowedDuplicatedChains,
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
      // Every prefix of a repeated chain is itself repeated, so `a.b.c` twice
      // also yields `a.b` twice. Report the longest one only: naming it
      // subsumes the shorter, and two diagnostics on one expression would ask
      // the reader to make the same edit twice.
      if (repeated.keys.any(
        (other) =>
            other != entry.key &&
            other.startsWith(entry.key) &&
            repeated[other]!.length == entry.value.length,
      )) {
        continue;
      }

      // Reported at the first occurrence: that is where the variable would be
      // introduced, so it is the line the reader has to act on.
      rule.reportAtNode(
        entry.value.first,
        arguments: [entry.key, entry.value.length.toString()],
      );
    }
  }
}

/// Groups repeated chains by their source text.
///
/// Source-text equality is the same identity [UseExistingVariable] uses. It
/// cannot see through a rename, which costs a missed report rather than a
/// false one.
class _ChainCollector extends RecursiveAstVisitor<void> {
  final Set<String> ignoredInvocations;
  final Set<String> ignoredTargets;
  final int minChainLength;

  /// Insertion-ordered, so the first occurrence stays first.
  final chains = <String, List<Expression>>{};

  _ChainCollector({
    required this.ignoredInvocations,
    required this.ignoredTargets,
    required this.minChainLength,
  });

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_record(node)) return;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_record(node)) return;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_record(node)) return;
    super.visitPropertyAccess(node);
  }

  // Stop at nested function boundaries: a closure may run a different number
  // of times, so hoisting out of it changes when the chain is evaluated.
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  /// Records [node] as a candidate chain. Returns whether recursion should
  /// stop.
  ///
  /// Recursion continues even after a match, because what repeats is often a
  /// *prefix* rather than a whole chain: `Theme.of(context).primary` and
  /// `Theme.of(context).secondary` share nothing at full length, and the
  /// variable the reader should introduce is the common `Theme.of(context)`.
  /// Every prefix is therefore counted on its own, and the reporting pass
  /// keeps only the longest of the chains that repeat equally often.
  bool _record(Expression node) {
    // An assignment target is a write; naming it would change the meaning.
    final parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      return true;
    }

    // A call made for its effect is the statement itself, not a value to
    // hoist: `print(x)` twice is two prints, and naming it changes nothing.
    if (parent is ExpressionStatement) return false;
    if (node.staticType is VoidType) return false;

    if (_isIgnored(node)) return false;
    // An invocation earns a name at any length: repeating `Theme.of(context)`
    // repeats the work, where repeating a field read only repeats the text.
    // `min_chain_length` therefore governs pure property chains only.
    if (!_containsInvocation(node) && _chainLength(node) < minChainLength) {
      return false;
    }
    // Anything that allocates or awaits is deliberately re-evaluated.
    if (_isSideEffecting(node)) return false;

    (chains[node.toSource()] ??= []).add(node);
    return false;
  }

  /// Whether any link in [node] names an ignored invocation or target.
  bool _isIgnored(Expression node) {
    if (ignoredInvocations.isEmpty && ignoredTargets.isEmpty) return false;

    for (Expression? link = node; link != null; link = _targetOf(link)) {
      switch (link) {
        case MethodInvocation(:final methodName, :final target):
          if (ignoredInvocations.contains(methodName.name)) return true;
          // `Theme.of(context)` — the class name is the target identifier.
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
      // A type reached through a chain is named by its static element.
      final typeName = link.staticType?.element?.name;
      if (typeName != null && ignoredTargets.contains(typeName)) return true;
    }
    return false;
  }

  /// Whether any link in [node] is a method call.
  static bool _containsInvocation(Expression node) {
    for (Expression? link = node; link != null; link = _targetOf(link)) {
      if (link is MethodInvocation) return true;
    }
    return false;
  }

  /// The number of links in [node], where `a.b` is 1 and `a.b.c` is 2.
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

  /// Whether re-evaluating [node] may be the point, as in
  /// [UseExistingVariable].
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
