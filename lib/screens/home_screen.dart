// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:time_tracker/screens/todos/todo_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Drives the search TextField. Owned by this State so its lifecycle
  // matches the screen and survives parent rebuilds.
  final TextEditingController _searchController = TextEditingController();

  // Lowercased mirror of _searchController.text. Cached as a separate
  // field so the StreamBuilder can do a cheap `.contains` per row
  // without re-lowercasing on every list build.
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listener bridges TextEditingController -> setState so the list
    // re-filters on every keystroke. Lowercase here once instead of in
    // the per-row filter loop.
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    // Required: TextEditingController holds a ChangeNotifier subscription
    // that will leak if not disposed when the State is removed.
    _searchController.dispose();
    super.dispose();
  }

  // Inserts a new running TimeEntry seeded from the todo's title, project,
  // and category. Enforces a single-timer-at-a-time invariant before inserting.
  void _startTimerFromTodo(BuildContext context, Todo todo) async {
    final db = Provider.of<AppDatabase>(context, listen: false);

    // Check if another timer is already running (endTime IS NULL means active).
    final activeTimers = await (db.select(db.timeEntries)..where((t) => t.endTime.isNull())).get();

    // Guard required after every `await`: the widget tree may have been
    // unmounted while the DB call was in-flight.
    if (!context.mounted) return;

    if (activeTimers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Another timer is already running. Please stop it first.')),
      );
      return;
    }

    // Create a new time entry from the todo
    final newEntry = TimeEntriesCompanion(
      description: drift.Value(todo.title),
      projectId: drift.Value(todo.projectId),
      category: drift.Value(todo.category),
      isBillable: const drift.Value(true),
      startTime: drift.Value(DateTime.now()),
    );

    await db.into(db.timeEntries).insert(newEntry);

    // Second mounted guard: insert is also async.
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Timer for "${todo.title}" has started!')),
    );
  }

  // Shows a confirmation dialog before bulk-deleting completed todos.
  // Returns early (no-op) when the user dismisses without confirming.
  void _clearCompletedTasks(BuildContext context) async {
    final db = Provider.of<AppDatabase>(context, listen: false);

    // showDialog is async; the widget may be unmounted by the time it resolves.
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Completed Tasks'),
          content: const Text('Are you sure you want to delete all completed tasks? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                (db.delete(db.todos)..where((t) => t.isCompleted.equals(true))).go();
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed tasks have been cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    // Join todos with their projects so the list can display project name
    // and the search can match on it. Sorted ascending by deadline so the
    // most urgent tasks surface at the top.
    final query = (db.select(db.todos)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.deadline)]))
        .join([
      drift.innerJoin(
          db.projects, db.projects.id.equalsExp(db.todos.projectId))
    ]);

    return Scaffold(
      body: Column(
        children: [
          // Search bar pinned above the task list. Sits inside a Column
          // (not the AppBar) so it stays visible while the list scrolls
          // and so MainScreen's AppBar title is unaffected.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, description, category, project...',
                prefixIcon: const Icon(Icons.search),
                // Clear button only appears when there's text to clear,
                // so the field doesn't show a useless "x" when empty.
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: query.watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTodos = snapshot.data ?? [];
                // Filter in-memory rather than rebuilding the drift query
                // on every keystroke: avoids resubscribing the stream and
                // lets us search across joined columns uniformly.
                final todosWithProjects = _searchQuery.isEmpty
                    ? allTodos
                    : allTodos.where((row) {
                        final todo = row.readTable(db.todos);
                        final project = row.readTable(db.projects);
                        // Concatenating into one lowercase haystack lets a
                        // single `contains` cover all four fields and
                        // implicitly matches across field boundaries
                        // (e.g. typing the project name finds its tasks).
                        final haystack = [
                          todo.title,
                          todo.description ?? '',
                          todo.category,
                          project.name,
                        ].join(' ').toLowerCase();
                        return haystack.contains(_searchQuery);
                      }).toList();

                // Distinguish "DB is empty" from "search filtered all out"
                // so the empty-state copy tells the user what to do next.
                if (allTodos.isEmpty &&
                    snapshot.connectionState == ConnectionState.active) {
                  return const Center(
                    child: Text("No tasks found. Click '+' to plan your work!"),
                  );
                }

                if (todosWithProjects.isEmpty) {
                  return const Center(
                    child: Text('No tasks match your search.'),
                  );
                }

                return ListView.builder(
                  itemCount: todosWithProjects.length,
                  itemBuilder: (context, index) {
                    final result = todosWithProjects[index];
                    final todo = result.readTable(db.todos);
                    final project = result.readTable(db.projects);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        // Inline checkbox persists the completion toggle
                        // immediately without requiring a separate save action.
                        leading: Checkbox(
                          value: todo.isCompleted,
                          onChanged: (bool? value) {
                            db.update(db.todos).replace(
                                  todo.copyWith(isCompleted: value ?? false),
                                );
                          },
                        ),
                        title: Text(
                          todo.title,
                          // Strike-through signals completion without hiding
                          // the title, so users can still read what was done.
                          style: TextStyle(
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          '${project.name} - Deadline: ${DateFormat.yMd().add_jm().format(todo.deadline)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                todo.priority,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getPriorityColor(todo.priority),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline),
                              tooltip: 'Start Timer for this Task',
                              onPressed: () => _startTimerFromTodo(context, todo),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => TodoEditScreen(todo: todo),
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Two FABs side-by-side. `heroTag` must be unique per FAB within
      // the same route; Flutter throws if two FABs share the same tag.
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _clearCompletedTasks(context),
            label: const Text('Clear Completed'),
            icon: const Icon(Icons.delete_sweep),
            heroTag: 'clear_tasks',
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const TodoEditScreen(),
              ));
            },
            heroTag: 'add_task',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // Maps the three priority levels to a traffic-light palette.
  // P1 (urgent) red → P2 (medium) orange → P3 (low) blue.
  // Falls back to grey for any unrecognised value.
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'P1':
        return Colors.red.shade700;
      case 'P2':
        return Colors.orange.shade700;
      case 'P3':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
