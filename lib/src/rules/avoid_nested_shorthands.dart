import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a dot shorthand appears inside the arguments of another dot
/// shorthand invocation.
///
/// A dot shorthand omits the type name because the context supplies it. Nesting
/// one inside another removes the last name a reader could anchor on, leaving
/// expressions such as `.new(.new(version: .new('val')))` where nothing on the
/// line says what is being built. The outer shorthand still reads fine — its
/// type comes from the variable, parameter or return type next to it — but the
/// inner ones are only resolvable by looking up the outer constructor's
/// signature.
///
/// The rule reports each nested shorthand, not the outer one, so the fix is
/// always local: name the type on the inner expression and the outer shorthand
/// stays.
///
/// Applies to every shorthand form — constructor invocations (`.new(...)`,
/// `.filled(...)`), static method invocations (`.make(...)`) and property
/// accesses (`.zero`) — since all three drop the type name for the same reason.
///
/// **BAD:**
/// ```dart
/// final Another a = .new(.new(version: .new('val')));  // LINT x2
/// final Some b = .new(version: .zero);                 // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// final Another a = .new(Some(version: SomeClass('val')));
/// final b = Another(.new(version: SomeClass('val')));
/// final Some c = .new(version: SomeClass.zero);
/// ```
class AvoidNestedShorthands extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_nested_shorthands',
    'Dot shorthand is nested inside another dot shorthand.',
    correctionMessage: 'Try writing the type name explicitly.',
  );

  AvoidNestedShorthands()
    : super(
        name: 'avoid_nested_shorthands',
        description:
            'Warns when a dot shorthand is nested inside another dot shorthand '
            'invocation, leaving no type name for the reader to anchor on.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    // Only the two *invocation* forms carry an argument list that something
    // could be nested inside. A `DotShorthandPropertyAccess` (`.zero`) has no
    // arguments, so it can only ever be the nested node, never the outer one.
    //
    // Both invocation forms must be registered: resolution decides which one a
    // call becomes. A constructor (including a factory) resolves to
    // `DotShorthandConstructorInvocation`, while a *static method* stays a
    // `DotShorthandInvocation` — and before resolution every form parses as the
    // latter, so registering only one silently misses half the cases.
    registry.addDotShorthandConstructorInvocation(this, visitor);
    registry.addDotShorthandInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNestedShorthands rule;

  _Visitor(this.rule);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _checkArguments(node.argumentList);

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) =>
      _checkArguments(node.argumentList);

  /// Reports every dot shorthand found anywhere within [argumentList].
  ///
  /// The search is deep rather than limited to direct arguments, because a
  /// nested shorthand is just as unreadable when buried in a sub-expression —
  /// `.of(.new(1).value)` hides `.new(1)` behind a property access.
  void _checkArguments(ArgumentList argumentList) {
    final finder = _NestedShorthandFinder();
    argumentList.accept(finder);

    for (final nested in finder.found) {
      rule.reportAtNode(nested);
    }
  }
}

/// Collects the outermost dot shorthands inside a subtree.
///
/// The overrides deliberately do not call `super`, so the walk stops at each
/// match instead of descending into it. That keeps a shorthand nested three
/// deep from being reported once per enclosing invocation: it is reported only
/// by its *direct* parent, which is reached anyway because the rule's visitor
/// runs for every invocation in the file.
///
/// Function boundaries are *not* skipped here, unlike most collectors in this
/// package. A closure passed as an argument still has its shorthands resolved
/// against the enclosing invocation's parameter type, so `.map(.new)`-style
/// nesting inside a callback body reads exactly as poorly as a direct argument.
class _NestedShorthandFinder extends RecursiveAstVisitor<void> {
  final List<Expression> found = [];

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => found.add(node);

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) =>
      found.add(node);

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) =>
      found.add(node);
}
