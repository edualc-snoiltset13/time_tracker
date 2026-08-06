import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<SpiritualHabit>>(
      stream: db.spiritualHabits.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final habits = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spiritual Habits',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              habits.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return _buildHabitCard(habit);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitCard(SpiritualHabit habit) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  habit.habitName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  habit.completed ? Icons.check_circle : Icons.circle_outlined,
                  color: habit.completed ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStreakBar(habit.streak, habit.longestStreak),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Streak: ${habit.streak} days',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                Text(
                  'Best: ${habit.longestStreak} days',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBar(int current, int longest) {
    final percentage = longest > 0 ? (current / longest) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: percentage,
        minHeight: 8,
        backgroundColor: Colors.grey[700],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6BBE92)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('No habits tracked yet'),
        ],
      ),
    );
  }
}
