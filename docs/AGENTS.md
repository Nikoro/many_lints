# Docs Site - Project Context

Astro Starlight documentation site for the `many_lints` Dart linter package. Deployed to GitHub Pages at `https://nikoro.github.io/many_lints/`.

## Commands

```bash
bun install                # Install dependencies
bun run dev                # Start dev server
bun run build              # Build static site
bun run preview            # Preview built site
bun run generate           # Bootstrap rule pages from Dart source (skip existing)
bun run generate --force   # Bootstrap all rule pages (overwrite) — NOT used in CI
bun run catalogs           # Refresh Related rules sections and the preset catalog
bun run catalogs:check     # Verify generated documentation catalogs are current
```

## Tech Stack

- **Framework**: Astro 7 with Starlight theme
- **Package manager**: Bun
- **Hosting**: GitHub Pages (via `.github/workflows/docs-deploy.yaml`)
- **Content format**: MDX / Markdown with Starlight frontmatter

## Project Structure

```
docs/
  astro.config.mjs          # Astro + Starlight config (sidebar, component overrides, redirects)
  package.json              # bun project with dev/build/preview/generate scripts
  tsconfig.json
  public/
    logo.webp               # Site logo
  src/
    assets/
      custom.css            # Custom theme (Flutter docs-inspired colors, badge styling, hero layout)
    components/
      Footer.astro          # Compact custom footer with project links
      SocialIcons.astro     # Custom header links (Docs, GitHub, pub.dev with external icons)
      ThemeSelect.astro     # Icon-only dark/light toggle (replaces Starlight dropdown)
    content.config.ts       # Astro content collection config
    content/docs/
      index.mdx             # Splash landing page (hero + CTA)
      docs/
        getting-started.mdx # Quick setup guide
        configuration.mdx   # Installation, diagnostics config, suppression
        rules.md            # Generated category index for all rules
        rules/              # Hand-maintained rule pages organized by category
          class-naming/
          bloc-riverpod/
          riverpod-state/
          async-safety/
          widget-best-practices/
          widget-replacement/
          state-management/
          control-flow/
          collection-type/
          pattern-matching/
          type-annotations/
          code-organization/
          shorthand-patterns/
          hook-rules/
          testing-rules/
          resource-management/
          code-quality/
  scripts/
    generate-rule-pages.mjs # Generates rule docs from Dart source + examples
  dist/                     # Build output (gitignored)
```

## Assist Examples Are Executed

The before/after pairs on `docs/src/content/docs/docs/assists.md` are the only
place a reader learns what an assist emits, so they are checked against the real
thing rather than reviewed by eye.

`test/docs_assist_examples_test.dart` replays every one through a real
`PluginServer` and compares the output to the documented "After". The fixtures
live in `docs/verified/assist_examples.json`.

Two consequences when touching an assist:

- **Changing an assist's output fails this test**, naming the page section to
  update. Fix the page first, then the fixture — in that order, so the page
  stays the source of truth.
- **Adding an assist means adding a fixture.** A guard asserts the fixture count
  so an emptied file cannot make the suite vacuously green.

Note what `tool/verify_documentation.dart` does *not* cover: it proves a snippet
parses, not that it is what the code produces. A snippet can be valid Dart and
still advertise output no assist has emitted in months — the class of drift this
test exists to catch. Prose claims ("this rule reports X", "only fires on Y") are
still unverified; check them against the rule source when editing.

## Rule Pages

Rule documentation pages are **hand-maintained** and committed directly. The generation script (`scripts/generate-rule-pages.mjs`) can bootstrap new pages but does not run in CI. It exits non-zero when a rule is uncategorized, listed in multiple categories, or referenced without a matching rule source.

Each rule page follows this format:
- **Badges**: `<span class="rule-badge rule-badge--{version,warning,fix,config,category}">` — version introduced, severity, fix availability, `Configurable` (only if the rule takes options), category
- **Description**: Human-friendly 2-3 sentence explanation
- **Rationale**: Real-world context belongs either in a dedicated "Why use this rule" section or in the opening explanation when a separate section would only repeat it
- **Don't / Do**: Separate code blocks showing bad and good patterns
- **Turning this rule off**: Optional convenience section. The canonical enable/disable and exclusion instructions live on the Configuration page, so older concise pages do not need to repeat them
- **Options** (configurable rules only): a sibling `##` heading, not nested under the section above
- **Related rules**: Generated as the final section by `bun run catalogs`. Review the suggested links after adding or moving a rule; explicit opposing conventions are maintained in `update-documentation-catalogs.mjs`

The all-rules index at `docs/rules/` and the preset catalog are generated by
`bun run catalogs` from the same rule pages. Do not edit either generated
catalog by hand; update the rule page metadata or the catalog script instead.

### Write plainly

The reader is a programmer looking up why a warning fired and how to clear it.
Answer that, then stop. This applies to every page on the site, not just rule
pages.

**Prose**

- Short sentences, concrete words. What the rule reports, why it is a bug, what
  to write instead.
- One paragraph of rationale is usually enough. Three is an essay.
- No rhetoric. "A repository's failures are part of its contract, not
  exceptions" gives the reader nothing to act on; "a method that throws does not
  say so in its signature, so callers cannot see the failure coming" does.
- Delete any sentence that only restates the one before it.

**Examples**

- Real code, never a description of code. A body commented `// 30 statements`
  demonstrates nothing — and since the rule counts statements, it would not even
  be reported.
- Self-contained and compiling: no helpers defined nowhere (`retry()`,
  `doWork()`, a bare `repository`), no `=> throw UnimplementedError()` standing
  in for the pipeline the page is about.
- Neutral domains — a user repository, a shopping cart, an HTTP client, config
  parsing. Not entities lifted from a particular app.
