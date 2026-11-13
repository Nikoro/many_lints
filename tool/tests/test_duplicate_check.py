import json
import os
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from repository_environment import isolated_environment

ROOT = Path(__file__).resolve().parents[2]
CANARY = "\n".join(
    [
        "int calculateReceipt(int subtotal) {",
        *[f"  subtotal = subtotal * {value} + {value + 1};" for value in range(2, 18)],
        "  return subtotal;",
        "}",
        "",
    ]
)
POLICY = runpy.run_path(str(ROOT / "scripts/quality/check_duplicates.py"))[
    "POLICY_FILES"
]


class DuplicateCheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.environment = isolated_environment(os.environ)
        self.environment.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        for name in POLICY:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if name == ".jscpd-baseline.json":
                target.write_text('{"version":1,"fingerprints":{}}\n', encoding="utf-8")
            else:
                shutil.copy2(ROOT / name, target)
        config = json.loads((self.root / ".jscpd.json").read_text(encoding="utf-8"))
        config["path"] = ["lib"]
        (self.root / ".jscpd.json").write_text(json.dumps(config), encoding="utf-8")
        (self.root / "lib").mkdir()
        (self.root / "lib/receipt.dart").write_text(CANARY, encoding="utf-8")
        (self.root / ".gitignore").write_text(
            "scripts/quality/js/node_modules/\nbuild/\n", encoding="utf-8"
        )
        self.git("init", "-q")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("add", ".")
        self.git("commit", "-qm", "fixture baseline")

    def git(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            env=self.environment,
            check=True,
            capture_output=True,
            encoding="utf-8",
            timeout=30,
        )

    def install(self) -> None:
        source = ROOT / "scripts/quality/js/node_modules"
        if not (source / ".bin/jscpd").is_file():
            self.skipTest(
                "Install duplication tooling with npm ci --prefix scripts/quality/js"
            )
        (self.root / "scripts/quality/js/node_modules").symlink_to(
            source, target_is_directory=True
        )

    def check(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(self.root / "scripts/quality/check_duplicates.py"),
                *arguments,
            ],
            cwd=self.root,
            env=self.environment,
            check=False,
            capture_output=True,
            encoding="utf-8",
            timeout=120,
        )

    def copy_receipt(self, name: str = "refund") -> None:
        (self.root / f"lib/{name}.dart").write_text(CANARY, encoding="utf-8")

    def assert_index_flag_is_rejected(
        self, flag: str, alternate: bool, policy: bool = False
    ) -> None:
        if policy:
            path = ".jscpd-baseline.json"
        else:
            self.copy_receipt()
            path = "lib/refund.dart"
            self.git("add", path)
        normal_index = self.root / ".git/index"
        selected_index = normal_index
        if alternate:
            selected_index = self.root / ".git/alternate-index"
            shutil.copy2(normal_index, selected_index)
            self.environment["GIT_INDEX_FILE"] = str(selected_index)
        self.git("update-index", flag, "--", path)
        normal_bytes = normal_index.read_bytes()
        selected_bytes = selected_index.read_bytes()
        target = self.root / path
        target.write_text(
            target.read_text(encoding="utf-8") + "\n"
            if policy
            else "int uniqueRefund() => 0;\n",
            encoding="utf-8",
        )
        result = self.check("--staged")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("index flags", result.stderr)
        self.assertEqual(normal_index.read_bytes(), normal_bytes)
        self.assertEqual(selected_index.read_bytes(), selected_bytes)

    def test_assume_unchanged_source_is_rejected(self) -> None:
        self.assert_index_flag_is_rejected("--assume-unchanged", False)

    def test_skip_worktree_source_is_rejected(self) -> None:
        self.assert_index_flag_is_rejected("--skip-worktree", False)

    def test_assume_unchanged_selected_index_is_preserved(self) -> None:
        self.assert_index_flag_is_rejected("--assume-unchanged", True)

    def test_skip_worktree_selected_index_is_preserved(self) -> None:
        self.assert_index_flag_is_rejected("--skip-worktree", True)

    def test_assume_unchanged_policy_is_rejected(self) -> None:
        self.assert_index_flag_is_rejected("--assume-unchanged", False, True)

    def test_skip_worktree_policy_is_rejected(self) -> None:
        self.assert_index_flag_is_rejected("--skip-worktree", False, True)

    def test_ignored_untracked_source_is_rejected_in_staged_mode(self) -> None:
        self.copy_receipt()
        with (self.root / ".gitignore").open("a", encoding="utf-8") as stream:
            stream.write("lib/refund.dart\n")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("Stage new duplication sources", result.stderr)

    def test_invalid_source_formats_fail_as_policy_errors(self) -> None:
        path = self.root / ".jscpd.json"
        original = json.loads(path.read_text(encoding="utf-8"))
        cases = (
            ("missing", None),
            ("empty", []),
            ("scalar", original["format"][0]),
            ("nonstring", [1]),
            ("unsupported", ["rust"]),
        )
        for name, value in cases:
            with self.subTest(case=name):
                configuration = dict(original)
                if name == "missing":
                    configuration.pop("format")
                else:
                    configuration["format"] = value
                path.write_text(json.dumps(configuration), encoding="utf-8")
                self.git("add", ".jscpd.json")
                result = self.check("--staged")
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn("Duplication formats", result.stderr)

    def test_unstaged_tracked_generated_source_is_outside_scan(self) -> None:
        self.install()
        target = self.root / "lib/receipt.g.dart"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(CANARY, encoding="utf-8")
        self.git("add", "-f", "lib/receipt.g.dart")
        target.write_text(CANARY + "\n", encoding="utf-8")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_index_flags_on_generated_source_are_outside_scan(self) -> None:
        self.install()
        target = self.root / "lib/receipt.g.dart"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(CANARY, encoding="utf-8")
        self.git("add", "-f", "lib/receipt.g.dart")
        for flag in ("--assume-unchanged", "--skip-worktree"):
            with self.subTest(flag=flag):
                self.git("update-index", flag, "--", "lib/receipt.g.dart")
                result = self.check("--staged")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_unstaged_tracked_non_source_metadata_is_outside_scan(self) -> None:
        self.install()
        target = self.root / "lib/.env"
        target.write_text("PRIVATE_SETTING=fixture-only\n", encoding="utf-8")
        self.git("add", "-f", "lib/.env")
        target.write_text("PRIVATE_SETTING=changed-fixture-only\n", encoding="utf-8")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignored_non_source_metadata_does_not_require_staging(self) -> None:
        self.install()
        (self.root / "lib/.env").write_text(
            "PRIVATE_SETTING=fixture-only\n", encoding="utf-8"
        )
        with (self.root / ".gitignore").open("a", encoding="utf-8") as stream:
            stream.write("lib/.env\n")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignored_generated_file_does_not_require_staging(self) -> None:
        self.install()
        (self.root / "lib/receipt.g.dart").write_text(CANARY, encoding="utf-8")
        with (self.root / ".gitignore").open("a", encoding="utf-8") as stream:
            stream.write("*.g.dart\n")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_clean_source_passes_and_new_clone_fails(self) -> None:
        self.install()
        clean = self.check("--staged")
        self.assertEqual(clean.returncode, 0, clean.stdout + clean.stderr)
        self.copy_receipt()
        self.git("add", "lib/refund.dart")
        duplicate = self.check("--staged")
        self.assertEqual(duplicate.returncode, 1, duplicate.stdout + duplicate.stderr)
        report = json.loads(
            (self.root / "build/quality/duplicates/jscpd-report.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertGreater(report["statistics"]["total"]["newClones"], 0)

    def test_additional_copy_of_baselined_content_fails(self) -> None:
        self.install()
        self.copy_receipt()
        update = subprocess.run(
            [
                str(self.root / "scripts/quality/js/node_modules/.bin/jscpd"),
                "--config",
                ".jscpd.json",
                "--baseline",
                ".jscpd-baseline.json",
                "--update-baseline",
            ],
            cwd=self.root,
            env=self.environment,
            check=False,
            capture_output=True,
            encoding="utf-8",
            timeout=120,
        )
        self.assertEqual(update.returncode, 0, update.stdout + update.stderr)
        self.git("add", "lib/refund.dart", ".jscpd-baseline.json")
        self.assertEqual(self.check("--staged").returncode, 0)
        self.copy_receipt("replacement")
        self.git("add", "lib/replacement.dart")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_unstaged_source_fix_cannot_conceal_staged_clone(self) -> None:
        self.copy_receipt()
        self.git("add", "lib/refund.dart")
        (self.root / "lib/refund.dart").write_text(
            "int refund() => 0;\n", encoding="utf-8"
        )
        result = self.check("--staged")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("Stage or stash", result.stderr)

    def test_unstaged_configuration_or_baseline_is_rejected(self) -> None:
        for name in (".jscpd.json", ".jscpd-baseline.json"):
            with self.subTest(name=name):
                target = self.root / name
                original = target.read_bytes()
                target.write_bytes(original + b"\n")
                result = self.check("--staged")
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn("Stage or stash", result.stderr)
                target.write_bytes(original)

    def test_missing_tool_fails_without_installing(self) -> None:
        result = self.check("--staged")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("npm ci --prefix", result.stderr)
        self.assertFalse((self.root / "scripts/quality/js/node_modules").exists())

    def test_missing_baseline_fails(self) -> None:
        self.install()
        (self.root / ".jscpd-baseline.json").unlink()
        result = self.check()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("baseline.json is missing", result.stderr)

    def test_ignored_source_clone_is_still_detected(self) -> None:
        self.install()
        self.copy_receipt()
        with (self.root / ".gitignore").open("a", encoding="utf-8") as stream:
            stream.write("lib/refund.dart\n")
        result = self.check()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_invalid_baseline_fails_as_an_environment_error(self) -> None:
        self.install()
        (self.root / ".jscpd-baseline.json").write_text("[]\n", encoding="utf-8")
        result = self.check()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("Invalid reviewed duplication baseline", result.stderr)

    def test_detector_failure_is_not_reported_as_a_clone(self) -> None:
        binary = self.root / "scripts/quality/js/node_modules/.bin/jscpd"
        binary.parent.mkdir(parents=True)
        binary.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
        binary.chmod(0o755)
        result = self.check()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_reported_clone_fails_even_if_detector_exits_zero(self) -> None:
        binary = self.root / "scripts/quality/js/node_modules/.bin/jscpd"
        binary.parent.mkdir(parents=True)
        binary.write_text(
            f"#!{sys.executable}\n"
            "from pathlib import Path\n"
            "p = Path('build/quality/duplicates/jscpd-report.json')\n"
            "p.parent.mkdir(parents=True)\n"
            'p.write_text(\'{"statistics":{"total":{"sources":2,"newClones":1}}}\')\n',
            encoding="utf-8",
        )
        binary.chmod(0o755)
        result = self.check()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_selected_index_is_preserved_and_used(self) -> None:
        self.install()
        normal_index = self.root / ".git/index"
        alternate_index = self.root / ".git/alternate-index"
        shutil.copy2(normal_index, alternate_index)
        normal_bytes = normal_index.read_bytes()
        self.environment["GIT_INDEX_FILE"] = str(alternate_index)
        self.copy_receipt()
        self.git("add", "lib/refund.dart")
        selected_bytes = alternate_index.read_bytes()
        result = self.check("--staged")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(normal_index.read_bytes(), normal_bytes)
        self.assertEqual(alternate_index.read_bytes(), selected_bytes)


if __name__ == "__main__":
    unittest.main()
