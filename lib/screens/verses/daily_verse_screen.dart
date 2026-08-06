import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class DailyVerseScreen extends StatelessWidget {
  const DailyVerseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return StreamBuilder<List<DailyVerse>>(
      stream: db.dailyVerses.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final verses = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodayVerseCard(),
              const SizedBox(height: 24),
              const Text(
                'Your Reading History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              verses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        final verse = verses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.menu_book, color: Color(0xFF4B9BE0)),
                            title: Text('${verse.book} ${verse.chapter}:${verse.verses}'),
                            subtitle: Text(verse.translation),
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

  Widget _buildTodayVerseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B9BE0), Color(0xFF6BBE92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Verse',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '"Trust in the Lord with all your heart and lean not on your own understanding."',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Proverbs 3:5',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.menu_book, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text('No verses read yet'),
        ],
      ),
    );
  }
}