- Don't and Do must be a matched pair: the Do block fixes the Don't block rather
  than answering a different question or dropping behaviour.
- Check the Do block against the other rules. Advice that trips a sibling rule
  is a bug — `handle_bloc_event_subclasses` once recommended `emit(state)`,
  which `emit_new_bloc_state_instances` reports under the `core` preset.

Short is not a defect. A rule about one line gets a one-line example; padding it
out makes the page worse.

**Configuration goes above the example it produces.** A rule that reports
nothing until configured — the `banned_*` family, `match_pattern`, the affix and
ordering rules — must show real, copy-pasteable YAML immediately before the
Don't/Do pair. Describing it in a code comment (`// With an entry banning
'data':`) fails twice: the reader cannot copy it, and never sees the actual
entry shape. Where an example depends on a non-default option, state it in prose
beside the fence — "With `max_imports: 5`" — which the gate also runs.

**Prefer several small examples to one large one.** A `### scenario` heading, its
YAML, then its Don't/Do reads better than a single block trying to carry every
case, and it lets a reader find the one that matches their situation.

**Do not narrate the implementation.** Sections titled "How matching works", or
prose explaining internal guard rails and why an option is parsed a certain way,
belong in the source. Document what a user writes and what they get back. A
"Known limitations" section is worth keeping when it answers "why didn't mine
fire" — that is user-visible behaviour, not internals.

### Rule Examples Are Executed

`test/docs_rule_examples_test.dart` takes the `## Don't` block from every rule
page, runs it through a real `PluginServer`, and fails if the rule that page
documents does not report on it. This is the rule-page counterpart of the assist
test described above, and it exists because `tool/verify_documentation.dart`
proves only that a snippet *parses* — it tries eleven wrapper contexts until one
sticks, so `int _useData() => useState(42)` passes despite `useState` returning
`ValueNotifier<int>`.

Consequences when writing or editing a page:

- **A described example fails CI.** Write the code the rule actually reports.
- **Options-dependent examples state the option in prose beside them** — "With
  `max_imports: 5`" — and the harness runs that value, so the printed number and
  the checked behaviour cannot drift apart.
- **Not every page is checked.** A page is skipped, with the reason printed, when
  the rule keys on Flutter, Riverpod, Bloc, hook or `package:test` types the
  stubs do not carry, or when the snippet leans on an undeclared identifier. A
  floor test fails if that coverage shrinks, so stubbing gaps cannot quietly
  hollow the suite out. Widening a stub moves pages from skipped to checked.

### Configurable rules use `.mdx`

The 123 rules that accept options are `.mdx`, not `.md`, because every options snippet is
shown in both supported locations via Starlight tabs:

```mdx
import { Tabs, TabItem } from '@astrojs/starlight/components';

<Tabs syncKey="many-lints-config-file">
<TabItem label="analysis_options.yaml">
...a `# analysis_options.yaml` block, nested under a top-level `many_lints:` key...
</TabItem>
<TabItem label="many_lints.yaml">
...the same block at the top level, headed `# many_lints.yaml`...
</TabItem>
</Tabs>
```

The shared `syncKey` makes every tab group on the site switch together, so a reader
picks their config file once. Never show an options snippet in only one location, and
always keep the `# <filename>` comment as the snippet's first line — that comment is
what tells the reader where the YAML goes.

`generate-rule-pages.mjs` checks for both extensions and will not overwrite a `.mdx`
page, even under `--force`.

**Adding a new rule page**: Create a `.md` file (or `.mdx`, if the rule has options) in the appropriate category directory under `docs/src/content/docs/docs/rules/`. Use an existing page as a template. Determine the version tag from git history. A rule with options must also be added to the table under "Per-rule options" in `configuration.mdx`.

**Adding a new category**: Add the directory under `rules/` AND add a matching entry in the `sidebar` array in `astro.config.mjs`.

## Sidebar Configuration

Defined in `astro.config.mjs`. Top-level pages are explicit slugs; rule categories use `autogenerate` to pick up all `.md` and `.mdx` files in each category directory. Rules with quick fixes get a blue "Fix" badge via Starlight's `badge` frontmatter. Starlight allows only one sidebar badge per page, so `Configurable` is shown on the rule page itself rather than in the sidebar.

## Theming & Component Overrides

Custom CSS in `src/assets/custom.css`:
- Color scheme inspired by Flutter docs (dark blue `#0468D7` accent, same in both themes)
- Dark and light mode variables
- Custom badge colors for sidebar "Fix" indicators (`.sl-badge.tip`)
- Rule page badges (`.rule-badge--version`, `--warning`, `--fix`, `--config`, `--category`) with dark/light mode
- Vertically + horizontally centered splash hero layout
- Styled "Get Started" button (rounded rectangle, white text on accent)

Starlight component overrides (registered in `astro.config.mjs` under `components`):
- `Footer.astro` — Replaces the default footer with a compact project footer and links.
- `SocialIcons.astro` — Replaces default icon-only social links with text labels ("Docs", "GitHub", "pub.dev"). External links get an arrow icon and open in new tabs.
- `ThemeSelect.astro` — Replaces the dropdown theme selector with a single sun/moon icon toggle (dark/light only, no "auto").

## Deployment

GitHub Actions workflow (`.github/workflows/docs-deploy.yaml`):
1. Triggers on pushes to `main` that touch `docs/**`
2. Installs Dart dependencies and runs `tool/verify_documentation.dart`
3. Installs bun and builds with `bun run build`
4. Deploys `docs/dist/` to GitHub Pages

## Routing

`/many_lints/docs/` redirects to `/many_lints/docs/getting-started/` via Astro's `redirects` config in `astro.config.mjs`.
