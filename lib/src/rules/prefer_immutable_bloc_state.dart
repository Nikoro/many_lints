import 'package:analyzer/error/error.dart';

import '../immutable_state_rule.dart';

class PreferImmutableBlocState extends ImmutableStateRule {
  static const LintCode code = LintCode(
    'prefer_immutable_bloc_state',
    'Bloc state classes should be annotated with @immutable.',
    correctionMessage: "Add '@immutable' annotation to this class.",
  );

  PreferImmutableBlocState()
    : super(
        name: 'prefer_immutable_bloc_state',
        description:
            'Warns when a class used as the state of a Bloc or Cubit lacks '
            'the @immutable annotation.',
        detection: StateDetection.blocTypeArgument,
      );

  @override
  LintCode get diagnosticCode => code;
}
