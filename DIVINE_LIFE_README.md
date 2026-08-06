# Divine Life - Religious & Spiritual Companion App

A comprehensive Flutter application designed to nurture faith, deepen spiritual practice, and connect believers in community through prayer, scripture study, meditation, and daily devotionals.

## 🙏 Overview

Divine Life transforms personal spirituality into a daily practice with 10 interconnected features:

1. **Dashboard** - Home screen with spiritual metrics and daily inspiration
2. **Prayer Journal** - Track prayers, intercessions, and answered prayers
3. **Daily Verse** - Scripture reading with reflections and multiple translations
4. **Meditations** - Guided meditation sessions with peace scoring
5. **Devotionals** - Structured daily spiritual readings
6. **Bible Study** - Deep scripture study with notes and interpretations
7. **Habit Tracker** - Monitor spiritual practices with streak tracking
8. **Reflections** - Daily journaling with mood and gratitude logging
9. **Testimonies** - Share and read spiritual stories and blessings
10. **Community Prayers** - Join intercession with shared prayer requests

## 🗄️ Database Architecture

Redesigned from the original time_tracker with 11 dedicated spiritual tables using Drift ORM:

### Core Tables

**Prayers**
- Personal, Gratitude, Intercession, Praise types
- Track prayer counts and answered prayers
- Intention notes and answer tracking
- Public/private sharing

**DailyVerse**
- Scripture passages with multiple translations
- Reading history and reflection notes
- Engagement scoring
- Daily tracking

**Meditations**
- Session types: Mindfulness, Breath, Gratitude, Scripture
- Duration, difficulty, and peace scores
- Guided/unguided distinction
- Session notes

**DailyDevotionals**
- Structured readings with scripture, message, application
- Prayer integration
- Completion tracking
- Topic organization

**BibleStudy**
- Deep study sessions with observations
- Interpretations and applications
- Time tracking
- Key takeaways

**SpiritualHabits**
- Prayer, Meditation, Reading, Fasting, Service habits
- Current and longest streak tracking
- Weekly frequency settings
- Daily completion checkboxes

**Reflections**
- Journal entries with title and content
- Mood tracking (Peaceful, Grateful, Challenged, Hopeful, Joyful)
- Gratitude items logging
- Faith score (1-10)
- Private/public entries

**Testimonies**
- Spiritual stories with author
- Theme categorization (Healing, Provision, Guidance, Transformation)
- Impact scoring and share counts
- Public/private sharing

**Blessings**
- Gratitude for answered prayers and blessings
- Category organization (Health, Relationships, Provision, Spiritual, Family)
- Gratitude level tracking

**FaithGoals**
- Long-term spiritual growth goals
- Categories: Spiritual Growth, Service, Learning, Practice
- Progress tracking
- Step-by-step planning

**CommunityPrayers**
- Shared prayer requests from community
- Prayer count tracking
- Category organization
- Active/inactive status

## 🎨 Design & Theme

### Color Palette (Spiritual)
```
Primary Purple:      #6B4BA3  (Deep spiritual)
Accent Lavender:     #9B7FBA  (Highlights)
Dark Background:     #0F0F1E  (Deep dark)
Card Background:     #1A1A2E  (Subtle)

Feature Colors:
- Prayer/Love:       #E94B3C  (Red)
- Scripture:         #4B9BE0  (Blue)
- Meditation:        #6BBE92  (Green)
- Devotional:        #FFB84D  (Amber)
```

### UI Components
- Gradient header cards for featured content
- Responsive 2-column grid layouts
- Expandable detail cards
- Progress bars with streak visualization
- Icon-based 10-tab navigation
- Material Design with modern spacing

## 📱 Navigation

**Bottom Navigation Bar (10 Tabs):**
1. 🏠 Divine Life (Dashboard)
2. ❤️ Prayers
3. 📖 Daily Verse
4. 🧘 Meditations
5. ☀️ Devotionals
6. 📚 Bible Study
7. ✅ Habits
8. 📝 Reflections
9. 👤 Testimonies
10. 👥 Community

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry & theming
├── database/
│   ├── database.dart                  # Drift schema (11 tables)
│   └── database.g.dart                # Auto-generated (don't edit)
└── screens/
    ├── home_screen.dart               # Dashboard
    ├── main_screen.dart               # Bottom nav controller
    ├── prayers/prayers_screen.dart
    ├── verses/daily_verse_screen.dart
    ├── meditations/meditations_screen.dart
    ├── devotionals/devotionals_screen.dart
    ├── bible_study/bible_study_screen.dart
    ├── habits/habits_screen.dart
    ├── reflections/reflections_screen.dart
    ├── testimonies/testimonies_screen.dart
    └── community/community_prayers_screen.dart
```

## 🔧 Setup & Build

### Prerequisites
- Flutter SDK >= 3.8.1
- Dart >= 3.8.1

### Installation

```bash
# Get dependencies
flutter pub get

