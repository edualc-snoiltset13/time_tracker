import time

def time_tracker():
    tasks = []
    while True:
        print("\n--- Time Tracker ---")
        print("1. Start a task")
        print("2. View logged tasks")
        print("3. Quit")
        choice = input("Choose an option: ")

        if choice == "1":
            name = input("Task name: ")
            print(f"Tracking '{name}'... Press Enter to stop.")
            start = time.time()
            input()
            elapsed = time.time() - start
            minutes, seconds = divmod(int(elapsed), 60)
            tasks.append({"name": name, "seconds": int(elapsed)})
            print(f"Logged: {name} — {minutes}m {seconds}s")

        elif choice == "2":
            if not tasks:
                print("No tasks logged yet.")
            else:
                total = 0
                for t in tasks:
                    m, s = divmod(t["seconds"], 60)
                    print(f"  - {t['name']}: {m}m {s}s")
                    total += t["seconds"]
                tm, ts = divmod(total, 60)
                print(f"  Total: {tm}m {ts}s")

        elif choice == "3":
            print("Goodbye!")
            break

        else:
            print("Invalid option.")

if __name__ == "__main__":
    time_tracker()
