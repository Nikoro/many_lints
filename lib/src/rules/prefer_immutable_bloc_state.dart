import 'package:analyzer/error/error.dart';

import '../immutable_state_rule.dart';

/// Warns when a Bloc or Cubit state class is not annotated with `@immutable`.
///
/// `emit` compares the new state against the current one and does nothing when
/// they are equal. Mutating a state object in place therefore produces a state
/// change no listener ever sees — the reference did not change, so `emit`
/// discards it. `@immutable` makes the analyzer say so where the field is
/// declared, rather than leaving it to be found as a UI that will not update.
///
/// The state class is recognised through the type argument of `Bloc<E, S>` or
/// `Cubit<S>`, and then widened to every subclass and implementor. That makes
/// the rule inert in a project without the `bloc` package, which is the point:
/// `prefer_immutable_state` is the state-management-agnostic version that
/// matches on the class name instead.
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