# Generate database code (required after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run -d macos           # macOS
```

### Building for Release

```bash
flutter build apk              # Android
flutter build ios              # iOS
flutter build web              # Web
flutter build macos            # macOS
flutter build windows          # Windows
flutter build linux            # Linux
```

## 📊 Key Features Explained

### Dashboard
- Welcome greeting with gradient card
- 4-stat overview grid (Prayers, Verses, Meditations, Streaks)
- Today's Focus with suggested practices
- Daily inspirational scripture quote
- Beautiful color-coded stat cards

### Prayer Journal
Stream-based reactive list of prayers with:
- Prayer type badges
- Prayer count indicator
- Answered prayer visual indicator (green/red heart)
- Expandable details
- Answer notes and dates

### Daily Verse
- Featured "Today's Verse" card with gradient
- Full reading history
- Multiple translation support
- Reflection notes per verse
- Engagement tracking

### Meditations
- Start meditation button with gradient card
- Past sessions list with duration and peace score
- Topic filtering
- Difficulty levels
- Guided/unguided distinction

### Devotionals
- Featured today's devotional card
- Completion tracking
- Topic and scripture display
- Quick access to full devotional content
- Status indicators

### Bible Study
- Study statistics card (sessions, total time, books)
- Deep study session history
- Key takeaway display
- Time spent tracking
- Progress indicators

### Habit Tracker
- Habit cards with completion status
- Current and longest streak visualization
- Progress bars
- Weekly frequency settings
- Habit notes

### Reflections
- Expandable journal entries
- Mood icons (Peaceful, Grateful, etc.)
- Content preview in list
- Full content in expansion
- Privacy indicators
- Gratitude highlighting

### Testimonies
- Testimony cards with story preview
- Author attribution
- Theme chips
- Impact scores
- Public/private icons
- Share counts

### Community Prayers
- Active prayer request cards
- Prayer count buttons (tappable)
- Category organization
- Active/inactive status badges
- Submitter attribution
- Beautiful card layout

## 💾 Local Database

- **Storage:** `divine_life.sqlite` in app support directory
- **ORM:** Drift v2.18.0 with code generation
- **Schema Version:** 1 (fresh start)
- **Foreign Keys:** Cascade delete enabled
- **No Cloud Sync:** All data stored locally

## 🎯 Architecture Patterns

### State Management
- `AppDatabase` provided at root via `Provider<AppDatabase>`
- Screens access: `Provider.of<AppDatabase>(context, listen: false)`
- Reactive UI via `StreamBuilder` with Drift `.watch()` streams

### Form Handling (Ready for Implementation)
- Standard Flutter `Form` with `GlobalKey<FormState>`
- `TextFormField` with validators
- Confirmation dialogs for destructive actions
- `ScaffoldMessenger.showSnackBar()` for feedback

### Database Operations
- `Companion` objects for inserts/updates
- `.where()`, `.orderBy()`, `.limit()` builders
- Reactive streams via `.watch()`
- Type-safe queries

## 📈 Future Enhancements

### Phase 2 - Forms & CRUD
- Prayer creation/editing dialog
- Bible verse logging form
- Meditation session start screen
- Reflection journal entry editor
- Testimony submission form
- Community prayer request form

### Phase 3 - Advanced Features
- Daily push notifications for devotionals
- Prayer reminders (customizable times)
- Habit streak notifications
- Weekly spiritual growth reports
- Analytics dashboard
- Data export (CSV, PDF)

### Phase 4 - Community Features
- User authentication (Firebase)
- Prayer sharing with friends
- Testimony moderation system
- Community leaderboard (optional)
- Prayer answer celebration feed
- Spiritual mentorship matching

### Phase 5 - Gamification & Analytics
- Spiritual growth score
- Achievement badges
- Habit completion streaks with rewards
- Monthly reflection reviews
- Bible reading progress
- Community impact metrics

## 🔒 Privacy & Security

- All data stored locally in SQLite
- No cloud storage or external APIs (local-only)
- Private journal and prayer options
- Public/private toggle for testimonies
- User-controlled data sharing
- No tracking or analytics

## 🙏 Spiritual Content

### Pre-loaded Scripture
- Daily verse system with multiple translations
- Scripture references for devotionals
- Bible study passage tracking
- Quote system (Jeremiah 29:11 featured)

### Categories & Types
- Prayer types: Personal, Gratitude, Intercession, Praise
- Meditation topics: Mindfulness, Breath, Gratitude, Scripture
- Habit types: Prayer, Meditation, Reading, Fasting, Service
- Testimony themes: Healing, Provision, Guidance, Transformation

## 📚 Code Conventions

- **Classes:** PascalCase (`PrayersScreen`)
- **Methods/Variables:** camelCase (`buildPrayerCard`)
- **Private Members:** `_underscore` prefix
- **Database Tables:** PascalCase (`Prayers`, `DailyVerse`)
- **Imports:** Package imports (`package:time_tracker/...`)
- **Async Safety:** Check `context.mounted` before UI updates

## 🚀 Getting Started with Development

1. **Generate Database Code:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Create a Form Screen Example:**
   - Copy prayer form pattern from time_tracker
   - Add validation
   - Implement database inserts

3. **Add a Feature Screen:**
   - Create folder in `screens/`
   - Implement `StreamBuilder` for data
   - Design UI with consistent theming

4. **Test in Emulator:**
   - Create sample data
   - Test navigation
   - Verify database operations

## 📝 Example: Adding Prayer Entry

```dart
// In prayers edit screen
final newPrayer = PrayersCompanion(
  title: drift.Value(titleController.text),
  content: drift.Value(contentController.text),
  type: drift.Value(selectedType),
  createdDate: drift.Value(DateTime.now()),
);
await db.into(db.prayers).insert(newPrayer);
```

## 🔗 Dependencies

- `flutter` (framework)
- `provider` (state management)
- `drift` (ORM & database)
- `intl` (internationalization)
- `path_provider` (file system)

## 📄 License

Part of the Time Tracker family of applications.

## 🙌 Contributing

To add new features:
1. Create new Drift table if needed
2. Add screen in organized folder
3. Update `main_screen.dart` navigation
4. Follow existing code patterns
5. Test with sample data

## 💬 Support

For issues or feature requests:
1. Check existing database schema
2. Review similar feature implementations
3. Follow established patterns
4. Test thoroughly before committing

---

**Divine Life v1.0** - Building stronger faith, one practice at a time. ✨

*Last Updated: August 6, 2026*
