import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from repository_environment import isolated_environment

PROJECT_ROOT = Path(__file__).resolve().parents[2]
GATE_SCRIPT = "tool/commit_gate.sh"
HOOKS = ".githooks"
INSTALLER = "tool/setup.sh"
TEST_DIRECTORY = "tool/tests"


class HookRepositoryTestCase(unittest.TestCase):
    def setUp(self):
        self.base = Path(self.enterContext(tempfile.TemporaryDirectory())).resolve()
        self.root = self.base / "project"
        self.root.mkdir()
        self.environment = isolated_environment(dict(os.environ))
        self.environment.update(
            GATE_LOG=str(self.base / "gate.log"),
            GIT_CONFIG_GLOBAL=str(self.base / "global.config"),
            GIT_CONFIG_NOSYSTEM="1",
            GIT_ALLOW_PROTOCOL="file",
        )
        self.git_environment = dict(self.environment)
        self.git("init", "-q", "-b", "main")
        (self.root / "README.md").write_text("fixture\n", encoding="utf-8")
        (self.root / ".gitignore").write_text(
            ".tools/\n__pycache__/\n", encoding="utf-8"
        )
        self.commit(self.root)
        self.git("config", "core.hooksPath", "before-hooks")
        for folder in ("tool", HOOKS):
            (self.root / folder).mkdir(parents=True, exist_ok=True)
            for source in (PROJECT_ROOT / folder).glob("*.sh"):
                shutil.copy2(source, self.root / folder / source.name)
        for name in ("pre-commit", "commit-msg"):
            shutil.copy2(PROJECT_ROOT / HOOKS / name, self.root / HOOKS / name)
        duplicate_check = self.root / "scripts/quality/check_duplicates.py"
        duplicate_check.parent.mkdir(parents=True, exist_ok=True)
        duplicate_check.write_text(
            "import os\nraise SystemExit(int(os.environ.get('DUPLICATE_FIXTURE_FAILURE', '0')))\n",
            encoding="utf-8",
        )
        self.source = self.base / "source"
        self.source.mkdir()
        self.git("init", "-q", "-b", "main", cwd=self.source)
        (self.source / ".gitignore").write_text("__pycache__/\n", encoding="utf-8")
        (self.source / "__main__.py").write_text(
            "import os,sys\nfrom pathlib import Path\n"
            "with Path(os.environ['GATE_LOG']).open('a', encoding='utf-8') as output:\n"
            "    output.write(repr(sys.argv[1:]) + '\\n')\n"
            "selected = os.environ.get('GATE_FAIL_COMMAND')\n"
            "failure = int(os.environ.get('GATE_FAILURE', '0'))\n"
            "sys.exit(failure if selected is None or sys.argv[1] == selected else 0)\n",
            encoding="utf-8",
        )
        self.commit(self.source)
        self.git(
            "config",
            "--file",
            self.environment["GIT_CONFIG_GLOBAL"],
            f"url.{self.source.as_uri()}.insteadOf",
            "git@github.com:Nikoro/commit_gate.git",
        )

    def git(self, *arguments, cwd=None):
        return subprocess.run(
            ["git", *arguments],
            cwd=cwd or self.root,
            env=self.git_environment,
            capture_output=True,
            encoding="utf-8",
            timeout=30,
            check=True,
        )

    def commit(self, root):
        self.git("add", ".", cwd=root)
        self.git(
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.com",
            "-c",
            "commit.gpgsign=false",
            "commit",
            "-qm",
            "fixture",
            cwd=root,
        )

    def run_script(self, script, *arguments):
        return subprocess.run(
            ["bash", script, *arguments],
            cwd=self.root,
            env=self.environment,
            capture_output=True,
            encoding="utf-8",
            timeout=30,
            check=False,
        )

    def install_fake_gate(self):
        checkout = self.root / ".tools/commit_gate"
        self.git("clone", "-q", str(self.source), str(checkout))
        return checkout

    def log(self):
        return (self.base / "gate.log").read_text(encoding="utf-8")

    def inherited_index(self):
        index = self.base / "caller.index"
        shutil.copy2(self.root / ".git/index", index)
        self.environment.update(
            GIT_DIR=str(self.root / ".git"),
            GIT_WORK_TREE=str(self.root),
            GIT_INDEX_FILE=str(index),
            GIT_COMMON_DIR=str(self.root / ".git"),
            GIT_OBJECT_DIRECTORY=str(self.root / ".git/objects"),
            GIT_PREFIX="caller-prefix/",
        )
        return index, index.read_bytes()

    def prepare_existing_checks(self):
        directory = self.root / TEST_DIRECTORY
        directory.mkdir(parents=True)
        (directory / "test_existing.py").write_text(
            "import os,unittest\nfrom pathlib import Path\n"
            "class ExistingSuite(unittest.TestCase):\n"
            "    def test_existing_gate_runs(self):\n"
            "        self.assertTrue(Path('.tools/commit_gate').is_dir())\n"
            "        with Path(os.environ['GATE_LOG']).open('a') as output:\n"
            "            output.write('existing tests\\n')\n",
            encoding="utf-8",
        )

    def expected_success_log(self):
        lines = ["['staged', '--no-review']", "existing tests"]
        lines.append("['check']")
        lines.append("['review', '--check']")
        return "\n".join(lines) + "\n"

    def assert_failed_installation(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("Hooks installed:", result.stdout)
        self.assertEqual(
            self.git("config", "--get", "core.hooksPath").stdout.strip(), "before-hooks"
        )


class CommitGateHooksTest(HookRepositoryTestCase):
    def test_missing_clone_fails_with_installation_command(self):
        result = self.run_script(GATE_SCRIPT, "check")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("missing or is not a clone", result.stderr)
        self.assertFalse((self.base / "gate.log").exists())

    def test_invalid_git_metadata_fails_before_running_the_tool(self):
        checkout = self.root / ".tools/commit_gate"
        (checkout / ".git").mkdir(parents=True)
        (checkout / "__main__.py").write_text(
            "raise SystemExit(99)\n", encoding="utf-8"
        )
        result = self.run_script(GATE_SCRIPT, "check")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("not a valid Git checkout", result.stderr)
        self.assertFalse((self.base / "gate.log").exists())

    def test_dirty_clone_fails_before_running_the_tool(self):
        checkout = self.install_fake_gate()
        (checkout / "untracked.txt").write_text("local change", encoding="utf-8")
        result = self.run_script(GATE_SCRIPT, "check")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("has local changes", result.stderr)
        self.assertFalse((self.base / "gate.log").exists())

    def test_commit_message_path_and_exit_code_are_forwarded(self):
        self.install_fake_gate()
        self.environment["GATE_FAILURE"] = "7"
        result = self.run_script(f"{HOOKS}/commit-msg", "message with spaces.txt")
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertEqual(self.log(), "['commit-msg', 'message with spaces.txt']\n")

    def test_precommit_stops_when_staged_gate_fails(self):
        self.install_fake_gate()
        self.environment["GATE_FAILURE"] = "6"
        result = self.run_script(f"{HOOKS}/pre-commit")
        self.assertEqual(result.returncode, 6, result.stdout + result.stderr)
        self.assertEqual(self.log(), "['staged', '--no-review']\n")

    def test_clone_checks_preserve_the_callers_absolute_index(self):
        self.install_fake_gate()
        index, before = self.inherited_index()
        result = self.run_script(GATE_SCRIPT, "check")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.log(), "['check']\n")
        self.assertEqual(index.read_bytes(), before)

    def test_suite_fixtures_preserve_an_inherited_outer_index(self):
        index, before = self.inherited_index()
        root_index = (self.root / ".git/index").read_bytes()
        cases = [
            f"{case.__name__}.{method}"
            for case in (CommitGateHooksTest, CommitGateInstallerTest)
            for method in unittest.defaultTestLoader.getTestCaseNames(case)
            if method != "test_suite_fixtures_preserve_an_inherited_outer_index"
        ]
        result = subprocess.run(
            [sys.executable, str(Path(__file__)), *cases],
            cwd=PROJECT_ROOT,
            env=self.environment,
            capture_output=True,
            encoding="utf-8",
            timeout=60,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(index.read_bytes(), before)
        self.assertEqual((self.root / ".git/index").read_bytes(), root_index)

    def test_launcher_rejects_old_python_and_forwards_arguments(self):
        binaries = self.base / "binaries"
        binaries.mkdir()
        old = binaries / "python3.15"
        old.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
        old.chmod(0o755)
        eligible = binaries / "python3.14"
        eligible.write_text(
            "#!/bin/sh\nexec " + shlex.quote(sys.executable) + ' "$@"\n',
            encoding="utf-8",
        )
        eligible.chmod(0o755)
        self.environment["PATH"] = str(binaries) + os.pathsep + self.environment["PATH"]
        result = self.run_script(
            "tool/python.sh", "-c", "import sys; print(sys.argv[1])", "two words"
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "two words\n")

    def test_duplicate_failure_stops_precommit_before_other_checks(self):
        self.install_fake_gate()
        self.environment["DUPLICATE_FIXTURE_FAILURE"] = "1"
        result = self.run_script(f"{HOOKS}/pre-commit")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.log(), "['staged', '--no-review']\n")

    def test_successful_precommit_checks_review_last(self):
        self.install_fake_gate()
        self.prepare_existing_checks()
        (self.root / "README.md").write_text("staged documentation\n", encoding="utf-8")
        self.git("add", "README.md")
        result = self.run_script(f"{HOOKS}/pre-commit")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.log(), self.expected_success_log())

    def test_empty_index_precommit_checks_review_last(self):
        self.install_fake_gate()
        self.prepare_existing_checks()
        result = self.run_script(f"{HOOKS}/pre-commit")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.log(), self.expected_success_log())

    def test_whole_tree_failure_prevents_review_validation(self):
        self.install_fake_gate()
        self.prepare_existing_checks()
        (self.root / "README.md").write_text("staged documentation\n", encoding="utf-8")
        self.git("add", "README.md")
        self.environment.update(GATE_FAILURE="9", GATE_FAIL_COMMAND="check")
        result = self.run_script(f"{HOOKS}/pre-commit")
        self.assertEqual(result.returncode, 9, result.stdout + result.stderr)
        expected = self.expected_success_log().replace("['review', '--check']\n", "")
        self.assertEqual(self.log(), expected)


