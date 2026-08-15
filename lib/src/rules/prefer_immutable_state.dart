import 'package:analyzer/error/error.dart';

import '../immutable_state_rule.dart';

/// Warns when a class whose name marks it as state is not annotated with
/// `@immutable`.
///
/// State that can be mutated in place changes without anything observing the
/// change. A Riverpod notifier assigning to a field of its own state, rather
/// than replacing it, updates nothing: the reference is the same, so no
/// listener rebuilds. The same holds for any value object a project treats as
/// a snapshot. `@immutable` makes the analyzer report the mutable field where
/// it is declared.
///
/// Which classes count is decided by name, through `name_pattern` — `State$`
/// by default — and then widened to every subclass and implementor. That makes
/// the rule state-management-agnostic: it covers Riverpod, a hand-rolled
/// store, or a plain `...State` value object equally.
///
/// For Bloc and Cubit specifically, `prefer_immutable_bloc_state` recognises
/// the state class through the `Bloc<E, S>` type argument instead, which is
/// exact rather than a name match.
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
