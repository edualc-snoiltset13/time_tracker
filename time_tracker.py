import time
from datetime import datetime, timedelta


class TimeTracker:
    def __init__(self):
        self.entries = []
        self._start_time = None
        self._current_task = None

    def start(self, task):
        if self._start_time:
            print(f"Already tracking: {self._current_task}")
            return
        self._start_time = time.time()
        self._current_task = task
        print(f"Started: {task}")

    def stop(self):
        if not self._start_time:
            print("No task is being tracked.")
            return
        elapsed = time.time() - self._start_time
        self.entries.append({"task": self._current_task, "seconds": elapsed})
        print(f"Stopped: {self._current_task} ({elapsed:.1f}s)")
        self._start_time = None
        self._current_task = None

    def summary(self):
        if not self.entries:
            print("No entries recorded.")
            return
        print("\n--- Time Summary ---")
        total = 0
        for entry in self.entries:
            duration = timedelta(seconds=int(entry["seconds"]))
            print(f"  {entry['task']}: {duration}")
            total += entry["seconds"]
        print(f"  Total: {timedelta(seconds=int(total))}")


if __name__ == "__main__":
    tracker = TimeTracker()

    tracker.start("Write code")
    time.sleep(2)
    tracker.stop()

    tracker.start("Review PR")
    time.sleep(1)
    tracker.stop()

    tracker.summary()
