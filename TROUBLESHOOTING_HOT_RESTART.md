# Troubleshooting Hot Restart Issue

## Error
```
Bad state: Could not find summary for library "package:faminga_irrigation/screens/profile/edit_profile_screen.dart"
```

## Solution

This is a Flutter build cache issue. Follow these steps to fix it:

### Option 1: Quick Fix (Try this first)
```bash
# Stop the app completely
# Then run:
flutter clean
flutter pub get
flutter run
```

### Option 2: Deep Clean (If Option 1 doesn't work)
```bash
# Stop the app
# Delete build artifacts manually:
rm -rf .dart_tool
rm -rf build
rm -rf .flutter-plugins-dependencies
rm -rf .packages

# Then rebuild:
flutter pub get
flutter run
```

### Option 3: IDE Cache Clear (If using VS Code or Android Studio)

**VS Code**:
1. Close VS Code
2. Delete `.vscode` folder (if exists)
3. Reopen VS Code
4. Run `flutter clean`
5. Run `flutter pub get`
6. Restart debugging

**Android Studio**:
1. File → Invalidate Caches / Restart
2. Run `flutter clean`
3. Run `flutter pub get`
4. Restart debugging

### Option 4: Full Restart (Nuclear option)
```bash
# Stop all Flutter processes
flutter clean
flutter pub cache repair
flutter pub get
flutter run
```

## Why This Happens

This error typically occurs when:
1. **Build cache is corrupted**: Flutter's analyzer has stale data
2. **Hot restart during compilation**: Interrupted a previous build
3. **File changes during build**: Files were modified while building
4. **IDE issues**: VS Code/Android Studio has outdated information

## Prevention

To avoid this in the future:
1. **Use Hot Reload** (R) instead of Hot Restart (Shift+R) when possible
2. **Stop debugging** before making major code changes
3. **Run `flutter clean`** after pulling from git
4. **Avoid editing files** while the app is building

## If Still Not Working

If none of the above work, try:

1. **Check for syntax errors**:
   ```bash
   flutter analyze
   ```

2. **Check for import issues**:
   - Ensure all imports are correct
   - No circular dependencies
   - All files exist

3. **Restart your computer**: Sometimes system resources are locked

4. **Update Flutter**:
   ```bash
   flutter upgrade
   ```

5. **Check Flutter doctor**:
   ```bash
   flutter doctor -v
   ```

## Current Status

The `edit_profile_screen.dart` file has **no syntax errors** - only warnings (which are non-critical).

The issue is purely a build cache problem, not a code problem.

## Recommended Action

Run these commands in order:
```bash
# 1. Clean
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Run app (NOT hot restart)
flutter run -d chrome
```

**Important**: Start fresh with `flutter run`, don't try to hot restart.
