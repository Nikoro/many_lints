---
name: release
description: Automate release preparation for the many_lints package. Determines version bump, updates pubspec.yaml/README.md/CHANGELOG.md, commits, tags, and pushes. Use when the user wants to publish a new release.
---

You are preparing a new release for the **many_lints** Dart linter package. The user may optionally provide a version number or bump keyword.

## Step 1: Parse User Input

Extract from `$ARGUMENTS`:
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
   - No user-facing commits (only `chore`, `test`, `ci`, `build`) → Use `AskUserQuestion` to ask whether to proceed with a PATCH release or abort

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

Use `AskUserQuestion` to confirm: "Does this release summary look correct? Should I proceed with updating files?"

Allow the user to request edits to the CHANGELOG content before proceeding.

## Step 7: Update Files

1. **`pubspec.yaml`**: Update the `version:` field to the new version.

2. **`README.md`**: Find **all** lines matching the pattern `many_lints: ^` or `version: ^` followed by a semver version and update them to `^X.Y.Z`. There are two occurrences: the simple plugin syntax (`many_lints: ^X.Y.Z`) and the extended syntax with diagnostics (`version: ^X.Y.Z`). Do NOT hardcode line numbers — use pattern matching to find them robustly.

3. **`CHANGELOG.md`**: Insert the new version section at the top of the file, directly after the `# Changelog` heading. Preserve all existing content below.

## Step 8: Commit & Tag

1. Stage changes: `git add pubspec.yaml README.md CHANGELOG.md`
2. Create commit:
   ```
   git commit -m "chore(release): bump version to X.Y.Z"
   ```
3. Create annotated tag:
   ```
   git tag -a vX.Y.Z -m "Release version X.Y.Z"
   ```

## Step 9: Push to Repository

**IMPORTANT**: Pushing the tag will trigger the `release.yaml` CI workflow, which publishes to pub.dev. This is irreversible.

Use `AskUserQuestion` to confirm: "Ready to push? This will trigger pub.dev publishing and create a GitHub release."

If confirmed:
```
git push origin main --follow-tags
```

After pushing, inform the user:
- The `release.yaml` workflow has been triggered
- It will: validate the version, run checks, publish to pub.dev, and create a GitHub release
- They can monitor progress at: `https://github.com/Nikoro/many_lints/actions`

If something goes wrong after push, provide rollback instructions:
```bash
# Delete remote tag
git push origin :refs/tags/vX.Y.Z
# Delete local tag
git tag -d vX.Y.Z
# Revert the release commit
git revert HEAD
git push origin main
```
