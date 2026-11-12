import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../future_of_fpdart_rule.dart';
import '../type_checker.dart';

class AvoidFutureOfEither extends FutureOfFpdartRule {
  static const LintCode code = LintCode(
    'avoid_future_of_either',
    "Returning 'Future<Either>' instead of '{0}'.",
    correctionMessage:
        "Return '{0}' so the pipeline stays composable and lazy, and callers "
        "can chain with 'flatMap' instead of awaiting first.",
  );

  AvoidFutureOfEither()
    : super(
        name: 'avoid_future_of_either',
        description:
            'Warns when a function returns Future<Either> rather than the '
            'equivalent TaskEither.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  TypeChecker get wrappedChecker => eitherChecker;

  @override
  String get replacementType => 'TaskEither';
}
