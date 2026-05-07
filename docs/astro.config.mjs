import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://nikoro.github.io',
  base: '/many_lints/',
  redirects: {
    '/docs/': '/many_lints/docs/getting-started/',
  },
  integrations: [
    starlight({
      title: 'Many Lints',
      favicon: '/favicon.ico',
      expressiveCode: {
        themes: ['github-light', 'github-dark'],
        styleOverrides: {
          borderColor: '#dce1e8',
          borderRadius: '8px',
        },
      },
      components: {
        SocialIcons: './src/components/SocialIcons.astro',
        ThemeSelect: './src/components/ThemeSelect.astro',
        Footer: './src/components/Footer.astro',
      },
      customCss: ['./src/assets/custom.css'],
      sidebar: [
        { label: 'Getting Started', slug: 'docs/getting-started' },
        { label: 'Configuration', slug: 'docs/configuration' },
        {
          label: 'Rules',
          items: [
            {
              label: 'Class Naming',
              items: [{ autogenerate: { directory: 'docs/rules/class-naming' } }],
            },
            {
              label: 'Bloc / Riverpod',
              items: [{ autogenerate: { directory: 'docs/rules/bloc-riverpod' } }],
            },
            {
              label: 'Riverpod State',
              items: [{ autogenerate: { directory: 'docs/rules/riverpod-state' } }],
            },
            {
              label: 'Async Safety',
              items: [{ autogenerate: { directory: 'docs/rules/async-safety' } }],
            },
            {
              label: 'Widget Best Practices',
              items: [{ autogenerate: { directory: 'docs/rules/widget-best-practices' } }],
            },
            {
              label: 'Widget Replacement',
              items: [{ autogenerate: { directory: 'docs/rules/widget-replacement' } }],
            },
            {
              label: 'State Management',
              items: [{ autogenerate: { directory: 'docs/rules/state-management' } }],
            },
            {
              label: 'Control Flow',
              items: [{ autogenerate: { directory: 'docs/rules/control-flow' } }],
            },
            {
              label: 'Collection & Type',
              items: [{ autogenerate: { directory: 'docs/rules/collection-type' } }],
            },
            {
              label: 'Pattern Matching',
              items: [{ autogenerate: { directory: 'docs/rules/pattern-matching' } }],
            },
            {
              label: 'Type Annotations',
              items: [{ autogenerate: { directory: 'docs/rules/type-annotations' } }],
            },
            {
              label: 'Code Organization',
              items: [{ autogenerate: { directory: 'docs/rules/code-organization' } }],
            },
            {
              label: 'Shorthand Patterns',
              items: [{ autogenerate: { directory: 'docs/rules/shorthand-patterns' } }],
            },
            {
              label: 'Hook Rules',
              items: [{ autogenerate: { directory: 'docs/rules/hook-rules' } }],
            },
            {
              label: 'Testing Rules',
              items: [{ autogenerate: { directory: 'docs/rules/testing-rules' } }],
            },
            {
              label: 'Resource Management',
              items: [{ autogenerate: { directory: 'docs/rules/resource-management' } }],
            },
            {
              label: 'Code Quality',
              items: [{ autogenerate: { directory: 'docs/rules/code-quality' } }],
            },
          ],
        },
      ],
    }),
  ],
});
