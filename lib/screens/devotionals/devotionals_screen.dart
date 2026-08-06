import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class DevotionalsScreen extends StatelessWidget {
  const DevotionalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<DailyDevotional>>(
      stream: db.dailyDevotionals.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final devotionals = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodayDevotionalCard(),
              const SizedBox(height: 24),
              devotionals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devotionals.length,
                      itemBuilder: (context, index) {
                        final dev = devotionals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.light_mode, color: Color(0xFFFFB84D)),
                            title: Text(dev.topic),
                            subtitle: Text(dev.scripture),
                            trailing: Icon(
                              dev.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                              color: dev.isCompleted ? Colors.green : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayDevotionalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB84D), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Devotional',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Topic: God\'s Faithfulness',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '"The Lord is faithful to all his promises and loving toward all he has made." - Psalm 145:13',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFFB84D),
            ),
            onPressed: () {},
            child: const Text('Read Full Devotional'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.light_mode, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('No devotionals yet'),
        ],
      ),
    );
  }
}
