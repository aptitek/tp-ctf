"""Minimal YAML roster loader for overseer/teams.yml."""

from __future__ import annotations

from pathlib import Path

from models import TeamConfig

__all__ = ["load_teams"]


def _parse_kv(line: str) -> tuple[str, str]:
    key, _, raw_val = line.partition(":")
    return key.strip(), raw_val.strip().strip('"').strip("'")


def _flush_entry(
    current: dict[str, str],
    result: list[TeamConfig],
) -> None:
    if not current:
        return
    team_id = current.get("id", "").strip()
    name = current.get("name", team_id).strip()
    ip_addr = current.get("ip", "").strip()
    if team_id and ip_addr:
        result.append(TeamConfig(team_id=team_id, name=name, ip=ip_addr))


def load_teams(path: Path) -> tuple[TeamConfig, ...]:
    """Read team definitions from a simple teams.yml file."""
    if not path.exists():
        return ()

    teams: list[TeamConfig] = []
    current: dict[str, str] = {}

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#") or stripped == "teams:":
            continue
        if stripped.startswith("- "):
            _flush_entry(current, teams)
            current = {}
            key, val = _parse_kv(stripped[2:])
            current[key] = val
            continue
        if ":" in stripped:
            key, val = _parse_kv(stripped)
            current[key] = val

    _flush_entry(current, teams)
    return tuple(teams)
