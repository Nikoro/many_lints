import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../type_checker.dart';

/// Fix that replaces an EdgeInsets constructor with a simpler alternative.
class PreferCorrectEdgeInsetsConstructorFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferCorrectEdgeInsetsConstructor',
    DartFixKindPriority.standard,
    'Use simpler EdgeInsets constructor',
  );

  PreferCorrectEdgeInsetsConstructorFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  static const _edgeInsetsChecker = TypeChecker.fromName(
    'EdgeInsets',
    packageName: 'flutter',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final String? constructorName;
    final ArgumentList argumentList;

    if (targetNode is InstanceCreationExpression) {
      final staticType = targetNode.staticType;
      if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
        return;
      }
      constructorName = targetNode.constructorName.name?.name;
      argumentList = targetNode.argumentList;
    } else if (targetNode is MethodInvocation) {
      final staticType = targetNode.staticType;
      if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
        return;
      }
      constructorName = targetNode.methodName.name;
      argumentList = targetNode.argumentList;
    } else {
      return;
    }

    final replacement = _computeReplacement(constructorName, argumentList);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }

  String? _computeReplacement(
    String? constructorName,
    ArgumentList argumentList,
  ) {
    return switch (constructorName) {
      'fromLTRB' => _replaceFromLTRB(argumentList),
      'only' => _replaceOnly(argumentList),
      'symmetric' => _replaceSymmetric(argumentList),
      'all' => _replaceAll(argumentList),
      _ => null,
    };
  }

  String? _replaceFromLTRB(ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.length != 4) return null;

    final l = args[0].toSource();
    final t = args[1].toSource();
    final r = args[2].toSource();
    final b = args[3].toSource();

    if (_isZero(l) && _isZero(t) && _isZero(r) && _isZero(b)) {
      return 'EdgeInsets.zero';
    }

    if (l == t && t == r && r == b) {
      return 'EdgeInsets.all($l)';
    }

    if (l == r && t == b) {
      final horizontal = !_isZero(l);
      final vertical = !_isZero(t);
      if (horizontal && vertical) {
        return 'EdgeInsets.symmetric(horizontal: $l, vertical: $t)';
      } else if (horizontal) {
        return 'EdgeInsets.symmetric(horizontal: $l)';
      } else if (vertical) {
        return 'EdgeInsets.symmetric(vertical: $t)';
      }
    }

    final hasLeft = !_isZero(l);
    final hasTop = !_isZero(t);
    final hasRight = !_isZero(r);
    final hasBottom = !_isZero(b);
    final nonZeroCount = [
      hasLeft,
      hasTop,
      hasRight,
      hasBottom,
    ].where((e) => e).length;

    if (nonZeroCount < 4) {
      final parts = <String>[];
      if (hasLeft) parts.add('left: $l');
      if (hasTop) parts.add('top: $t');
      if (hasRight) parts.add('right: $r');
      if (hasBottom) parts.add('bottom: $b');
      return 'EdgeInsets.only(${parts.join(', ')})';
    }

    return null;
  }

  String? _replaceOnly(ArgumentList argumentList) {
    final args = argumentList.arguments;

    String? left;
    String? top;
    String? right;
    String? bottom;

    for (final arg in args.whereType<NamedExpression>()) {
      switch (arg.name.label.name) {
        case 'left':
          left = arg.expression.toSource();
        case 'top':
          top = arg.expression.toSource();
        case 'right':
          right = arg.expression.toSource();
        case 'bottom':
          bottom = arg.expression.toSource();
      }
    }

    final l = left ?? '0';
    final t = top ?? '0';
    final r = right ?? '0';
    final b = bottom ?? '0';

    if (_isZero(l) && _isZero(t) && _isZero(r) && _isZero(b)) {
      return 'EdgeInsets.zero';
    }

    if (l == t && t == r && r == b) {
      return 'EdgeInsets.all($l)';
    }

    if (l == r && t == b) {
      final horizontal = !_isZero(l);
      final vertical = !_isZero(t);
      if (horizontal && vertical) {
        return 'EdgeInsets.symmetric(horizontal: $l, vertical: $t)';
      } else if (horizontal) {
        return 'EdgeInsets.symmetric(horizontal: $l)';
      } else if (vertical) {
        return 'EdgeInsets.symmetric(vertical: $t)';
      }
    }

    return null;
  }

  String? _replaceSymmetric(ArgumentList argumentList) {
    final args = argumentList.arguments;

    String? horizontal;
    String? vertical;

    for (final arg in args.whereType<NamedExpression>()) {
      switch (arg.name.label.name) {
        case 'horizontal':
          horizontal = arg.expression.toSource();
        case 'vertical':
          vertical = arg.expression.toSource();
      }
    }

    final h = horizontal ?? '0';
    final v = vertical ?? '0';

    if (_isZero(h) && _isZero(v)) {
      return 'EdgeInsets.zero';
    }

    if (h == v) {
      return 'EdgeInsets.all($h)';
    }

    return null;
  }

  String? _replaceAll(ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.isEmpty) return null;

    final value = args.first.toSource();
    if (_isZero(value)) {
      return 'EdgeInsets.zero';
    }

    return null;
  }

  static bool _isZero(String source) {
    return source == '0' || source == '0.0';
  }
}
