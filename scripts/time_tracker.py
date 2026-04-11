#!/usr/bin/env python3
"""
A simple command-line time tracker utility.

Usage:
    python time_tracker.py start <project> [--description <desc>]
    python time_tracker.py stop
    python time_tracker.py status
    python time_tracker.py log [--project <project>] [--days <n>]
    python time_tracker.py summary [--days <n>]
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

DATA_DIR = Path.home() / ".time_tracker"
ACTIVE_FILE = DATA_DIR / "active.json"
ENTRIES_FILE = DATA_DIR / "entries.json"


def ensure_data_dir():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not ENTRIES_FILE.exists():
        ENTRIES_FILE.write_text("[]")


def load_entries():
    if not ENTRIES_FILE.exists():
        return []
    return json.loads(ENTRIES_FILE.read_text())


def save_entries(entries):
    ENTRIES_FILE.write_text(json.dumps(entries, indent=2))


def format_duration(seconds):
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    if hours > 0:
        return f"{hours}h {minutes}m {secs}s"
    if minutes > 0:
        return f"{minutes}m {secs}s"
    return f"{secs}s"


def cmd_start(args):
    ensure_data_dir()

    if ACTIVE_FILE.exists():
        active = json.loads(ACTIVE_FILE.read_text())
        print(f"Timer already running for project '{active['project']}' "
              f"(started at {active['start_time']})")
        print("Stop it first with: time_tracker.py stop")
        sys.exit(1)

    entry = {
        "project": args.project,
        "description": args.description or "",
        "start_time": datetime.now().isoformat(),
    }
    ACTIVE_FILE.write_text(json.dumps(entry, indent=2))
    print(f"Started tracking time for '{args.project}'")
    if args.description:
        print(f"  Description: {args.description}")


def cmd_stop(args):
    ensure_data_dir()

    if not ACTIVE_FILE.exists():
        print("No active timer running.")
        sys.exit(1)

    active = json.loads(ACTIVE_FILE.read_text())
    start = datetime.fromisoformat(active["start_time"])
    end = datetime.now()
    duration = (end - start).total_seconds()

    entry = {
        "project": active["project"],
        "description": active["description"],
        "start_time": active["start_time"],
        "end_time": end.isoformat(),
        "duration_seconds": duration,
    }

    entries = load_entries()
    entries.append(entry)
    save_entries(entries)

    ACTIVE_FILE.unlink()

    print(f"Stopped timer for '{active['project']}'")
    print(f"  Duration: {format_duration(duration)}")


def cmd_status(args):
    ensure_data_dir()

    if not ACTIVE_FILE.exists():
        print("No active timer running.")
        return

    active = json.loads(ACTIVE_FILE.read_text())
    start = datetime.fromisoformat(active["start_time"])
    elapsed = (datetime.now() - start).total_seconds()

    print(f"Active timer:")
    print(f"  Project:     {active['project']}")
    if active.get("description"):
        print(f"  Description: {active['description']}")
    print(f"  Started:     {start.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  Elapsed:     {format_duration(elapsed)}")


def cmd_log(args):
    ensure_data_dir()
    entries = load_entries()

    if not entries:
        print("No time entries recorded yet.")
        return

    cutoff = datetime.now() - timedelta(days=args.days)

    filtered = []
    for e in entries:
        entry_time = datetime.fromisoformat(e["start_time"])
        if entry_time < cutoff:
            continue
        if args.project and e["project"].lower() != args.project.lower():
            continue
        filtered.append(e)

    if not filtered:
        print("No matching entries found.")
        return

    print(f"{'Date':<12} {'Project':<20} {'Duration':<12} {'Description'}")
    print("-" * 70)

    for e in filtered:
        date = datetime.fromisoformat(e["start_time"]).strftime("%Y-%m-%d")
        duration = format_duration(e["duration_seconds"])
        desc = e.get("description", "")
        print(f"{date:<12} {e['project']:<20} {duration:<12} {desc}")


def cmd_summary(args):
    ensure_data_dir()
    entries = load_entries()

    if not entries:
        print("No time entries recorded yet.")
        return

    cutoff = datetime.now() - timedelta(days=args.days)

    totals = {}
    for e in entries:
        entry_time = datetime.fromisoformat(e["start_time"])
        if entry_time < cutoff:
            continue
        project = e["project"]
        totals[project] = totals.get(project, 0) + e["duration_seconds"]

    if not totals:
        print("No entries in the given time range.")
        return

    print(f"Time summary (last {args.days} days):")
    print(f"{'Project':<25} {'Total Time':<15}")
    print("-" * 40)

    grand_total = 0
    for project, seconds in sorted(totals.items()):
        print(f"{project:<25} {format_duration(seconds):<15}")
        grand_total += seconds

    print("-" * 40)
    print(f"{'TOTAL':<25} {format_duration(grand_total):<15}")


def main():
    parser = argparse.ArgumentParser(
        description="Simple command-line time tracker"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # start
    start_parser = subparsers.add_parser("start", help="Start tracking time")
    start_parser.add_argument("project", help="Project name")
    start_parser.add_argument(
        "--description", "-d", default="", help="Description of the work"
    )

    # stop
    subparsers.add_parser("stop", help="Stop the active timer")

    # status
    subparsers.add_parser("status", help="Show the active timer status")

    # log
    log_parser = subparsers.add_parser("log", help="Show time entry log")
    log_parser.add_argument("--project", "-p", default=None, help="Filter by project")
    log_parser.add_argument(
        "--days", "-n", type=int, default=7, help="Number of days to show (default: 7)"
    )

    # summary
    summary_parser = subparsers.add_parser(
        "summary", help="Show time summary by project"
    )
    summary_parser.add_argument(
        "--days", "-n", type=int, default=7, help="Number of days to show (default: 7)"
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    commands = {
        "start": cmd_start,
        "stop": cmd_stop,
        "status": cmd_status,
        "log": cmd_log,
        "summary": cmd_summary,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
