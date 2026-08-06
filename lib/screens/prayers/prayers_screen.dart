import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<Prayer>>(
      stream: db.prayers.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final prayers = snapshot.data ?? [];

        return prayers.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: prayers.length,
                itemBuilder: (context, index) {
                  final prayer = prayers[index];
                  return _buildPrayerCard(prayer);
                },
              );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            'Start Your Prayer Journey',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a prayer and watch God work in your life',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(Prayer prayer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.favorite,
          color: prayer.isAnswered ? Colors.green : Colors.red,
        ),
        title: Text(prayer.title),
        subtitle: Text(prayer.type),
        trailing: Text('${prayer.prayerCount}x'),
      ),
    );
  }
}
