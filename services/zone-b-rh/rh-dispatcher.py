#!/usr/bin/env python3
"""E-Corp RH Dispatcher — pedagogical zombie process simulator."""

import os
import signal
import subprocess
import time

CONF_PATH = "/etc/ecorp/rh-dispatcher.conf"
LOG_PATH = "/var/log/ecorp/rh-dispatcher.log"
PID_PATH = "/tmp/rh-dispatcher.pid"
TARGET_ZOMBIES = 5

RUNNING = True
RELOAD_REQUESTED = False


def log_line(message: str) -> None:
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a", encoding="utf-8") as handle:
        handle.write(f"[{timestamp}] {message}\n")


def read_reap_setting() -> bool:
    if not os.path.exists(CONF_PATH):
        return False
    with open(CONF_PATH, "r", encoding="utf-8") as handle:
        for line in handle:
            stripped = line.strip()
            if stripped.startswith("REAP_CHILDREN="):
                return stripped.split("=", 1)[1].strip().lower() == "true"
    return False


def handle_sigterm(_signum: int, _frame: object) -> None:
    global RUNNING
    RUNNING = False


def handle_sighup(_signum: int, _frame: object) -> None:
    global RELOAD_REQUESTED
    RELOAD_REQUESTED = True


def reap_all(children: list[subprocess.Popen[bytes]]) -> None:
    for proc in children:
        proc.wait()
    children.clear()


def sync_children(children: list[subprocess.Popen[bytes]], reap_enabled: bool) -> None:
    if reap_enabled:
        if children:
            reap_all(children)
        return
    if len(children) < TARGET_ZOMBIES:
        children.append(subprocess.Popen(["/bin/true"]))


def handle_reload(children: list[subprocess.Popen[bytes]]) -> bool:
    reap_enabled = read_reap_setting()
    log_line(f"Configuration rechargée : REAP_CHILDREN={reap_enabled}")
    if reap_enabled and children:
        reap_all(children)
        log_line("Tous les processus zombies ont été collectés proprement.")
    return reap_enabled


def main() -> None:
    global RELOAD_REQUESTED
    signal.signal(signal.SIGTERM, handle_sigterm)
    signal.signal(signal.SIGINT, handle_sigterm)
    signal.signal(signal.SIGHUP, handle_sighup)

    with open(PID_PATH, "w", encoding="utf-8") as handle:
        handle.write(f"{os.getpid()}\n")

    children: list[subprocess.Popen[bytes]] = []
    reap_enabled = read_reap_setting()
    log_line(f"rh-dispatcher démarré (PID={os.getpid()}, REAP_CHILDREN={reap_enabled})")

    while RUNNING:
        if RELOAD_REQUESTED:
            RELOAD_REQUESTED = False
            reap_enabled = handle_reload(children)
        sync_children(children, reap_enabled)
        time.sleep(2)

    reap_all(children)
    log_line("rh-dispatcher arrêté proprement.")


if __name__ == "__main__":
    main()
