import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

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

class _TearOffCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;

    if (parent is MethodInvocation && parent.methodName == node) return;
    if (parent is MethodDeclaration && parent.name == node.token) return;
    if (parent is FunctionDeclaration && parent.name == node.token) return;
    if (parent is Label) return;
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

    // Edge case: `=> _body` reads a getter instead of tearing it off, so it still builds inline
    if (!isGetter && tearOffNames.contains(nameToken.lexeme)) return;

    final type = returnType.type;
    if (type == null) return;

    if (rule.config.boolOption('allow_nullable', defaultValue: false) &&
        returnType.question != null) {
      return;
    }

    if (type is InterfaceType && widgetChecker.isAssignableFromType(type)) {
      rule.reportAtToken(nameToken);
    }
  }
}
