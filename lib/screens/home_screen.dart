import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildStatisticsGrid(db),
          const SizedBox(height: 24),
          _buildTodayFocusCard(),
          const SizedBox(height: 24),
          _buildSpiritualQuoteCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4BA3), Color(0xFF9B7FBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Divine Life',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nurture your faith and spiritual growth',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(AppDatabase db) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('Prayers', '12', Icons.favorite, const Color(0xFFE94B3C)),
        _buildStatCard('Verses Read', '8', Icons.menu_book, const Color(0xFF4B9BE0)),
        _buildStatCard('Meditations', '5', Icons.spa, const Color(0xFF6BBE92)),
        _buildStatCard('Streak Days', '21', Icons.whatshot, const Color(0xFFFFB84D)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFocusCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.light_mode, color: Color(0xFF9B7FBA), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Focus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '1. Morning Prayer - 10 minutes\n2. Read Daily Verse\n3. Meditation - 15 minutes\n4. Evening Reflection',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4B9BE0).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Color(0xFF4B9BE0), size: 28),
          const SizedBox(height: 12),
          const Text(
            '"For I know the plans I have for you, declares the Lord, plans for welfare and not for evil, to give you a future and a hope."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jeremiah 29:11',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
