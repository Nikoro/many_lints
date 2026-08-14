import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a function, method, or getter returns a Widget or Widget subclass.
///
/// Extracting widgets to helper methods is a Flutter anti-pattern because
/// Flutter rebuilds the widget tree by calling the function every time,
/// which prevents framework optimizations. Instead, extract widgets into
/// separate widget classes.
///
/// The `build()` override method is exempted since it is the standard
/// way to build widgets.
class AvoidReturningWidgets extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_returning_widgets',
    'Avoid returning widgets from functions, methods, or getters.',
    correctionMessage: 'Extract the widget into a separate widget class.',
  );

  AvoidReturningWidgets()
    : super(
        name: 'avoid_returning_widgets',
        description:
            'Warns when a function, method, or getter returns a Widget '
            'or Widget subclass instead of using a dedicated widget class.',
      );

  @override
  LintCode get diagnosticCode => code;

  /// Annotations of the functional-widget generators, which turn an annotated
  /// function into a real widget class — so the function is a widget
  /// declaration rather than a helper, and reporting it asks for a rewrite the
  /// generator already performs.
  ///
  /// These are the defaults for this rule.
  static const defaultIgnoredAnnotations = {
    'FunctionalWidget',
    'swidget',
    'hwidget',
    'hcwidget',
  };

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // Registered on the unit rather than on each declaration: the tear-off
    // exemption needs to know whether a declaration is referenced by name
    // elsewhere in the file, which a per-declaration visit cannot see.
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidReturningWidgets rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final tearOffs = _TearOffCollector();
    node.accept(tearOffs);
    node.accept(_DeclarationVisitor(rule, tearOffs.names));
  }
}

/// Collects the names of functions and methods that are passed as values
/// rather than called.
///
/// A `SimpleIdentifier` naming a declaration is a tear-off unless it is the
/// callee of an invocation or the left side of an assignment. Matching by name
/// rather than by element is deliberate: it costs a false exemption when two
/// declarations in one file share a name, which is far cheaper than the false
/// positive it prevents.
class _TearOffCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;

    // `foo()` — an invocation, not a tear-off.
    if (parent is MethodInvocation && parent.methodName == node) return;
    // The declaration's own name token.
    if (parent is MethodDeclaration && parent.name == node.token) return;
    if (parent is FunctionDeclaration && parent.name == node.token) return;
    // `foo: ...` in a named argument is the label, not a reference.
    if (parent is Label) return;
    // `x.foo` where foo is the property being accessed, not torn off, unless
    // the whole access is itself a value — which the parent check below covers.
    if (parent is PropertyAccess && parent.propertyName == node) {
      if (parent.parent is! ArgumentList) return;
    }

    names.add(node.name);
  }
}

class _DeclarationVisitor extends RecursiveAstVisitor<void> {
  final AvoidReturningWidgets rule;
  final Set<String> tearOffNames;

  _DeclarationVisitor(this.rule, this.tearOffNames);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);

    // Exempt build() overrides
    if (node.name.lexeme == 'build') return;

    _checkReturnType(
      node.returnType,
      node.name,
      node.metadata,
      isGetter: node.isGetter,
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);

    _checkReturnType(
      node.returnType,
      node.name,
      node.metadata,
      isGetter: node.isGetter,
    );
  }

  void _checkReturnType(
    TypeAnnotation? returnType,
    Token nameToken,
    NodeList<Annotation> metadata, {
    bool isGetter = false,
  }) {
    if (returnType == null) return;

    final ignoredNames = rule.config.stringListOption('ignored_names');
    if (ignoredNames.contains(nameToken.lexeme)) return;

    final ignoredAnnotations = rule.config.nameSetOption(
      'ignored_annotations',
      defaultValue: AvoidReturningWidgets.defaultIgnoredAnnotations,
    );
    if (metadata.any((a) => ignoredAnnotations.contains(a.name.name))) {
      return;
    }

    // A declaration handed to a builder (`Builder(builder: _row)`) is invoked
    // by the framework at its own point in the tree, so it does not collapse a
    // subtree into the caller's rebuild — which is the cost this rule exists to
    // prevent. Only a declaration that is *called* to build inline is reported.
    //
    // Getters are excluded: `=> _body` reads the getter rather than tearing it
    // off, so a bare reference to one is the inline build this rule targets.
    if (!isGetter && tearOffNames.contains(nameToken.lexeme)) return;

    final type = returnType.type;
    if (type == null) return;

    // `allow_nullable: true` exempts `Widget?` returns, where the null case
    // usually means "render nothing" rather than a widget-building helper.
    if (rule.config.boolOption('allow_nullable', defaultValue: false) &&
        returnType.question != null) {
      return;
    }

    // Handle nullable types: Widget? -> check the underlying type
    final effectiveType = type is InterfaceType ? type : null;
    if (effectiveType == null) return;

    if (widgetChecker.isAssignableFromType(effectiveType)) {
      rule.reportAtToken(nameToken);
    }
  }
}
