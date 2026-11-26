"""Network probes for Zones A, B, and C with anti-cheat SSH checks."""

from __future__ import annotations

import json
import logging
import socket
import urllib.error
import urllib.request

from models import TeamConfig, ZoneProbe

__all__ = ["probe_team_zones"]

PROBE_TIMEOUT_SEC = 2.5


def _tcp_open(host: str, port: int) -> bool:
    try:
        with socket.create_connection((host, port), timeout=PROBE_TIMEOUT_SEC):
            return True
    except OSError as exc:
        logging.debug("TCP probe failed for %s:%d (%s)", host, port, exc)
        return False


def _http_get_text(url: str) -> str | None:
    req = urllib.request.Request(url, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=PROBE_TIMEOUT_SEC) as resp:
            if resp.status != 200:
                return None
            return resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, OSError, TimeoutError) as exc:
        logging.debug("HTTP probe failed for %s (%s)", url, exc)
        return None


def _down_probe(zone: str) -> ZoneProbe:
    return ZoneProbe(
        zone=zone,
        state="DOWN",
        sla_ok=False,
        owner_token="",
        locked_by="",
        emergency_restored=False,
    )


def _probe_zone(
    host: str,
    zone: str,
    ssh_port: int,
    http_port: int,
) -> ZoneProbe:
    if not _tcp_open(host, ssh_port):
        return _down_probe(zone)

    raw_json = _http_get_text(f"http://{host}:{http_port}/status")
    if raw_json is None:
        return _down_probe(zone)

    try:
        payload = json.loads(raw_json)
    except json.JSONDecodeError as exc:
        logging.debug("Invalid JSON from %s:%d (%s)", host, http_port, exc)
        return _down_probe(zone)

    if not isinstance(payload, dict):
        return _down_probe(zone)

    sla_ok = bool(payload.get("sla_ok", False))
    state = str(payload.get("state", "DEGRADED"))

    if zone == "zone-a" and _http_get_text(f"http://{host}:{http_port}/index.html") is None:
        sla_ok = False
        state = "DEGRADED"

    return ZoneProbe(
        zone=zone,
        state=state,
        sla_ok=sla_ok,
        owner_token=str(payload.get("owner_token", "")).strip(),
        locked_by=str(payload.get("locked_by", "")).strip(),
        emergency_restored=bool(payload.get("emergency_restored", False)),
    )


def probe_team_zones(team: TeamConfig) -> tuple[ZoneProbe, ZoneProbe, ZoneProbe]:
    """Probe Zone A, Zone B, and Zone C for a team's ZeroTier IP."""
    zone_a = _probe_zone(team.ip, "zone-a", ssh_port=2201, http_port=8080)
    zone_b = _probe_zone(team.ip, "zone-b", ssh_port=2202, http_port=8082)
    zone_c = _probe_zone(team.ip, "zone-c", ssh_port=2203, http_port=8083)
    return zone_a, zone_b, zone_c
