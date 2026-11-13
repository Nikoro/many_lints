import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = [
    ("ci.yaml", "tests", "tool/python.sh scripts/quality/check_duplicates.py"),
    ("release.yaml", "publish", "tool/python.sh scripts/quality/check_duplicates.py"),
]
INSTALL = "npm --prefix scripts/quality/js ci --ignore-scripts --no-audit --no-fund"
VERSION = "scripts/quality/js/node_modules/.bin/jscpd --version"


class WorkflowBootstrapTest(unittest.TestCase):
    def quality_job(self, filename: str, job: str) -> str:
        text = (ROOT / ".github/workflows" / filename).read_text(encoding="utf-8")
        match = re.search(
            rf"(?ms)^  {re.escape(job)}:\n(.*?)(?=^  [a-zA-Z0-9_-]+:|\Z)", text
        )
        self.assertIsNotNone(match, f"Missing {job} in {filename}")
        return match.group(1)

    def test_ci_provisions_locked_detector_before_quality(self) -> None:
        for filename, job, quality_command in WORKFLOWS:
            with self.subTest(filename=filename):
                text = self.quality_job(filename, job)
                setup = text.index("uses: actions/setup-node@")
                install = text.index("run: " + INSTALL)
                verify = text.index("run: " + VERSION)
                quality = text.index(quality_command)
                self.assertLess(setup, install)
                self.assertLess(install, verify)
                self.assertLess(verify, quality)
                self.assertRegex(text[setup:install], r"node-version:\s*24")

    def test_detector_manifest_matches_locked_dependencies(self) -> None:
        package = ROOT / "scripts/quality/js"
        manifest = json.loads((package / "package.json").read_text(encoding="utf-8"))
        lock = json.loads((package / "package-lock.json").read_text(encoding="utf-8"))
        self.assertEqual(
            manifest["devDependencies"], lock["packages"][""]["devDependencies"]
        )
        self.assertIn("node_modules/jscpd", lock["packages"])


if __name__ == "__main__":
    unittest.main()
