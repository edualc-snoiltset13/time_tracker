"""pytest suite for time_tracker.py — exercises start/stop/status/summary."""

import json
import sys
import time
from pathlib import Path

import pytest

import time_tracker as tt


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _state(tmp_path) -> dict:
    return json.loads((tmp_path / "data.json").read_text())


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def redirect_data_file(tmp_path, monkeypatch):
    """Point DATA_FILE at a temp file for every test."""
    data_file = tmp_path / "data.json"
    monkeypatch.setattr(tt, "DATA_FILE", data_file)
    return data_file


# ---------------------------------------------------------------------------
# start
# ---------------------------------------------------------------------------

class TestStart:
    def test_start_creates_current(self, tmp_path):
        tt.cmd_start(["writing", "tests"])
        data = _state(tmp_path)
        assert data["current"]["task"] == "writing tests"
        assert data["current"]["start"] is not None

    def test_start_refuses_when_already_tracking(self, capsys):
        tt.cmd_start(["first task"])
        with pytest.raises(SystemExit):
            tt.cmd_start(["second task"])
        out = capsys.readouterr().out
        assert "Already tracking" in out

    def test_start_no_args_exits(self, capsys):
        with pytest.raises(SystemExit):
            tt.cmd_start([])

    def test_start_leaves_entries_empty(self, tmp_path):
        tt.cmd_start(["something"])
        assert _state(tmp_path)["entries"] == []


# ---------------------------------------------------------------------------
# stop
# ---------------------------------------------------------------------------

class TestStop:
    def test_stop_clears_current_and_appends_entry(self, tmp_path):
        tt.cmd_start(["task one"])
        tt.cmd_stop([])
        data = _state(tmp_path)
        assert data["current"] is None
        assert len(data["entries"]) == 1
        entry = data["entries"][0]
        assert entry["task"] == "task one"
        assert entry["duration_seconds"] >= 0
        assert "start" in entry
        assert "end" in entry

    def test_stop_without_tracking_exits(self, capsys):
        with pytest.raises(SystemExit):
            tt.cmd_stop([])

    def test_stop_records_positive_duration(self, tmp_path):
        tt.cmd_start(["timed task"])
        time.sleep(0.05)
        tt.cmd_stop([])
        entry = _state(tmp_path)["entries"][0]
        assert entry["duration_seconds"] > 0

    def test_multiple_start_stop_cycles(self, tmp_path):
        for i in range(3):
            tt.cmd_start([f"task {i}"])
            tt.cmd_stop([])
        assert len(_state(tmp_path)["entries"]) == 3


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------

class TestStatus:
    def test_status_not_tracking(self, capsys):
        tt.cmd_status([])
        assert "Not tracking anything" in capsys.readouterr().out

    def test_status_shows_task(self, capsys):
        tt.cmd_start(["my task"])
        tt.cmd_status([])
        out = capsys.readouterr().out
        assert "my task" in out
        assert "Elapsed" in out

    def test_status_clears_after_stop(self, capsys):
        tt.cmd_start(["temp"])
        tt.cmd_stop([])
        tt.cmd_status([])
        assert "Not tracking anything" in capsys.readouterr().out


# ---------------------------------------------------------------------------
# log
# ---------------------------------------------------------------------------

class TestLog:
    def test_log_empty(self, capsys):
        tt.cmd_log([])
        assert "No entries" in capsys.readouterr().out

    def test_log_shows_entries(self, capsys, tmp_path):
        for label in ["alpha", "beta", "gamma"]:
            tt.cmd_start([label])
            tt.cmd_stop([])
        tt.cmd_log([])
        out = capsys.readouterr().out
        assert "alpha" in out
        assert "beta" in out
        assert "gamma" in out

    def test_log_respects_limit(self, capsys, tmp_path):
        for i in range(5):
            tt.cmd_start([f"task {i}"])
            tt.cmd_stop([])
        capsys.readouterr()  # discard start/stop output
        tt.cmd_log(["2"])
        lines = [l for l in capsys.readouterr().out.strip().splitlines() if l]
        assert len(lines) == 2

    def test_log_invalid_count_exits(self, capsys):
        with pytest.raises(SystemExit):
            tt.cmd_log(["notanumber"])


# ---------------------------------------------------------------------------
# summary
# ---------------------------------------------------------------------------

class TestSummary:
    def test_summary_empty(self, capsys):
        tt.cmd_summary([])
        assert "No entries" in capsys.readouterr().out

    def test_summary_totals_per_task(self, capsys, tmp_path):
        # Two entries for "alpha", one for "beta"
        for _ in range(2):
            tt.cmd_start(["alpha"])
            tt.cmd_stop([])
        tt.cmd_start(["beta"])
        tt.cmd_stop([])
        tt.cmd_summary([])
        lines = capsys.readouterr().out.strip().splitlines()
        # alpha should appear before beta (more total time assumed equal or more)
        tasks_in_order = [l.split()[-1] for l in lines]
        assert "alpha" in tasks_in_order
        assert "beta" in tasks_in_order

    def test_summary_sorted_descending(self, tmp_path):
        # Inject entries with known durations
        data = tt._load()
        data["entries"] = [
            {"task": "short", "start": "2024-01-01T00:00:00+00:00",
             "end": "2024-01-01T00:01:00+00:00", "duration_seconds": 60},
            {"task": "long", "start": "2024-01-01T00:00:00+00:00",
             "end": "2024-01-01T01:00:00+00:00", "duration_seconds": 3600},
        ]
        tt._save(data)
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            tt.cmd_summary([])
        lines = buf.getvalue().strip().splitlines()
        assert "long" in lines[0]
        assert "short" in lines[1]


# ---------------------------------------------------------------------------
# _fmt_duration
# ---------------------------------------------------------------------------

class TestFmtDuration:
    def test_zero(self):
        assert tt._fmt_duration(0) == "0h 0m 0s"

    def test_one_hour(self):
        assert tt._fmt_duration(3600) == "1h 0m 0s"

    def test_mixed(self):
        assert tt._fmt_duration(3661) == "1h 1m 1s"

    def test_only_seconds(self):
        assert tt._fmt_duration(45) == "0h 0m 45s"
