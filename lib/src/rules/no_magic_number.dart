import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../magic_literal_context.dart';
import '../many_lints_rule.dart';

/// Warns when a numeric literal appears without a name to explain it.
///
/// `if (retries > 3)` states a policy the reader cannot check and the next
/// person cannot find: the same 3 appears in four other files, and changing
/// the policy means finding all five. `if (retries > maxRetries)` says what
/// the number is for and gives the change one place to happen.
///
/// The defaults are tuned to report only numbers that genuinely carry meaning:
///
/// - `-1`, `0`, `1` and `2` are always allowed. They are the vocabulary of
///   indexing, counting and halving, and naming them makes code worse.
/// - A literal that *initialises a declaration* is exempt, since it is already
///   named — `const timeout = 30;` is the shape this rule asks for.
/// - Anything inside a `const` declaration or an `enum` is exempt for the same
///   reason, as are annotation arguments.
/// - Tests are exempt by default. A fixture's numbers are the test data, and
///   naming each one buries the case it describes.
///
/// This rule is in **no preset**: what counts as magic is a house style, and
/// in a Flutter codebase full of layout numbers the honest default is off.
class NoMagicNumber extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_magic_number',
    'The number {0} is used without a name.',
    correctionMessage: 'Move it to a named constant that says what it means.',
  );

  NoMagicNumber()
    : super(
        name: 'no_magic_number',
        description:
            'Warns when a numeric literal appears without a name to explain '
            'it.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIntegerLiteral(this, visitor);
    registry.addDoubleLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// The numbers that carry no policy: indexing, counting, halving, and the
  /// sentinel every codebase spells `-1`.
  static final _defaultAllowed = {-1.0, 0.0, 1.0, 2.0};

  /// Constructors whose numeric arguments are a measurement, not a policy.
  ///
  /// A spacing grid is the single biggest source of noise this rule has: on a
  /// real Flutter app these accounted for **416 of 490** reports, all of them
  /// `Gap(8)`, `EdgeInsets.only(top: 12)` and their siblings. `spacing8` is a
  /// worse name than `8`, and extracting it moves the number away from the
  /// layout it describes — so they are ignored by default, and a project that
  /// disagrees can clear the list.
  static const _defaultIgnoredInvocations = {
    'BorderRadius',
    'Radius',
    'EdgeInsets',
    'EdgeInsetsDirectional',
    'EdgeInsetsGeometry',
    'Gap',
    'SliverGap',
    'SizedBox',
    'Size',
    'Offset',
    'Duration',
    'Rect',
    'Alignment',
  };

  final NoMagicNumber rule;

  _Visitor(this.rule);

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    final value = node.value;
    if (value != null) _check(node, value.toDouble(), node.literal.lexeme);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) =>
      _check(node, node.value, node.literal.lexeme);

  /// [written] is the literal as the author spelled it, which is what the
  /// diagnostic quotes. Comparison normalises to `double` so `17` and `17.0`
  /// match one `allowed:` entry, but reporting that normalised form would tell
  /// the reader to look for a `17.0` their file does not contain.
  void _check(Literal node, double value, String written) {
    if (rule.config.boolOption('ignore_tests', defaultValue: true) &&
        (rule.relativePath?.startsWith('test/') ?? false)) {
      return;
    }

    final allowed = rule.config.numberSetOption(
      'allowed',
      defaultValue: _defaultAllowed,
    );
    // A negated literal parses as a prefix expression over a positive one, so
    // `-1` reaches here as `1`. Without this, allowing -1 would never match.
    final effective = _isNegated(node) ? -value : value;
    if (allowed.contains(effective) || allowed.contains(value)) return;

    if (initialisesADeclaration(node)) return;
    if (isInExemptContext(node)) return;

    final ignoredInvocations = rule.config.nameSetOption(
      'ignored_invocations',
      defaultValue: _defaultIgnoredInvocations,
    );
    if (isArgumentToIgnoredInvocation(node, ignoredInvocations)) return;

    rule.reportAtNode(node, arguments: [written]);
  }

  bool _isNegated(Literal node) {
    final parent = node.parent;

    return parent is PrefixExpression && parent.operator.lexeme == '-';
  }
}
