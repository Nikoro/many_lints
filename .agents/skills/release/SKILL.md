---
name: release
description: Automate release preparation for the many_lints package. Determines the version bump, synchronizes package and documentation metadata, validates the release, commits, tags, and pushes. Use when the user wants to publish a new release.
---

You are preparing a new release for the **many_lints** Dart linter package. The user may optionally provide a version number or bump keyword.

## Step 1: Parse User Input

Extract from the user's request:
- **Explicit version** (e.g., `0.3.0`, `1.0.0`) — use this exact version
- **Bump keyword** (`major`, `minor`, or `patch`) — apply this bump to the current version
- **Empty** — auto-determine the bump type from commit analysis

## Step 2: Pre-flight Checks

Run these checks before doing anything else. If any fail, **abort immediately** with a clear error message.

1. **Clean working tree**: Run `git status --porcelain`. If there is any output, abort — tell the user to commit or stash their changes first.
2. **On main branch**: Run `git branch --show-current`. If the result is not `main`, abort — tell the user to switch to `main`.
3. **In sync with remote**: Run `git fetch origin main` then compare `git rev-parse HEAD` with `git rev-parse origin/main`. If they differ, abort — tell the user to pull or push first.

## Step 3: Quality Gates

Run these checks to ensure the package is in a releasable state. If any fail, **abort** and ask the user to fix the issues first.

1. `dart analyze` — must produce **zero** issues (errors, warnings, or infos)
2. `dart test` — all tests must pass
3. `dart format --output=none --set-exit-if-changed .` — formatting must be clean
4. `dart pub publish --dry-run` — package validation must pass
5. `bun run build` from `docs/` — documentation must build successfully

## Step 4: Analyze Commits & Determine Version

1. Get the latest git tag: `git describe --tags --abbrev=0`
2. Get current version from `pubspec.yaml` (the `version:` field)
3. List all commits since the latest tag: `git log <latest_tag>..HEAD --oneline`
4. Parse each commit using Conventional Commits format (`type(scope): description`):
   - Extract the **type** (e.g., `feat`, `fix`, `refactor`)
   - Extract the **scope** if present (e.g., `lint`, `fixes`, `core`)
   - Extract the **description**
   - Check for breaking changes: `BREAKING CHANGE:` in body/footer or `!` after type (e.g., `feat!:`)

5. **Determine version bump** (unless user provided explicit version or keyword):
   - Any breaking change → **MAJOR** bump
   - Any `feat` commit → **MINOR** bump
   - Only `fix`, `refactor`, `style`, `perf`, `docs` → **PATCH** bump
   - No user-facing commits (only `chore`, `test`, `ci`, `build`) → ask the user whether to proceed with a PATCH release or abort, using the available input mechanism

6. If user provided a bump keyword (`major`/`minor`/`patch`), apply it to the current version.
7. If user provided an explicit version, validate it is higher than the current version.

## Step 5: Generate CHANGELOG Entry

Map commits to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) categories:

| Commit type          | CHANGELOG category | Include? |
|----------------------|--------------------|----------|
| `feat`               | **Added**          | Yes      |
| `fix`                | **Fixed**          | Yes      |
| `refactor`           | **Changed**        | Yes      |
| `style`              | **Changed**        | Yes      |
| `perf`               | **Changed**        | Yes      |
| `chore`              | —                  | Skip     |
| `test`               | —                  | Skip     |
| `ci`                 | —                  | Skip     |
| `build`              | —                  | Skip     |
| `docs`               | —                  | Skip     |
| `chore(release)`     | —                  | Skip     |

Rules:
- **Only include categories that have actual entries.** Do NOT add empty categories.
- Write **human-friendly descriptions**, not raw commit messages. For example:
  - Commit: `feat(lint): add avoid_foo rule, quick fix, tests, and example`
  - Changelog: `- \`avoid_foo\` rule to detect <brief description of what it detects>`
- Group related commits when appropriate (e.g., multiple fixes for the same rule).

Format:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added

- `rule_name` rule description

### Fixed

- Fix description
```

## Step 6: Review & Confirm

Present a summary to the user before making any file changes:

```
Release Summary
───────────────
Current version: A.B.C
New version:     X.Y.Z (BUMP_TYPE bump)

Commits since last release: N total (M user-facing, K skipped)

