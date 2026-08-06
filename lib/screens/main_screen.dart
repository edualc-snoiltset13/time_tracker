import 'package:flutter/material.dart';
import 'package:time_tracker/screens/home_screen.dart';
import 'package:time_tracker/screens/prayers/prayers_screen.dart';
import 'package:time_tracker/screens/verses/daily_verse_screen.dart';
import 'package:time_tracker/screens/meditations/meditations_screen.dart';
import 'package:time_tracker/screens/devotionals/devotionals_screen.dart';
import 'package:time_tracker/screens/bible_study/bible_study_screen.dart';
import 'package:time_tracker/screens/habits/habits_screen.dart';
import 'package:time_tracker/screens/reflections/reflections_screen.dart';
import 'package:time_tracker/screens/testimonies/testimonies_screen.dart';
import 'package:time_tracker/screens/community/community_prayers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const <Widget>[
    HomeScreen(),
    PrayersScreen(),
    DailyVerseScreen(),
    MeditationsScreen(),
    DevotionalsScreen(),
    BibleStudyScreen(),
    HabitsScreen(),
    ReflectionsScreen(),
    TestimoniesScreen(),
    CommunityPrayersScreen(),
  ];

  final List<String> _titles = const <String>[
    'Divine Life',
    'Prayers',
    'Daily Verse',
    'Meditations',
    'Devotionals',
    'Bible Study',
    'Habits',
    'Reflections',
    'Testimonies',
    'Community',
  ];

  final List<IconData> _icons = const <IconData>[
    Icons.home,
    Icons.favorite,
    Icons.menu_book,
    Icons.spa,
    Icons.light_mode,
    Icons.library_books,
    Icons.check_circle,
    Icons.edit_note,
    Icons.person,
    Icons.people,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icons[_selectedIndex], color: const Color(0xFF9B7FBA)),
            const SizedBox(width: 12),
            Text(_titles[_selectedIndex]),
          ],
        ),
      ),
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(
          _icons.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index].split(' ').first,
          ),
        ),
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF9B7FBA),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A2E),
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
    );
  }
}
