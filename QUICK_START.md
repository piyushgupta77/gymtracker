# 🚀 QUICK START GUIDE - Gym Tracker

## First Time Running the App

### Prerequisites
- Flutter SDK installed (3.11.5+)
- Android SDK installed (or iOS SDK for macOS)
- Device connected (physical or emulator running)

### Step 1: Install Dependencies
```bash
cd /Users/piyushgupta/AndroidStudioProjects/gym_tracker
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

**Expected Output:**
```
Launching lib/main.dart on [device]...
Running Gradle task 'assembleDebug'... (takes ~30-60 seconds first time)
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk... (takes ~10-20 seconds)
Syncing files to device [device]... (takes a few seconds)
D/FlutterGeolocator( 9696): FlutterGeolocatorPlugin onMethodCall
I/flutter ( 9696): Gym Tracker app is running!
```

---

## First App Interaction

### When App Launches
1. ✅ You see a calendar with current month displayed
2. ✅ Today's date is highlighted (secondary purple color)
3. ✅ No workouts visible yet (you can add them!)

### Try Adding a Workout
1. Tap the **blue circular button** (FAB) in bottom-right corner
2. **WorkoutDetailsScreen** opens
3. Enter a workout:
   - **Heading**: "First Workout"
   - **Notes**: "Test workout - bench press, squats, etc."
4. Tap **Save** button
5. ✅ You'll see a green success message
6. ✅ AutoMatically returns to calendar
7. ✅ Workout appears on today's date!

### Try Editing the Workout
1. Tap today's date on the calendar
2. Your workout preview shows at the bottom
3. Tap the preview or the date again
4. **WorkoutDetailsScreen** opens with your data
5. Modify the content
6. Tap **Save**
7. ✅ Changes saved and displayed

### Try Different Dates
1. Tap a different date on the calendar
2. Message shows "No workout recorded"
3. Tap FAB to add workout for that date
4. Fill in data and save
5. ✅ Multiple dates can have different workouts

### Navigate Months
1. Use **< >** arrows at top of calendar
2. Navigate to previous or future months
3. All your saved workouts persist across months!

---

## Testing Checklist

Print this out and check off as you test:

### Basic Navigation
- [ ] App launches without crash
- [ ] Calendar displays current month
- [ ] Current date is highlighted
- [ ] Can navigate to other months

### Adding Workouts
- [ ] FAB opens WorkoutDetailsScreen
- [ ] Can type in title field
- [ ] Can type in notes area
- [ ] Save button works
- [ ] Success message appears
- [ ] Workout appears on calendar
- [ ] Can add multiple workouts on same date? (No - replaces)

### Editing Workouts
- [ ] Can tap existing workout
- [ ] Details screen shows previous data
- [ ] Can modify content
- [ ] Save updates the workout
- [ ] Changes appear on calendar

### Cancel/Back
- [ ] Cancel button closes screen without saving
- [ ] Back button closes screen without saving
- [ ] If unsaved changes: dialog appears
- [ ] Dialog options work correctly

### Data Persistence
- [ ] Close app completely
- [ ] Reopen app
- [ ] Previously saved workouts still visible
- [ ] Can still edit them

### Error Handling
- [ ] Try to save empty title
- [ ] Error message appears: "Please enter a heading"
- [ ] Can fix and save successfully

---

## Common Issues & Fixes

### App Won't Build
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Dependencies Not Found
```bash
# Update packages
flutter pub upgrade
flutter pub get
```

### App Crashes on Startup
- Check Flutter version: `flutter --version`
- Should be 3.11.5 or higher
- Update: `flutter upgrade`

### Database Issues
```bash
# Reset app state
flutter clean
# Reinstall: Uninstall app from device, then:
flutter run
```

### Keyboard Overlay Issues
- App automatically handles keyboard
- Buttons move above keyboard when typing
- Should work correctly

---

## Development Tips

### Hot Reload
- Make code changes
- Press `r` in terminal to hot reload
- Changes apply instantly (without losing data)

### Hot Restart
- Press `R` in terminal to hot restart
- Full app restart (data may reset)
- Use when hot reload doesn't work

### View Logs
```bash
# See real-time logs
flutter logs

# View specific error
flutter logs | grep -i error
```

### Debug Mode
```bash
# Run in debug mode with debugging
flutter run -v
```

### Build Release APK
```bash
flutter build apk
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## File Locations

