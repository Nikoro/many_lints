import argparse
import json
import subprocess
import sys
from fnmatch import fnmatchcase
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
POLICY_FILES = (
    ".jscpd.json",
    ".jscpd-baseline.json",
    "scripts/quality/check_duplicates.py",
    "scripts/quality/js/package.json",
    "scripts/quality/js/package-lock.json",
)


def git(*arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *arguments],
        cwd=ROOT,
        capture_output=True,
        encoding="utf-8",
        check=False,
        timeout=30,
    )


def source_suffixes(formats: object) -> tuple[str, ...]:
    if formats != ["dart"]:
        raise ValueError("Duplication formats must be ['dart'].")
    return (".dart",)


def is_scan_input(path: str, ignored: list[str], suffixes: tuple[str, ...]) -> bool:
    return path in POLICY_FILES or (
        Path(path).suffix.lower() in suffixes
        and not any(fnmatchcase(path, pattern) for pattern in ignored)
    )


def require_staged_scan_inputs(
    paths: list[str], ignored: list[str], suffixes: tuple[str, ...]
) -> None:
    tracked = git("ls-files", "--error-unmatch", "--", *POLICY_FILES)
    if tracked.returncode:
        raise ValueError(
            "Stage the duplication checker and its policy files before committing."
        )
    entries = git("ls-files", "-v", "-z", "--", *POLICY_FILES, *paths)
    if entries.returncode:
        raise ValueError(entries.stderr.strip() or "Git could not inspect index flags.")
    if any(
        entry[:1] == "S" or entry[:1].islower()
        for entry in entries.stdout.split("\0")
        if entry and is_scan_input(entry[2:], ignored, suffixes)
    ):
        raise ValueError(
            "Clear assume-unchanged and skip-worktree index flags for duplication sources and policy before committing."
        )
    difference = git("diff", "--name-only", "-z", "--", *POLICY_FILES, *paths)
    if difference.returncode:
        raise ValueError(
            difference.stderr.strip() or "Git could not inspect duplication sources."
        )
    if any(
        path and is_scan_input(path, ignored, suffixes)
        for path in difference.stdout.split("\0")
    ):
        raise ValueError(
            "Stage or stash changes to duplication sources and policy before committing."
        )
    untracked = git("ls-files", "--others", "-z", "--", *POLICY_FILES, *paths)
    if untracked.returncode:
        raise ValueError(
            untracked.stderr.strip() or "Git could not inspect untracked sources."
        )
    if any(
        path and is_scan_input(path, ignored, suffixes)
        for path in untracked.stdout.split("\0")
    ):
        raise ValueError(
            "Stage new duplication sources and policy files before committing."
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Reject new authored-code clones against the reviewed baseline."
    )
    parser.add_argument("--staged", action="store_true")
    arguments = parser.parse_args()
    try:
        configuration = json.loads((ROOT / ".jscpd.json").read_text(encoding="utf-8"))
        paths = configuration["path"]
        if (
            not isinstance(paths, list)
            or not paths
            or any(
                not isinstance(path, str)
                or Path(path).is_absolute()
                or ".." in Path(path).parts
                for path in paths
            )
        ):
            raise ValueError(
                "Duplication paths must be nonempty repository-relative paths."
            )
        if arguments.staged:
            ignored = configuration.get("ignore", [])
            if not isinstance(ignored, list) or any(
                not isinstance(pattern, str) for pattern in ignored
            ):
                raise ValueError(
                    "Duplication exclusions must be a list of glob patterns."
                )
            require_staged_scan_inputs(
                paths, ignored, source_suffixes(configuration.get("format"))
            )
        executable = ROOT / "scripts/quality/js/node_modules/.bin/jscpd"
        if not executable.is_file():
            raise ValueError(
                "Install duplication tooling first: npm ci --prefix scripts/quality/js"
            )
        if not (ROOT / ".jscpd-baseline.json").is_file():
            raise ValueError("The reviewed .jscpd-baseline.json is missing.")
        baseline = json.loads(
            (ROOT / ".jscpd-baseline.json").read_text(encoding="utf-8")
        )
        fingerprints = (
            baseline.get("fingerprints") if isinstance(baseline, dict) else None
        )
        if (
            not isinstance(baseline, dict)
            or baseline.get("version") != 1
            or not isinstance(fingerprints, dict)
            or any(
                not isinstance(key, str) or type(count) is not int or count < 1
                for key, count in fingerprints.items()
            )
        ):
            raise ValueError("Invalid reviewed duplication baseline.")
        report = ROOT / "build/quality/duplicates/jscpd-report.json"
        report.unlink(missing_ok=True)
        result = subprocess.run(
            [
                str(executable),
                "--workers",
                "2",
                "--config",
                str(ROOT / ".jscpd.json"),
                "--baseline",
                str(ROOT / ".jscpd-baseline.json"),
                "--fail-on-new-clones",
                "0",
                "--reporters",
                "console,json",
                "--output",
                str(report.parent),
            ],
            cwd=ROOT,
            check=False,
            timeout=120,
        )
        if result.returncode not in (0, 1):
            return 2
        summary = json.loads(report.read_text(encoding="utf-8"))["statistics"]["total"]
        if type(summary["sources"]) is not int or summary["sources"] < 1:
            raise ValueError("Duplication scan did not analyze any source files.")
        if type(summary["newClones"]) is not int or summary["newClones"] < 0:
            raise ValueError("Invalid clone count in the duplicate detector report.")
        if result.returncode == 1 and summary["newClones"] < 1:
            raise ValueError(
                "The duplicate detector failed without reporting a new clone."
            )
        return 1 if summary["newClones"] else 0
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.TimeoutExpired,
    ) as error:
        print(f"duplicate check: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
