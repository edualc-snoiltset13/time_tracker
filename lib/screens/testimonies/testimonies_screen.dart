import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class TestimoniesScreen extends StatelessWidget {
  const TestimoniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<Testimony>>(
      stream: db.testimonies.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final testimonies = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Testimonies & Blessings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              testimonies.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: testimonies.length,
                      itemBuilder: (context, index) {
                        final testimony = testimonies[index];
                        return _buildTestimonyCard(testimony);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestimonyCard(Testimony testimony) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimony.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${testimony.author}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (testimony.isPublic)
                  const Icon(Icons.public, size: 20, color: Color(0xFF9B7FBA)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              testimony.story,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (testimony.theme != null)
                  Chip(
                    label: Text(testimony.theme!),
                    backgroundColor: const Color(0xFF9B7FBA).withOpacity(0.2),
                  ),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${testimony.impactScore.toInt()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.person, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('Share your spiritual journey'),
        ],
      ),
    );
  }
}
