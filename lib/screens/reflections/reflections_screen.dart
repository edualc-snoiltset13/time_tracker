import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class ReflectionsScreen extends StatelessWidget {
  const ReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<Reflection>>(
      stream: db.reflections.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final reflections = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Reflections',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              reflections.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reflections.length,
                      itemBuilder: (context, index) {
                        final reflection = reflections[index];
                        return _buildReflectionCard(reflection);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReflectionCard(Reflection reflection) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          reflection.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(reflection.mood ?? 'Reflective'),
        leading: _buildMoodIcon(reflection.mood),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reflection.content,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 12),
                if (reflection.gratitudeItems != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Gratitude: ${reflection.gratitudeItems}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF6BBE92),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Faith Score: ${reflection.faithScore}/10',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    Icon(
                      reflection.isPrivate ? Icons.lock : Icons.public,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIcon(String? mood) {
    final iconMap = {
      'Peaceful': Icons.favorite,
      'Grateful': Icons.sentiment_satisfied,
      'Challenged': Icons.psychology,
      'Hopeful': Icons.lightbulb,
      'Joyful': Icons.star,
    };
    return Icon(iconMap[mood] ?? Icons.sentiment_neutral);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('Start journaling your thoughts'),
        ],
      ),
    );
  }
}
