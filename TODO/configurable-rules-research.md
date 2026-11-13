# Configuration follow-ups

## Package identity overrides

Consider a global `package_names` option only after a project reports a real fork
or wrapper that cannot use the pinned TypeCheckers. Intermediate subclasses are
already handled through supertypes and do not justify this option. A name-only
fallback would widen matches to unrelated user types.

## Rule ideas to evaluate

- Required import aliases for configured packages, with an optional alias pattern.
- Widget-type bans scoped by path; first check whether existing `avoid_banned_types`
  configuration expresses the requirement.
- Layer dependency checks remain import-level: PluginServer does not invoke a
  pubspec visitor, so a rule cannot promise pubspec validation.

[Regression boundaries](../docs/development/regression-boundaries.md) owns the
configuration and helper constraints established by the completed investigation.