class CommitGateInstallerTest(HookRepositoryTestCase):
    def test_installer_clones_validates_then_activates(self):
        index, before = self.inherited_index()
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.log(), "['--help']\n")
        self.assertEqual(
            self.git("config", "--get", "core.hooksPath").stdout.strip(), HOOKS
        )
        self.assertEqual(index.read_bytes(), before)

    def test_duplicate_tool_failure_preserves_previous_hooks(self):
        self.environment["DUPLICATE_FIXTURE_FAILURE"] = "2"
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assert_failed_installation(result)

    def test_installer_rejects_a_nonclone_without_activating_hooks(self):
        checkout = self.root / ".tools/commit_gate"
        checkout.mkdir(parents=True)
        (checkout / "unrelated.txt").write_text("keep", encoding="utf-8")
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assert_failed_installation(result)
        self.assertEqual(
            (checkout / "unrelated.txt").read_text(encoding="utf-8"), "keep"
        )

    def test_installer_rejects_invalid_existing_metadata(self):
        checkout = self.root / ".tools/commit_gate"
        (checkout / ".git").mkdir(parents=True)
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("not a valid Git checkout", result.stderr)
        self.assert_failed_installation(result)

    def test_installer_rejects_dirty_clone_before_fetch(self):
        checkout = self.install_fake_gate()
        (checkout / "untracked.txt").write_text("local change", encoding="utf-8")
        shutil.rmtree(self.source)
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("local changes", result.stderr)
        self.assert_failed_installation(result)

    def test_failed_clone_preserves_previous_hooks(self):
        shutil.rmtree(self.source)
        result = self.run_script(INSTALLER)
        self.assert_failed_installation(result)
        self.assertFalse((self.base / "gate.log").exists())

    def test_failed_fetch_preserves_previous_hooks(self):
        self.install_fake_gate()
        shutil.rmtree(self.source)
        result = self.run_script(INSTALLER)
        self.assert_failed_installation(result)
        self.assertFalse((self.base / "gate.log").exists())

    def test_failed_help_preserves_previous_hooks(self):
        self.install_fake_gate()
        self.environment["GATE_FAILURE"] = "8"
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 8, result.stdout + result.stderr)
        self.assert_failed_installation(result)

    def test_installer_fast_forwards_an_existing_clean_clone(self):
        checkout = self.install_fake_gate()
        (self.source / "updated.txt").write_text("update", encoding="utf-8")
        self.commit(self.source)
        index, before = self.inherited_index()
        result = self.run_script(INSTALLER)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            (checkout / "updated.txt").read_text(encoding="utf-8"), "update"
        )
        self.assertEqual(index.read_bytes(), before)
        self.assertEqual(self.log(), "['--help']\n")

    def test_installer_refuses_divergence_without_activating_hooks(self):
        checkout = self.install_fake_gate()
        (checkout / "local.txt").write_text("local", encoding="utf-8")
        self.commit(checkout)
        (self.source / "remote.txt").write_text("remote", encoding="utf-8")
        self.commit(self.source)
        result = self.run_script(INSTALLER)
        self.assert_failed_installation(result)
        self.assertFalse((self.base / "gate.log").exists())


