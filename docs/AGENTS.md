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
```

## Tech Stack

- **Framework**: Astro 6 with Starlight theme
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
      SocialIcons.astro     # Custom header links (Docs, GitHub, pub.dev with external icons)
      ThemeSelect.astro     # Icon-only dark/light toggle (replaces Starlight dropdown)
    content.config.ts       # Astro content collection config
    content/docs/
      index.mdx             # Splash landing page (hero + CTA)
      docs/
        getting-started.mdx # Quick setup guide
        configuration.md    # Installation, diagnostics config, suppression
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

## Rule Pages

Rule documentation pages are **hand-maintained** and committed directly. The generation script (`scripts/generate-rule-pages.mjs`) can bootstrap new pages but does not run in CI.

Each rule page follows this format:
- **Badges**: `<span class="rule-badge rule-badge--{version,warning,fix,category}">` — version introduced, severity, fix availability, category
- **Description**: Human-friendly 2-3 sentence explanation
- **Why use this rule**: Real-world context with "See also" links to official docs
- **Don't / Do**: Separate code blocks showing bad and good patterns
- **Configuration**: YAML snippet to disable the rule

**Adding a new rule page**: Create a `.md` file in the appropriate category directory under `docs/src/content/docs/docs/rules/`. Use an existing page as a template. Determine the version tag from git history.

**Adding a new category**: Add the directory under `rules/` AND add a matching entry in the `sidebar` array in `astro.config.mjs`.

## Sidebar Configuration

Defined in `astro.config.mjs`. Top-level pages are explicit slugs; rule categories use `autogenerate` to pick up all `.md` files in each category directory. Rules with quick fixes get a blue "Fix" badge via Starlight's `badge` frontmatter.

## Theming & Component Overrides

Custom CSS in `src/assets/custom.css`:
- Color scheme inspired by Flutter docs (dark blue `#0468D7` accent, same in both themes)
- Dark and light mode variables
- Custom badge colors for sidebar "Fix" indicators (`.sl-badge.tip`)
- Rule page badges (`.rule-badge--version`, `--warning`, `--fix`, `--category`) with dark/light mode
- Vertically + horizontally centered splash hero layout
- Styled "Get Started" button (rounded rectangle, white text on accent)

Starlight component overrides (registered in `astro.config.mjs` under `components`):
- `SocialIcons.astro` — Replaces default icon-only social links with text labels ("Docs", "GitHub", "pub.dev"). External links get an arrow icon and open in new tabs.
- `ThemeSelect.astro` — Replaces the dropdown theme selector with a single sun/moon icon toggle (dark/light only, no "auto").

## Deployment

GitHub Actions workflow (`.github/workflows/docs-deploy.yaml`):
1. Triggers on pushes to `main` that touch `docs/**`
2. Installs bun, builds with `bun run build`
3. Deploys `docs/dist/` to GitHub Pages

## Routing

`/many_lints/docs/` redirects to `/many_lints/docs/getting-started/` via Astro's `redirects` config in `astro.config.mjs`.
