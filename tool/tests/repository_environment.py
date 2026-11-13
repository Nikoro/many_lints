from collections.abc import Mapping


def isolated_environment(inherited: Mapping[str, str]) -> dict[str, str]:
    return {
        name: value for name, value in inherited.items() if not name.startswith("GIT_")
    }
