import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that rewrites a predicate conditional into `Option.fromPredicate`.
///
/// The conditional's condition becomes the lambda body with the wrapped value
/// substituted for the lambda's parameter, so
/// `age > 18 ? Option.of(age) : none()` becomes
/// `Option.fromPredicate(age, (a) => a > 18)`.
///
/// The substitution is what makes this worth doing rather than emitting
/// `(_) => age > 18`: the point of `fromPredicate` is that the predicate reads
/// as a test *on the value*, which a closure over the original variable does
/// not.
class PreferFromPredicateFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferFromPredicate',
    DartFixKindPriority.standard,
    "Replace with 'Option.fromPredicate'",
  );

  PreferFromPredicateFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final conditional = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditional == null) return;

    final wrapped = _someArgument(conditional.thenExpression);
    if (wrapped == null) return;

    final valueSource = wrapped.toSource();
    final parameter = _parameterName(conditional, valueSource);

    // Rewrite the condition with the lambda's parameter standing in for the
    // value. Edits are collected first and applied back-to-front so earlier
    // replacements do not shift later offsets.
    final condition = conditional.condition.unParenthesized;
    final occurrences = _occurrencesOf(condition, valueSource);
    if (occurrences.isEmpty) return;

    final buffer = StringBuffer();
    var cursor = condition.offset;
    final source = unitResult.content;
    for (final occurrence in occurrences) {
      buffer.write(source.substring(cursor, occurrence.offset));
      buffer.write(parameter);
      cursor = occurrence.end;
    }
    buffer.write(source.substring(cursor, condition.end));

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(conditional),
        'Option.fromPredicate($valueSource, ($parameter) => $buffer)',
      );
    });
  }

  /// The value passed to the `Some`/`Option.of` branch.
  Expression? _someArgument(Expression expression) {
    final target = expression.unParenthesized;
    if (target is! InstanceCreationExpression) return null;

    final arguments = target.argumentList.arguments;
    if (arguments.length != 1) return null;

    final argument = arguments.first;
    return argument is Expression ? argument : null;
  }

  /// A lambda parameter name that nothing in the conditional already binds.
  ///
  /// The obvious first initial is usually free, but a condition like
  /// `a > b` would shadow `b` if the value were `bananas`, so the name is
  /// checked against every identifier in the expression before being used.
  String _parameterName(ConditionalExpression conditional, String value) {
    final taken = _IdentifierCollector();
    conditional.accept(taken);

    final initial = value.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(value[0])
        ? value[0].toLowerCase()
        : 'v';

    if (!taken.names.contains(initial)) return initial;
    for (var i = 2; ; i++) {
      final candidate = '$initial$i';
      if (!taken.names.contains(candidate)) return candidate;
    }
  }

  /// Every node in [condition] whose source is exactly [source].
  List<AstNode> _occurrencesOf(Expression condition, String source) {
    final finder = _OccurrenceFinder(source);
    condition.accept(finder);
    return finder.occurrences;
  }
}

/// Collects every identifier name appearing in an expression.
class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
  }
}

/// Finds the nodes matching a given source text, outermost first and without
/// overlapping.
class _OccurrenceFinder extends RecursiveAstVisitor<void> {
  final String source;
  final occurrences = <AstNode>[];

  _OccurrenceFinder(this.source);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.toSource() == source) occurrences.add(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.toSource() == source) {
      occurrences.add(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.toSource() == source) {
      occurrences.add(node);
      return;
    }
    super.visitPropertyAccess(node);
  }
}