### Important Paths
```
Project Root:
/Users/piyushgupta/AndroidStudioProjects/gym_tracker/

Source Code:
lib/main.dart                          # Entry point
lib/models/workout.dart               # Data model
lib/services/database_service.dart    # Database
lib/providers/workout_provider.dart   # State
lib/screens/home_screen.dart          # Calendar
lib/screens/workout_details_screen.dart # Editor

Database File (on device):
/data/user/0/com.example.gym_tracker/databases/gym_tracker.db

Build Output:
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk

Documentation:
IMPLEMENTATION_GUIDE.md               # Technical details
QUICK_REFERENCE.md                    # API reference
VISUAL_COMPONENT_GUIDE.md            # UI/Component structure
IMPLEMENTATION_SUMMARY.md             # Project overview
```

---

## Device Requirements

### Minimum
- Android 5.1 (API level 22) or higher
- iOS 11.0 or higher

### Recommended for Development
- Physical device or emulator with 2GB+ RAM
- Latest Android Studio or VS Code with Flutter extension
- Android SDK (API 30+)

---

## Project Structure Reminder

```
lib/
├── main.dart                    ← App entry point
├── models/workout.dart         ← Data model
├── services/database_service.dart ← Database layer
├── providers/workout_provider.dart ← State management
└── screens/
    ├── home_screen.dart        ← Calendar view
    └── workout_details_screen.dart ← Note editor
```

---

## Documentation Files

1. **This File** - Quick start & testing guide
2. **IMPLEMENTATION_SUMMARY.md** - Project overview
3. **IMPLEMENTATION_GUIDE.md** - Technical architecture
4. **QUICK_REFERENCE.md** - Code examples & API
5. **VISUAL_COMPONENT_GUIDE.md** - UI structure & flows

---

## Next Steps

### If Everything Works ✅
- Congratulations! Your app is ready to use
- Start logging your workouts
- See the documentation for advanced features

### If You Want to Customize
- Edit `lib/main.dart` to change theme colors
- Modify `lib/screens/home_screen.dart` for UI changes
- Add new features using `WorkoutProvider`

### If You Want to Deploy
```bash
# Build production APK
flutter build apk --release

# Build production iOS app
flutter build ios --release

# Share the APK
# File: build/app/outputs/flutter-apk/app-release.apk
```

---

## Troubleshooting Checklist

Problem: App won't launch
→ Solution: `flutter clean && flutter pub get && flutter run`

Problem: Build errors
→ Solution: Check Flutter version `flutter --version`

Problem: Workouts not saving
→ Solution: Check database permissions, run `flutter run -v` for detailed logs

Problem: Calendar not showing
→ Solution: Ensure `table_calendar` package installed, try hot restart

Problem: Keyboard covers inputs
→ Solution: This is handled automatically, scroll or use Back button

---

## Getting Help

### Check Documentation First
1. QUICK_REFERENCE.md for API usage
2. IMPLEMENTATION_GUIDE.md for architecture
3. VISUAL_COMPONENT_GUIDE.md for UI structure

### Common Questions

**Q: Where's my data stored?**
A: SQLite database on your device at `/data/user/0/com.example.gym_tracker/databases/gym_tracker.db`

**Q: Can I backup my data?**
A: Yes, the database is a regular SQLite file. You can copy it to backup.

**Q: Can I export workouts?**
A: Currently no, but you can implement this by modifying DatabaseService

**Q: Will data sync across devices?**
A: No, each device has its own database. You could add cloud sync later.

**Q: Can I delete a workout?**
A: The UI doesn't have a delete button, but WorkoutProvider has deleteWorkout() method. You could add a delete action.

---

## Quick Demo Script (2 minutes)

If showing someone the app:

1. **Launch** (10 sec)
   - Tap and hold app icon or use `flutter run`
   - Show calendar view with current date highlighted

2. **Add Workout** (30 sec)
   - Tap FAB button
   - Enter "Upper Body - Push"
   - Type "Bench 5x5, Overhead press 4x8"
   - Tap Save
   - Point out success message and workout on calendar

3. **Add Another Date** (30 sec)
   - Tap different date
   - Add "Leg Day" with "Squats, Deadlifts"
   - Save and show calendar now has 2 workouts

4. **Edit Workout** (30 sec)
   - Tap first workout date
   - Change "Upper Body - Push" to "Upper Body - Push + Core"
   - Save and show update

5. **Navigate** (10 sec)
   - Use calendar arrows to go back/forward
   - Show workouts persist across months

**Total Time: ~2 minutes**

---

**You're all set! Happy tracking! 💪**

Generated: October 1, 2026

