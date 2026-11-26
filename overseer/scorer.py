"""Pure functional scoring rules for E-Corp Arena King of the Hill."""

from __future__ import annotations

from models import ScoreboardSnapshot, TeamConfig, TeamRow, TickContext, ZoneProbe

__all__ = ["compute_next_scores", "build_rows", "apply_scores"]

SLA_POINTS = 2
CONTROL_POINTS = 3
VAULT_LOCK_BONUS = 4
RESTORE_PENALTY = 2


def _score_zone(
    host_team_id: str,
    probe: ZoneProbe,
    known_ids: set[str],
    deltas: dict[str, int],
) -> None:
    if probe.emergency_restored:
        deltas[host_team_id] = deltas.get(host_team_id, 0) - RESTORE_PENALTY

    if probe.state == "ENCRYPTED" and probe.locked_by in known_ids:
        if probe.locked_by != host_team_id:
            deltas[probe.locked_by] = deltas.get(probe.locked_by, 0) + VAULT_LOCK_BONUS
        return

    if not probe.sla_ok:
        return

    deltas[host_team_id] = deltas.get(host_team_id, 0) + SLA_POINTS
    if probe.owner_token in known_ids:
        deltas[probe.owner_token] = deltas.get(probe.owner_token, 0) + CONTROL_POINTS


def compute_next_scores(
    teams: tuple[TeamConfig, ...],
    probes_by_team: dict[str, tuple[ZoneProbe, ZoneProbe, ZoneProbe]],
    current_scores: dict[str, int],
) -> dict[str, int]:
    """Compute updated team scores for one scoring tick."""
    known_ids = {team.team_id for team in teams}
    deltas: dict[str, int] = {team.team_id: 0 for team in teams}

    for team in teams:
        probes = probes_by_team.get(team.team_id)
        if probes is None:
            continue
        for probe in probes:
            _score_zone(team.team_id, probe, known_ids, deltas)

    return {
        team_id: max(0, current_scores.get(team_id, 0) + delta)
        for team_id, delta in deltas.items()
    }


def build_rows(
    teams: tuple[TeamConfig, ...],
    probes_by_team: dict[str, tuple[ZoneProbe, ZoneProbe, ZoneProbe]],
) -> tuple[TeamRow, ...]:
    """Create sorted TeamRow entries (scores injected separately)."""
    rows: list[TeamRow] = []
    for team in teams:
        zone_a, zone_b, zone_c = probes_by_team[team.team_id]
        rows.append(
            TeamRow(
                team_id=team.team_id,
                name=team.name,
                ip=team.ip,
                score=0,
                zone_a=zone_a,
                zone_b=zone_b,
                zone_c=zone_c,
            )
        )
    return tuple(rows)


def apply_scores(
    ctx: TickContext,
    rows: tuple[TeamRow, ...],
    scores: dict[str, int],
) -> ScoreboardSnapshot:
    """Attach scores to TeamRows and sort descending by score."""
    scored = [
        TeamRow(
            team_id=row.team_id,
            name=row.name,
            ip=row.ip,
            score=scores.get(row.team_id, 0),
            zone_a=row.zone_a,
            zone_b=row.zone_b,
            zone_c=row.zone_c,
        )
        for row in rows
    ]
    scored.sort(key=lambda item: (-item.score, item.name.lower()))
    return ScoreboardSnapshot(tick=ctx.tick, updated_at=ctx.updated_at, rows=tuple(scored))
