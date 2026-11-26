"""E-Corp Overseer HTTP Dashboard & 15-second Scorebot Loop."""

from __future__ import annotations

import dataclasses
import json
import logging
import os
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from config import load_teams
from models import ScoreboardSnapshot, TickContext, ZoneProbe
from probes import probe_team_zones
from scorer import apply_scores, build_rows, compute_next_scores

__all__ = ["run_server"]

APP_DIR = Path(__file__).resolve().parent
TEAMS_FILE = Path(os.environ.get("OVERSEER_TEAMS_FILE", str(APP_DIR / "teams.yml")))
DASHBOARD_FILE = APP_DIR / "dashboard.html"
POLL_INTERVAL_SEC = int(os.environ.get("OVERSEER_POLL_SECONDS", "15"))
LISTEN_PORT = int(os.environ.get("OVERSEER_PORT", "9000"))

_STATE_LOCK = threading.Lock()
_LATEST_SNAPSHOT = ScoreboardSnapshot(tick=0, updated_at="--:--:--", rows=())


def _snapshot_to_json(snapshot: ScoreboardSnapshot) -> bytes:
    payload = dataclasses.asdict(snapshot)
    return json.dumps(payload, ensure_ascii=False).encode("utf-8")


def _polling_loop() -> None:
    global _LATEST_SNAPSHOT
    scores: dict[str, int] = {}
    tick = 0

    while True:
        teams = load_teams(TEAMS_FILE)
        probes_by_team: dict[str, tuple[ZoneProbe, ZoneProbe, ZoneProbe]] = {}
        for team in teams:
            probes_by_team[team.team_id] = probe_team_zones(team)

        tick += 1
        scores = compute_next_scores(teams, probes_by_team, scores)
        rows = build_rows(teams, probes_by_team)
        ctx = TickContext(tick=tick, updated_at=time.strftime("%H:%M:%S"))
        snapshot = apply_scores(ctx, rows, scores)

        with _STATE_LOCK:
            _LATEST_SNAPSHOT = snapshot

        logging.info("Tick #%d terminé (%d équipes évaluées)", tick, len(teams))
        time.sleep(POLL_INTERVAL_SEC)


class OverseerHandler(BaseHTTPRequestHandler):
    """Serve the static dashboard HTML and live JSON scoreboard API."""

    def log_message(self, format: str, *args: object) -> None:
        logging.debug(format, *args)

    def _send_bytes(self, body: bytes, content_type: str) -> None:
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path in ("/", "/index.html"):
            body = DASHBOARD_FILE.read_bytes()
            self._send_bytes(body, "text/html; charset=utf-8")
            return
        if self.path == "/api/state":
            with _STATE_LOCK:
                body = _snapshot_to_json(_LATEST_SNAPSHOT)
            self._send_bytes(body, "application/json; charset=utf-8")
            return
        if self.path == "/healthz":
            self._send_bytes(b'{"status":"ok"}', "application/json; charset=utf-8")
            return
        self.send_error(HTTPStatus.NOT_FOUND, "Not Found")


def run_server() -> None:
    """Start the background scorebot thread and HTTP dashboard server."""
    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] [OVERSEER] %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )
    poller = threading.Thread(target=_polling_loop, daemon=True)
    poller.start()

    server = ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), OverseerHandler)
    logging.info("E-Corp Overseer actif sur http://0.0.0.0:%d", LISTEN_PORT)
    server.serve_forever()


if __name__ == "__main__":
    run_server()