CHANGELOG preview:
──────────────────
## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Fixed
- ...
```

Ask the user to confirm: "Does this release summary look correct? Should I proceed with updating files?" Use the input mechanism available in the current environment.

Allow the user to request edits to the CHANGELOG content before proceeding.

## Step 7: Update Files

1. **`pubspec.yaml`**: Update the `version:` field to the new version.

2. **Published-version references**: Find every install/configuration example that
   names the package version and update it to `X.Y.Z`. Do not rely on a fixed
   number of occurrences; search for the old version and verify that none remain.
   The maintained locations are:
   - `README.md`
   - `docs/src/content/docs/docs/configuration.md`
   - `docs/src/content/docs/docs/getting-started.mdx`
   - `example/README.md`
   - the package documentation example in `lib/many_lints.dart`

   **If the release changes the `analyzer` dependency**, also update the analyzer version badge in `README.md` (the `img.shields.io/badge/analyzer-<version>-blue` line — update both the `src` URL and the `alt` text) to the analyzer version from `pubspec.lock`. Additionally check that the `environment.sdk` constraint in `pubspec.yaml` and `example/pubspec.yaml` and the pinned `sdk:` version in `.github/workflows/*.yaml` satisfy the new analyzer's minimum SDK requirement — a mismatch makes CI fail at `dart pub get` after the tag is pushed. Finally, update the "Requires Dart X.Y+ (Flutter A.B+)" line in `README.md`, `docs/src/content/docs/docs/configuration.md`, and `docs/src/content/docs/docs/getting-started.mdx` to match the new minimum Dart SDK and the Flutter stable release that ships it.

3. **`CHANGELOG.md`**: Insert the new version section at the top of the file, directly after the `# Changelog` heading. Preserve all existing content below.

4. **Generated counts and indexes**: derive the registered rule count from the
   `_registerWarningRule(registry, ...)` calls inside `ManyLintsPlugin.register`
   (do not count the helper definition), then synchronize any prose or tables that state the
   total in `README.md`, the docs pages, and `example/README.md`. Verify that:
   - every registered rule has one docs page and one example;
   - the example README table contains every registered rule exactly once;
   - `docs/scripts/generate-rule-pages.mjs` categorizes every rule exactly once.

   Validate these sets explicitly. Running `bun run generate` alone is not a
   sufficient gate because the generator skips existing pages and does not fail
   for duplicate category entries.

   Do NOT update version badges on rule pages (`rule-badge--version`) — those are
   historical and indicate the version that introduced each rule.

5. Search the repository for the previous package version and previous rule
   count. Review each remaining match explicitly; historical changelog entries
   and rule-introduction badges are expected, current setup instructions are not.

## Step 8: Commit & Tag

1. Repeat the format, analyze, test, and docs-build gates from Step 3 after the
   version, changelog, and docs edits. Run the final publish dry-run after the
   release commit so the dirty working tree does not create a false failure.
2. Review `git diff`, then stage every release-consistency file changed in Step
   7. At minimum this normally includes `pubspec.yaml`, `README.md`,
   `CHANGELOG.md`, both setup docs, `example/README.md`, and
   `lib/many_lints.dart`.
3. Create commit:
   ```
   git commit -m "chore(release): bump version to X.Y.Z"
   ```
4. Run `dart pub publish --dry-run`. If it fails, fix the problem, repeat the
   relevant gates, amend the release commit, and rerun the dry-run. Do not tag
   until it passes from a clean working tree.
5. Create annotated tag:
   ```
   git tag -a vX.Y.Z -m "Release version X.Y.Z"
   ```

## Step 9: Push to Repository

**IMPORTANT**: Pushing the tag will trigger the `release.yaml` CI workflow, which publishes to pub.dev. This is irreversible.

Ask the user to confirm: "Ready to push? This will trigger pub.dev publishing and create a GitHub release." Use the input mechanism available in the current environment.

If confirmed:
```
git push origin main vX.Y.Z
```

After pushing, inform the user:
- The `release.yaml` workflow has been triggered
- It will: validate the version, run checks, publish to pub.dev, and create a GitHub release
- They can monitor progress at: `https://github.com/Nikoro/many_lints/actions`

If something goes wrong after push, explain that a pub.dev publication cannot
be rolled back. The following commands only repair Git/GitHub metadata; they do
not remove or replace the published package:
```bash
# Delete remote tag
git push origin :refs/tags/vX.Y.Z
# Delete local tag
git tag -d vX.Y.Z
# Revert the release commit
git revert HEAD
git push origin main
```
