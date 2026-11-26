"""Typed immutable domain models for E-Corp Overseer."""

from __future__ import annotations

from dataclasses import dataclass

__all__ = [
    "TeamConfig",
    "TickContext",
    "ZoneProbe",
    "TeamRow",
    "ScoreboardSnapshot",
]


@dataclass(frozen=True)
class TeamConfig:
    """Static team roster entry loaded from teams.yml."""

    team_id: str
    name: str
    ip: str


@dataclass(frozen=True)
class TickContext:
    """Metadata for a single scoring tick."""

    tick: int
    updated_at: str


@dataclass(frozen=True)
class ZoneProbe:
    """Observed state of a single zone (A, B, or C) for one team."""

    zone: str
    state: str
    sla_ok: bool
    owner_token: str
    locked_by: str
    emergency_restored: bool


@dataclass(frozen=True)
class TeamRow:
    """Aggregated scoreboard row for a single team."""

    team_id: str
    name: str
    ip: str
    score: int
    zone_a: ZoneProbe
    zone_b: ZoneProbe
    zone_c: ZoneProbe


@dataclass(frozen=True)
class ScoreboardSnapshot:
    """Complete immutable snapshot rendered by the dashboard API."""

    tick: int
    updated_at: str
    rows: tuple[TeamRow, ...]
