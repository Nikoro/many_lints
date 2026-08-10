import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that gives a discarded `BuildContext` parameter a usable name.
class NeverDiscardBuildContextFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.neverDiscardBuildContext',
    DartFixKindPriority.standard,
    "Name the parameter 'context'",
  );

  NeverDiscardBuildContextFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final parameter = node.thisOrAncestorOfType<RegularFormalParameter>();
    final name = parameter?.name;
    if (parameter == null || name == null) return;

    // Renaming to `context` is only safe when nothing in the enclosing scope
    // already binds that name — otherwise the fix would shadow the very
    // context the body currently relies on, silently changing behaviour
    // instead of just making the parameter usable.
    if (_scopeBindsContext(parameter)) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(name), 'context');
    });
  }

  /// Whether anything named `context` is already in scope around [parameter].
  ///
  /// Scans the **outermost** enclosing member rather than the immediately
  /// enclosing body, because the name that would be shadowed usually lives
  /// further out — a `build(BuildContext context)` whose builder callback
  /// discards its own context is the case this rule fires on most.
  ///
  /// This deliberately over-approximates: a `context` declared in a sibling
  /// branch cannot actually collide, but treating it as a collision only costs
  /// an offered fix, whereas missing one would silently rebind the name the
  /// body already reads.
  bool _scopeBindsContext(RegularFormalParameter parameter) {
    final scope =
        parameter.thisOrAncestorOfType<MethodDeclaration>() ??
        parameter.thisOrAncestorOfType<FunctionDeclaration>() ??
        parameter.thisOrAncestorOfType<FunctionBody>();
    if (scope == null) return false;

    final finder = _ContextBindingFinder(parameter);
    scope.accept(finder);
    return finder.found;
  }
}

/// Finds a declaration of the name `context` other than [exclude].
class _ContextBindingFinder extends RecursiveAstVisitor<void> {
  final RegularFormalParameter exclude;
  bool found = false;

  _ContextBindingFinder(this.exclude);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == 'context') found = true;
    super.visitVariableDeclaration(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    if (node != exclude && node.name?.lexeme == 'context') found = true;
    super.visitRegularFormalParameter(node);
  }
}