class OptionalDeveloperToolsTest(unittest.TestCase):
    @unittest.skipUnless(shutil.which("shellcheck"), "ShellCheck is not installed")
    def test_gate_scripts_pass_shellcheck(self):
        scripts = [
            PROJECT_ROOT / GATE_SCRIPT,
            PROJECT_ROOT / "tool/commit_gate_git.sh",
            PROJECT_ROOT / "tool/python.sh",
            PROJECT_ROOT / HOOKS / "pre-commit",
            PROJECT_ROOT / HOOKS / "commit-msg",
            PROJECT_ROOT / "tool/setup.sh",
        ]
        result = subprocess.run(
            ["shellcheck", "--severity=warning", *map(str, scripts)],
            capture_output=True,
            encoding="utf-8",
            timeout=30,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which("ruff"), "Ruff is not installed")
    def test_quality_python_passes_ruff(self):
        paths = [
            PROJECT_ROOT / "scripts/quality/check_duplicates.py",
            PROJECT_ROOT / "tool/tests/repository_environment.py",
            *sorted((PROJECT_ROOT / "tool/tests").glob("test_*.py")),
        ]
        for command in (["check"], ["format", "--check"]):
            with self.subTest(command=command):
                result = subprocess.run(
                    ["ruff", *command, "--no-cache", *map(str, paths)],
                    capture_output=True,
                    encoding="utf-8",
                    timeout=30,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
