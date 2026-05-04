# Dev Setup — macOS

## Prerequisites

Install these before anything else.

### 1. Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Flutter SDK
```bash
brew install --cask flutter
flutter doctor  # check for issues
```

Or manually: https://docs.flutter.dev/get-started/install/macos

### 3. Java 17 (needed for Android builds)
```bash
brew install openjdk@17
echo 'export JAVA_HOME=$(brew --prefix openjdk@17)' >> ~/.zshrc
source ~/.zshrc
```

### 4. Xcode (iOS/macOS targets)
- Install from Mac App Store
- Then: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- Accept license: `sudo xcodebuild -license accept`

### 5. Chrome (web target)
- Install Google Chrome normally — Flutter finds it automatically on Mac, no extra config needed.

---

## Clone & Install

```bash
git clone <repo-url>
cd digital-card-flutter
flutter pub get
```

---

## API Configuration

Backend runs on the host machine at `192.168.3.35:3000`.

Already set in `lib/core/constants.dart`:
```dart
static const String baseUrl = 'http://192.168.3.35:3000';
```

> If you move to a different network or the host IP changes, update this line.

---

## Running the App

### Web (Chrome)
```bash
flutter run -d chrome
```

### iOS Simulator
```bash
open -a Simulator
flutter run -d ios
```

### Physical iPhone
- Connect via USB, trust the device
- `flutter devices` to confirm it appears
- `flutter run -d <device-id>`

### Android Emulator
- Open Android Studio → Virtual Device Manager → start an emulator
- Change `baseUrl` to `http://10.0.2.2:3000` for emulator (maps to host loopback)
- `flutter run -d android`

### Physical Android Device
- Enable Developer Options + USB Debugging on device
- Connect USB, `flutter devices` to confirm
- `flutter run -d <device-id>`

---

## Running Tests

```bash
flutter test test/unit/
# 49 tests, no backend needed
```

---

## flutter doctor Checklist

Run `flutter doctor -v` and resolve any `[✗]` items. Common ones on Mac:

| Issue | Fix |
|---|---|
| Xcode not found | Install Xcode from App Store |
| CocoaPods missing | `sudo gem install cocoapods` |
| Android SDK missing | Install Android Studio, open SDK Manager |
| Java version wrong | Ensure `JAVA_HOME` points to JDK 17 |
| Chrome not found | Install Google Chrome |

---

## Project Structure Quick Reference

```
lib/
├── core/
│   ├── constants.dart          ← baseUrl lives here
│   ├── di/providers.dart       ← Dio, storage, interceptor
│   ├── network/auth_interceptor.dart
│   └── router/router.dart
├── features/
│   ├── auth/                   ← login, register, splash
│   ├── cards/                  ← card CRUD, builder, detail
│   └── share/                  ← public card, share sheet
└── shared/
    ├── utils/                  ← color, validators, vcard
    └── widgets/                ← reusable UI components
```

Full API docs and endpoint reference: `CONFIG.md`
