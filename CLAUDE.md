# Digital Card — Flutter App

## Stack
- **Flutter** (web + Android/iOS) — `flutter run -d chrome` (requires `CHROME_EXECUTABLE=/usr/bin/chromium`)
- **Backend** — NestJS at `http://localhost:3000` (separate repo: `~/Documents/digital_card`)
- **State** — Riverpod 2.x (`flutter_riverpod`)
- **Routing** — GoRouter 14.x
- **HTTP** — Dio 5.x with JWT auth interceptor
- **Storage** — `flutter_secure_storage` (localStorage on web, keychain/keystore on mobile)

## Running

```bash
# Web (Chromium already configured in ~/.zshrc)
flutter run -d chrome

# Android (requires device connected — Gradle needs Java ≤ 17)
flutter run -d android

# Tests
flutter test test/unit/
```

## Architecture

```
lib/
├── core/
│   ├── constants.dart          # baseUrl, StorageKeys
│   ├── di/providers.dart       # Dio, SecureStorage, AuthInterceptor providers
│   ├── network/auth_interceptor.dart  # JWT attach + refresh + 401 queue
│   ├── router/router.dart      # GoRouter setup (use ref.read NOT ref.watch)
│   ├── router/routes.dart      # Route path constants
│   ├── storage/secure_storage.dart
│   └── theme/                  # AppTheme, AppColors, AppTextStyles
├── features/
│   ├── auth/
│   │   ├── domain/user_model.dart
│   │   ├── data/auth_repository.dart   # login, register, logout, getMe
│   │   ├── providers/auth_provider.dart # AuthNotifier (ChangeNotifier) + AuthState sealed
│   │   └── screens/            # splash, login, register
│   ├── cards/
│   │   ├── domain/card_data.dart       # CardData, SocialLink, CardTemplate
│   │   ├── domain/card_model.dart      # CardModel (server response wrapper)
│   │   ├── data/card_repository.dart   # CRUD + public card
│   │   ├── providers/cards_provider.dart       # CardsNotifier (AsyncNotifier)
│   │   ├── providers/card_builder_provider.dart # CardBuilderNotifier (StateNotifier.family)
│   │   └── screens/            # home, card_builder, card_detail
│   └── share/
│       └── screens/            # public_card_screen, share_bottom_sheet
└── shared/
    ├── utils/color_utils.dart  # hexToColor, colorToHex
    ├── utils/validators.dart   # required, email, password, url, hexColor
    ├── utils/vcard.dart        # vCard export
    └── widgets/                # card_widget, social_chip, template_picker, etc.
```

## Key Design Decisions

### Router
- `routerProvider` uses `ref.read(authProvider)` — NOT `ref.watch`. Using `ref.watch` rebuilds GoRouter on every auth state change, disposing the old router's stream → "Bad state: Cannot add new events after calling close".
- Router redirect handles splash: stays on splash while `AuthInitial | AuthLoading`, redirects after auth check completes. Does NOT rely on `ref.listen` in SplashScreen for navigation.

### Auth Flow
1. App opens → splash (`/`)
2. `checkSession()` reads token from storage → calls `GET /users/me`
3. Router redirect fires on `notifyListeners()` → navigates to `/home` or `/login`
4. 401 on any request → `AuthInterceptor` tries refresh token → queues pending requests
5. Refresh fails → `onUnauthenticated()` → `authNotifier.forceLogout()` → router redirects to login

### Card Builder
- `cardBuilderProvider` is a `StateNotifierProvider.family<CardBuilderNotifier, CardData, CardData?>` keyed on initial data
- Edit mode: `_initialData` is loaded from `cardsProvider` cache in `didChangeDependencies`
- New card: `_initialData` is null → fresh `CardData.empty()`
- Save uses `addPostFrameCallback` for `context.pop()` to avoid GoRouter stream errors on web

### Appearance
- 3 card templates: `minimal`, `bold`, `glass` — rendered in `CardWidget` which picks sub-widget
- Accent color: hex string stored in `CardData.accentColor`, color picker via `flutter_colorpicker`
- Import `flutter_colorpicker` with `hide colorToHex` to avoid name conflict with `color_utils.dart`

## API Endpoints (NestJS backend)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Register, returns `{access_token, refresh_token, user}` |
| POST | `/auth/login` | Login, returns `{access_token, refresh_token, user}` |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/refresh` | Refresh tokens (Bearer refresh_token) |
| GET | `/users/me` | Current user |
| GET | `/cards` | All cards for user |
| POST | `/cards` | Create card |
| PATCH | `/cards/:id` | Update card |
| DELETE | `/cards/:id` | Delete card |
| GET | `/public/:slug` | Public card (no auth) |

## Tests
```
test/unit/
├── validators_test.dart         # all Validators.* methods
├── color_utils_test.dart        # hexToColor / colorToHex roundtrip
├── card_data_test.dart          # CardData fromJson/toJson/copyWith, SocialLink, CardTemplate
├── auth_state_test.dart         # AuthState sealed class variants
└── card_builder_notifier_test.dart  # CardBuilderNotifier field setters, socials, reset
```
Run: `flutter test test/unit/` — 49 tests, no mocks needed.

## Known Web-Specific Issues Fixed
1. `CHROME_EXECUTABLE=/usr/bin/chromium` required (Arch Linux uses `chromium` not `google-chrome`)
2. `baseUrl` must be `http://localhost:3000` (not `http://10.0.2.2:3000` which is Android emulator)
3. `flutter_colorpicker` exports `colorToHex` conflicting with `color_utils.dart` — fix: `hide colorToHex` in import
4. `ActionChip` has no `deleteIcon`/`onDeleted` — use `FilterChip` when delete is needed
5. `WidgetsFlutterBinding.ensureInitialized()` needed in `main()` before `runApp`
6. Router must use `ref.read` (not `ref.watch`) to avoid GoRouter stream lifecycle errors
