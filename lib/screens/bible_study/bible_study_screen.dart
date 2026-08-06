import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class BibleStudyScreen extends StatelessWidget {
  const BibleStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<BibleStudy>>(
      stream: db.bibleStudies.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final studies = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudyStatsCard(studies),
              const SizedBox(height: 24),
              const Text(
                'Study Sessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              studies.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: studies.length,
                      itemBuilder: (context, index) {
                        final study = studies[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.library_books, color: Color(0xFF9B7FBA)),
                            title: Text('${study.book} ${study.chapter}'),
                            subtitle: Text('${study.timeSpentMinutes} min study'),
                            trailing: Text(study.keyTakeaway ?? 'In Progress'),
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

  Widget _buildStudyStatsCard(List<BibleStudy> studies) {
    final totalMinutes = studies.fold<int>(0, (sum, s) => sum + s.timeSpentMinutes);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9B7FBA).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Sessions', studies.length.toString()),
          _buildStatItem('Total Time', '$totalMinutes min'),
          _buildStatItem('Books', '${studies.length > 0 ? 1 : 0}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9B7FBA),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.library_books, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('Start a Bible study session'),
        ],
      ),
    );
  }
}
