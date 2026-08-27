# Verified documentation examples

Each file here is a **Before** snippet from
`docs/src/content/docs/docs/assists.md`, together with the assist that is
applied to it and the **After** snippet the page claims comes out.

`test/docs_assist_examples_test.dart` runs every one of them through a real
`PluginServer` and compares the result to the recorded `after`. A change to an
assist that alters its output therefore fails the test until the documentation
page is updated to match — the failure names the page section, so the fix is to
edit the prose, not this file.

Fields:

- `section` — the `##`/`###` heading on the page the example sits under.
- `assist` — the assist id applied.
- `cursor` — the token in `before` the cursor is placed on, marked `^`.
- `before` / `after` — the two halves of the documented example, expanded into
  a compilable library. The page shows them trimmed to the interesting lines;
  the surrounding declarations here exist only so the snippet resolves.
