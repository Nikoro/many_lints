import 'package:analyzer/dart/ast/ast.dart';

enum FlexAxis { vertical, horizontal }

typedef WidgetInfo = ({
  String name,
  ArgumentList argumentList,
  Expression node,
});
