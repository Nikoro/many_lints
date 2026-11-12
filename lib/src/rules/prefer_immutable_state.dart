import 'package:analyzer/error/error.dart';

import '../immutable_state_rule.dart';

class PreferImmutableState extends ImmutableStateRule {
  static const LintCode code = LintCode(
    'prefer_immutable_state',
    'State classes should be annotated with @immutable.',
    correctionMessage: "Add '@immutable' annotation to this class.",
  );

  PreferImmutableState()
    : super(
        name: 'prefer_immutable_state',
        description:
            'Warns when a class whose name matches the configured state '
            'pattern lacks the @immutable annotation.',
        detection: StateDetection.namePattern,
      );

  @override
  LintCode get diagnosticCode => code;
}
