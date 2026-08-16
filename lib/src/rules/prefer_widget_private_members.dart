import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a widget class declares a public method or getter.
///
/// A widget's public surface is its constructor: the parameters a parent
/// passes in. Everything else exists to serve `build`, and making it public
/// invites a caller to reach into the widget and invoke part of its rendering
/// out of band — which is exactly the coupling a widget class is meant to
/// prevent.
///
/// This matters more in Flutter than the general rule would suggest, because a
/// widget instance is *rebuilt constantly*. A public method on a widget is a
/// method on an object the framework may discard on the next frame, so
/// whatever a caller does with it cannot be relied upon.
///
/// Fields are not reported: a widget's fields are its constructor parameters,
/// and `final` public fields are the idiom the framework itself uses. An
/// `@override` is skipped too, since the name belongs to the supertype.
class PreferWidgetPrivateMembers extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_widget_private_members',
    "The widget member '{0}' is public.",
    correctionMessage: 'Make it private: a widget\'s API is its constructor.',
  );

  PreferWidgetPrivateMembers()
    : super(
        name: 'prefer_widget_private_members',
        description: 'Warns when a widget class declares a public method.',
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
  /// Members the framework itself calls, which therefore cannot be private.
  static const _frameworkMembers = {
    'build',
    'createState',
    'createElement',
    'debugFillProperties',
    'debugDescribeChildren',
    'toStringShort',
    'noSuchMethod',
    'toString',
  };

  final PreferWidgetPrivateMembers rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (!widgetChecker.isSuperOf(element)) return;

    // A State class is not a widget, and its `initState`/`dispose` are the
    // framework's. Only the widget itself is in scope here.
    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (member.isOperator) continue;
      // A static member is not reachable on a widget instance, so the argument
      // this rule rests on — that the framework may discard the object on the
      // next frame — does not apply to it. `static Future<T> show(context)` is
      // the documented way to open a dialog or a sheet, and it was 14 of 16
      // reports on a real app.
      if (member.isStatic) continue;

      final name = member.name.lexeme;
      if (name.startsWith('_')) continue;
      if (_frameworkMembers.contains(name)) continue;
      if (member.metadata.any((a) => a.name.name == 'override')) continue;
      if (member.metadata.any((a) => a.name.name == 'visibleForTesting')) {
        continue;
      }

      rule.reportAtToken(member.name, arguments: [name]);
    }
  }
}
