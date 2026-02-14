import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Suggests using `List.of()` / `Set.of()` instead of `List.from()` /
/// `Set.from()` when the argument type is already assignable to the target
/// element type.
///
/// `.of()` enforces type safety at compile time, while `.from()` allows
/// potentially unsafe downcasting checked only at runtime.
class PreferIterableOf extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_iterable_of',
    'Use {0}.of() instead of {0}.from().',
    correctionMessage:
        'Replace .from() with .of() for compile-time type '
        'safety.',
  );

  PreferIterableOf()
    : super(
        name: 'prefer_iterable_of',
        description:
            'Prefer List.of() / Set.of() over List.from() / Set.from() when '
            'types are already compatible.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferIterableOf rule;

  _Visitor(this.rule);

  static const _targetNames = {'List', 'Set'};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Handles: List<int>.from(source), Set<int>.from(source)
    final constructorName = node.constructorName;
    final name = constructorName.name;
    if (name == null || name.name != 'from') return;

    final typeName = constructorName.type.name.lexeme;
    if (!_targetNames.contains(typeName)) return;

    _check(node, node.argumentList, node.staticType, typeName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Handles: List.from(source), Set.from(source) (no explicit type args)
    if (node.methodName.name != 'from') return;

    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (!_targetNames.contains(target.name)) return;

    _check(node, node.argumentList, node.staticType, target.name);
  }

  void _check(
    AstNode node,
    ArgumentList argumentList,
    DartType? resultType,
    String typeName,
  ) {
    final positionalArgs = argumentList.arguments
        .where((a) => a is! NamedExpression)
        .toList();
    if (positionalArgs.length != 1) return;

    final sourceArg = positionalArgs.first;

    // Get the target type (the result type, e.g. List<int>)
    if (resultType is! InterfaceType) return;

    // Get the target element type (the T in List<T> or Set<T>)
    final targetTypeArgs = resultType.typeArguments;
    if (targetTypeArgs.isEmpty) return;
    final targetElementType = targetTypeArgs.first;

    // If target element type is dynamic, .from() and .of() are equivalent
    if (targetElementType is DynamicType) {
      rule.reportAtNode(node, arguments: [typeName]);
      return;
    }

    // Get the source argument's static type
    final sourceType = sourceArg.staticType;
    if (sourceType is! InterfaceType) return;

    // Extract the source element type from Iterable<T>
    final sourceElementType = _getIterableElementType(sourceType);
    if (sourceElementType == null) return;

    // If source element type is assignable to target element type,
    // .of() is safe and preferred
    if (_isAssignable(sourceElementType, targetElementType)) {
      rule.reportAtNode(node, arguments: [typeName]);
    }
  }

  /// Extracts the element type from an Iterable type.
  /// For `List<int>`, returns `int`. For `Set<String>`, returns `String`.
  DartType? _getIterableElementType(InterfaceType type) {
    if (type.typeArguments.isNotEmpty) {
      return type.typeArguments.first;
    }

    for (final supertype in type.element.allSupertypes) {
      if (supertype.element.name == 'Iterable' &&
          supertype.typeArguments.isNotEmpty) {
        return supertype.typeArguments.first;
      }
    }

    return null;
  }

  /// Checks if [source] is assignable to [target].
  bool _isAssignable(DartType source, DartType target) {
    if (source is DynamicType) return true;
    if (source == target) return true;

    if (source is InterfaceType && target is InterfaceType) {
      final sourceElement = source.element;
      final targetElement = target.element;

      if (sourceElement == targetElement) return true;

      for (final supertype in sourceElement.allSupertypes) {
        if (supertype.element == targetElement) return true;
      }
    }

    return false;
  }
}
