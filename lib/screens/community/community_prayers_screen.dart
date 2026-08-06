import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class CommunityPrayersScreen extends StatelessWidget {
  const CommunityPrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<CommunityPrayer>>(
      stream: db.communityPrayers.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final prayers = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Community Prayer Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              prayers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prayers.length,
                      itemBuilder: (context, index) {
                        final prayer = prayers[index];
                        return _buildCommunityPrayerCard(prayer);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityPrayerCard(CommunityPrayer prayer) {
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
                        prayer.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (prayer.submitter != null)
                        Text(
                          'by ${prayer.submitter}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
                if (prayer.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6BBE92).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6BBE92),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              prayer.request,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (prayer.category != null)
                  Chip(
                    label: Text(prayer.category!),
                    backgroundColor: const Color(0xFF4B9BE0).withOpacity(0.2),
                  ),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${prayer.prayerCount} prayers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
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
          Icon(Icons.people, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('No community prayers yet'),
          const SizedBox(height: 12),
          const Text(
            'Join others in intercession',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
