#!/usr/bin/env python3
"""Command-line time tracker. State stored in ~/.time_tracker.json."""

import json
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

DATA_FILE = Path.home() / ".time_tracker.json"


def _local_now() -> datetime:
    return datetime.now().astimezone()


def _fmt_iso(dt: datetime) -> str:
    return dt.isoformat(timespec="seconds")


def _parse_iso(s: str) -> datetime:
    return datetime.fromisoformat(s)


def _fmt_duration(seconds: float) -> str:
    seconds = int(seconds)
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    return f"{h}h {m}m {s}s"


def _load() -> dict:
    if DATA_FILE.exists():
        with DATA_FILE.open() as f:
            return json.load(f)
    return {"current": None, "entries": []}


def _save(data: dict) -> None:
    with DATA_FILE.open("w") as f:
        json.dump(data, f, indent=2)


def cmd_start(args: list[str]) -> None:
    if not args:
        print("Usage: time_tracker.py start <task description...>", file=sys.stderr)
        sys.exit(1)
    task = " ".join(args)
    data = _load()
    if data["current"] is not None:
        current = data["current"]
        print(
            f"Already tracking: '{current['task']}' "
            f"(started {current['start']}). Stop it first."
        )
        sys.exit(1)
    now = _local_now()
    data["current"] = {"task": task, "start": _fmt_iso(now)}
    _save(data)
    print(f"Started tracking '{task}' at {_fmt_iso(now)}.")


def cmd_stop(_args: list[str]) -> None:
    data = _load()
    if data["current"] is None:
        print("Not tracking anything.")
        sys.exit(1)
    now = _local_now()
    current = data["current"]
    start_dt = _parse_iso(current["start"])
    duration = (now - start_dt).total_seconds()
    entry = {
        "task": current["task"],
        "start": current["start"],
        "end": _fmt_iso(now),
        "duration_seconds": duration,
    }
    data["entries"].append(entry)
    data["current"] = None
    _save(data)
    print(
        f"Stopped '{entry['task']}'. Duration: {_fmt_duration(duration)}."
    )


def cmd_status(_args: list[str]) -> None:
    data = _load()
    if data["current"] is None:
        print("Not tracking anything.")
        return
    current = data["current"]
    start_dt = _parse_iso(current["start"])
    elapsed = (_local_now() - start_dt).total_seconds()
    print(
        f"Tracking: '{current['task']}'\n"
        f"  Started : {current['start']}\n"
        f"  Elapsed : {_fmt_duration(elapsed)}"
    )


def cmd_log(args: list[str]) -> None:
    n = 10
    if args:
        try:
            n = int(args[0])
        except ValueError:
            print(f"Invalid count: {args[0]}", file=sys.stderr)
            sys.exit(1)
    data = _load()
    entries = data["entries"][-n:]
    if not entries:
        print("No entries yet.")
        return
    for e in entries:
        print(
            f"{e['start']}  {_fmt_duration(e['duration_seconds']):>14}  {e['task']}"
        )


def cmd_summary(_args: list[str]) -> None:
    data = _load()
    totals: dict[str, float] = {}
    for e in data["entries"]:
        totals[e["task"]] = totals.get(e["task"], 0) + e["duration_seconds"]
    if not totals:
        print("No entries yet.")
        return
    for task, secs in sorted(totals.items(), key=lambda x: x[1], reverse=True):
        print(f"{_fmt_duration(secs):>14}  {task}")


COMMANDS = {
    "start": cmd_start,
    "stop": cmd_stop,
    "status": cmd_status,
    "log": cmd_log,
    "summary": cmd_summary,
}


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(
            "Usage: time_tracker.py <command> [args]\n"
            "Commands: start <task...> | stop | status | log [n] | summary",
            file=sys.stderr,
        )
        sys.exit(1)
    cmd = sys.argv[1]
    COMMANDS[cmd](sys.argv[2:])


if __name__ == "__main__":
    main()
