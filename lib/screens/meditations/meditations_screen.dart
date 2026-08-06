import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class MeditationsScreen extends StatelessWidget {
  const MeditationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<Meditation>>(
      stream: db.meditations.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final meditations = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeditationStartCard(),
              const SizedBox(height: 24),
              const Text(
                'Past Sessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              meditations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: meditations.length,
                      itemBuilder: (context, index) {
                        final med = meditations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.spa, color: Color(0xFF6BBE92)),
                            title: Text(med.title),
                            subtitle: Text('${med.durationMinutes} minutes'),
                            trailing: _buildPeaceScore(med.peaceScore),
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

  Widget _buildMeditationStartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6BBE92), Color(0xFF4B9BE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start a Meditation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Find peace and clarity in just 10-20 minutes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6BBE92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Text(
                'Begin Meditation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeaceScore(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6BBE92).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber[600]),
          const SizedBox(width: 4),
          Text(score.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.spa, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('Begin your meditation practice'),
        ],
      ),
    );
  }
}
