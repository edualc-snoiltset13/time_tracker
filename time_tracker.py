import time

tasks = {}

def start_task(name):
    tasks[name] = {"start": time.time(), "elapsed": 0}
    print(f"Started tracking: {name}")

def stop_task(name):
    if name in tasks and "start" in tasks[name]:
        tasks[name]["elapsed"] += time.time() - tasks[name].pop("start")
        print(f"Stopped tracking: {name} ({tasks[name]['elapsed']:.1f}s)")
    else:
        print(f"Task '{name}' is not running.")

def show_tasks():
    print("\n--- Tracked Tasks ---")
    for name, data in tasks.items():
        elapsed = data["elapsed"]
        if "start" in data:
            elapsed += time.time() - data["start"]
        mins, secs = divmod(int(elapsed), 60)
        hrs, mins = divmod(mins, 60)
        status = "running" if "start" in data else "stopped"
        print(f"  {name}: {hrs:02d}:{mins:02d}:{secs:02d} [{status}]")
    if not tasks:
        print("  No tasks tracked yet.")
    print()

if __name__ == "__main__":
    print("Time Tracker - Commands: start <task>, stop <task>, show, quit")
    while True:
        cmd = input("> ").strip().split(maxsplit=1)
        if not cmd:
            continue
        action = cmd[0].lower()
        if action == "quit":
            show_tasks()
            break
        elif action == "start" and len(cmd) > 1:
            start_task(cmd[1])
        elif action == "stop" and len(cmd) > 1:
            stop_task(cmd[1])
        elif action == "show":
            show_tasks()
        else:
            print("Usage: start <task> | stop <task> | show | quit")
