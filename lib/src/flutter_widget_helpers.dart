import 'package:analyzer/dart/ast/ast.dart';

/// Represents the main axis direction of a flex/multi-child widget.
enum FlexAxis { vertical, horizontal }

/// Lightweight info about a widget node in the AST.
typedef WidgetInfo = ({
  String name,
  ArgumentList argumentList,
  Expression node,
});
