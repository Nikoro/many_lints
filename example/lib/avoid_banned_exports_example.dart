// avoid_banned_exports
//
// Warns when a file re-exports a library banned for its location. The rule
// reports nothing until you configure it — see the `avoid_banned_exports`
// entry in example/many_lints.yaml, which bans re-exporting any `*_internal`
// library from this file to keep it out of the public API.
//
// Importing a library and re-exporting it are different decisions, so this
// rule is configured separately from `avoid_banned_imports`: a package is
// often free to depend on something it must not expose.

// LINT: matches the banned '.*_internal\.dart' pattern, so everything in that
// library would become public API — and removing it later would be breaking.
export 'banned_exports_internal.dart';

// OK: a library meant to be part of the public surface.
export 'banned_exports_api.dart';
