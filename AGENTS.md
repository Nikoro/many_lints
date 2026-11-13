# Many Lints

Dart analyzer plugin for lint rules, fixes and assists. Repository artifacts use English.

## Commands

```sh
dart pub get --no-example
dart format --enable-experiment=primary-constructors --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

Run `tool/setup.sh` to install the shared gates and hooks. See [quality gates](docs/quality-gates.md).

## Guidance

- [Plugin guide](docs/development/plugin-guide.md): registration, presets, diagnostic suppression, helper ownership and comment policy.
- [Rules guide](docs/development/rules-guide.md): AST patterns and existing rule implementations to reuse.
- [Fixes guide](docs/development/fixes-guide.md): safe edits and output testing.
- [Assists guide](docs/development/assists-guide.md): applicability, linked renames and behavioral differences.
- [Site guide](docs/development/site-guide.md): documentation writing, verified examples and generated catalogs.
- [Findings](findings/INDEX.md): framework constraints; read the relevant topic before changing unfamiliar code.
- Use [.agents/skills/new-lint/SKILL.md](.agents/skills/new-lint/SKILL.md) when adding a rule.
- Use [.agents/skills/release/SKILL.md](.agents/skills/release/SKILL.md) only for authorized release work.

## Comments

The shared gate accepts tool directives, public docs in `lib/many_lints.dart`, and short
`Edge case:` or tracked `Workaround:` notes. Test fixture strings retain their semantics.
Move durable knowledge into its topic guide before removing comments. Detailed policy is
in [the plugin guide](docs/development/plugin-guide.md#comments).
