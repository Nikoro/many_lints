import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferTypedExceptions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_typed_exceptions',
    "Throwing '{0}' gives callers nothing to catch selectively.",
    correctionMessage:
        'Throw a named type so callers can catch this failure and no other.',
  );

  PreferTypedExceptions()
    : super(
        name: 'prefer_typed_exceptions',
        description:
            'Warns when a throw does not name a type a caller could catch '
            'selectively.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _defaultSelfDescribingSdkTypes = {
    'ArgumentError',
    'AssertionError',
    'ConcurrentModificationError',
    'FormatException',
    'IndexError',
    'RangeError',
    'StateError',
    'UnimplementedError',
    'UnsupportedError',
  };

  static const _messageOnlyCoreThrowables = {'Exception', 'Error'};

  final PreferTypedExceptions rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    final type = node.expression.staticType;
    if (type == null || type is DynamicType) return;

    final element = type.element;
    if (element is! InterfaceElement) {
      rule.reportAtNode(node, arguments: [type.getDisplayString()]);
      return;
    }

    final name = element.name;
    final isOutsideDartCore = !element.library.isDartCore;
    if (isOutsideDartCore) {
      if (!_isThrowable(element)) {
        rule.reportAtNode(node, arguments: [type.getDisplayString()]);
      }
      return;
    }

    final selfDescribingSdkTypes = rule.config.nameSetOption(
      'allow',
      defaultValue: _defaultSelfDescribingSdkTypes,
    );
    if (name != null && selfDescribingSdkTypes.contains(name)) return;

    rule.reportAtNode(node, arguments: [name ?? type.getDisplayString()]);
  }

  bool _isThrowable(InterfaceElement element) {
    if (_isCoreThrowable(element)) return true;

    return element.allSupertypes.any(
      (supertype) => _isCoreThrowable(supertype.element),
    );
  }

  bool _isCoreThrowable(InterfaceElement element) =>
      element.library.isDartCore &&
      _messageOnlyCoreThrowables.contains(element.name);
}
