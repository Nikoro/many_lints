// avoid_long_files
//
// Detects a file longer than the configured line budget.
//
// A demonstration file cannot be 300 lines long and still be worth reading,
// so this example lowers the budget to 20 lines instead:
//
//   avoid_long_files:
//     max_lines: 20
//
// LINT: this file is over the budget configured for it.
//
// Blank lines and comments do not count by default — a file is not hard to
// navigate because it is well documented — so the code below is what pushes
// it over. Set `count_comments: true` to include them.
//
// ✅ Good: split the file along its subjects, so the name at the top
// describes everything under it. Generated files are the obvious exception
// and belong in the rule's `exclude`:
//
//   avoid_long_files:
//     exclude: ["**/*.g.dart", "**/*.freezed.dart"]

const a = 1;
const b = 2;
const c = 3;
const d = 4;
const e = 5;
const f = 6;
const g = 7;
const h = 8;
const i = 9;
const j = 10;
const k = 11;
const l = 12;
const m = 13;
const n = 14;
const o = 15;
const p = 16;
const q = 17;
const r = 18;
const s = 19;
const t = 20;
const u = 21;
const v = 22;
