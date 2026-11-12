import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../future_of_fpdart_rule.dart';
import '../type_checker.dart';

class AvoidFutureOfOption extends FutureOfFpdartRule {
  static const LintCode code = LintCode(
    'avoid_future_of_option',
    "Returning 'Future<Option>' instead of '{0}'.",
    correctionMessage:
        "Return '{0}' so the pipeline stays composable and lazy, and callers "
        "can chain with 'flatMap' instead of awaiting first.",
  );

  AvoidFutureOfOption()
    : super(
        name: 'avoid_future_of_option',
        description:
            'Warns when a function returns Future<Option> rather than the '
            'equivalent TaskOption.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  TypeChecker get wrappedChecker => optionChecker;

  @override
  String get replacementType => 'TaskOption';
}
