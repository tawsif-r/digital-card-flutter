# Digital Card — Flutter App

## Stack
- **Flutter** (web + Android/iOS) — `flutter run -d chrome` (requires `CHROME_EXECUTABLE=/usr/bin/chromium`)
- **Backend** — NestJS at `http://localhost:3000` (separate repo: `~/Documents/digital_card`)
- **State** — Riverpod 2.x (`flutter_riverpod`)
- **Routing** — GoRouter 14.x
- **HTTP** — Dio 5.x with JWT auth interceptor
- **Storage** — `flutter_secure_storage` (localStorage on web, keychain/keystore on mobile)
- **WebSocket** — `socket_io_client` for real-time messaging

## Running

```bash
# Web (Chromium already configured in ~/.zshrc)
flutter run -d chrome

# Android (physical device — 8GB RAM machine, NEVER emulator)
flutter run -d android

# Tests
flutter test test/unit/
```

## Architecture

```
lib/
├── core/
│   ├── constants.dart                    # baseUrl, StorageKeys
│   ├── di/providers.dart                 # Dio, SecureStorage, AuthInterceptor providers
│   ├── network/auth_interceptor.dart     # JWT attach + refresh + 401 queue
│   ├── providers/session_provider.dart   # userSessionProvider → current user ID string
│   ├── router/router.dart                # GoRouter setup (use ref.read NOT ref.watch)
│   ├── router/routes.dart                # Route path constants
│   ├── storage/secure_storage.dart
│   └── theme/                            # AppTheme, AppColors, AppTextStyles
├── features/
│   ├── auth/
│   │   ├── domain/user_model.dart
│   │   ├── data/auth_repository.dart     # login, register, logout, getMe
│   │   ├── providers/auth_provider.dart  # AuthNotifier (ChangeNotifier) + AuthState sealed
│   │   └── screens/                      # splash, login, register
│   ├── cards/
│   │   ├── domain/card_data.dart         # CardData, SocialLink, CardTemplate
│   │   ├── domain/card_model.dart        # CardModel (server response wrapper)
│   │   ├── data/card_repository.dart     # CRUD + public card
│   │   ├── providers/cards_provider.dart         # CardsNotifier (AsyncNotifier)
│   │   ├── providers/card_builder_provider.dart  # CardBuilderNotifier (StateNotifier.family)
│   │   └── screens/                      # home, card_builder, card_detail, issue_card, issued_cards
│   ├── contacts/
│   │   ├── domain/contact_model.dart     # ContactModel, ContactPeer, ContactPeerCard, UserSearchResult
│   │   ├── data/contact_repository.dart  # add by slug/email, list, update, accept/block/remove
│   │   ├── providers/contacts_provider.dart
│   │   └── screens/                      # contacts_screen, add_contact_screen, contact_detail_screen, pending_requests_screen
│   ├── messaging/
│   │   ├── domain/
│   │   │   ├── message_model.dart        # MessageModel (reactions, replyToId/Body/SenderId, pending/failed)
│   │   │   ├── reaction_model.dart       # ReactionModel (emoji, count, userIds, hasReacted)
│   │   │   ├── thread_model.dart         # ThreadModel
│   │   │   ├── thread_with_peer.dart     # ThreadWithPeer (thread + peerName + peerAvatarUrl)
│   │   │   ├── socket_events.dart        # typed event wrappers (ReactionUpdatedEvent, etc.)
│   │   │   └── messages_page.dart        # MessagesPage (data, nextCursor)
│   │   ├── data/
│   │   │   ├── messaging_repository.dart # REST: threads CRUD, send/edit/delete/react messages
│   │   │   └── messaging_socket.dart     # Socket.IO wrapper: connect, join, send, typing, react streams
│   │   ├── providers/
│   │   │   ├── messaging_socket_provider.dart   # singleton MessagingSocket
│   │   │   ├── messaging_repository_provider.dart
│   │   │   ├── threads_provider.dart            # ThreadsNotifier (AsyncNotifier) — thread list
│   │   │   ├── thread_messages_provider.dart    # ThreadMessagesNotifier.family(threadId) — message list
│   │   │   └── typing_provider.dart             # typingProvider.family(threadId) → Set<userId>
│   │   ├── screens/
│   │   │   ├── threads_screen.dart       # conversation list
│   │   │   └── thread_detail_screen.dart # message list + composer + options sheet
│   │   └── widgets/
│   │       ├── composer.dart             # text input + emoji picker + reply bar
│   │       ├── message_bubble.dart       # bubble with quoted reply + reaction chips
│   │       ├── thread_tile.dart
│   │       ├── typing_indicator.dart
│   │       └── start_thread_button.dart
│   ├── company/
│   ├── dashboard/
│   ├── mail/
│   ├── settings/
│   └── share/
│       └── screens/                      # public_card_screen, share_bottom_sheet
└── shared/
    ├── utils/color_utils.dart            # hexToColor, colorToHex
    ├── utils/validators.dart             # required, email, password, url, hexColor
    ├── utils/vcard.dart                  # vCard export
    └── widgets/                          # card_widget, social_chip, template_picker, etc.
```

---

## Key Design Decisions

### Router
- `routerProvider` uses `ref.read(authProvider)` — NOT `ref.watch`. Using `ref.watch` rebuilds GoRouter on every auth state change, disposing the old router's stream → "Bad state: Cannot add new events after calling close".
- Router redirect handles splash: stays on splash while `AuthInitial | AuthLoading`, redirects after auth check completes.

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

### Contacts (Bidirectional Model)
- Backend uses `requester_id` / `addressee_id` / `status` on the `contacts` table
- Backend resolves which user is the `peer` server-side (relative to the authenticated caller) — Flutter never needs to check requester vs. addressee
- `ContactModel.peerData` is always the other person; use `peer(myUserId)` accessor (just returns `peerData`)
- `ContactModel.myNotes(myUserId)` returns the note written by the current user (checks `requesterId == myUserId`)
- `UserSearchResult` returned by search includes `relationStatus` (existing contact status or null)
- Pending requests screen shows incoming (addressee = me, status = pending) vs. outgoing tabs

### Messaging — Socket + State

#### MessagingSocket (`messaging_socket.dart`)
- Wraps `socket_io_client`; `connect(token)` connects to `http://localhost:3000/messaging` with JWT in `auth.token`
- Exposes typed `Stream`s: `messageNew`, `messageUpdated`, `messageDeleted`, `readUpdated`, `typingStart`, `typingStop`, `reactionUpdated`
- `_activeThreads: Set<String>` — tracks joined rooms; flushed on `onConnect` to handle reconnection race: `joinThread()` called before socket ready no-ops; `onConnect` re-joins all active threads
- `disconnect()` clears `_activeThreads`

#### ThreadMessagesNotifier (`thread_messages_provider.dart`)
- `AsyncNotifier.family(threadId)` — owns the message list for one thread
- Subscribes to all socket streams in `build()`; cancels subscriptions in disposal
- `sendMessage(body, {replyToId, replyToMessage})`: optimistic insert (pending=true, nonce), then REST POST, then replace by nonce; on error marks message as failed
- Optimistic message includes denormalized `replyToBody`/`replyToSenderId` from the local `replyToMessage` arg so quote renders immediately without waiting for server
- `addReaction(messageId, emoji)` / `removeReaction(messageId, emoji)`: REST call; `reactionUpdated` WS event triggers local state update
- `reactionUpdated` stream subscription patches reactions list in-place by `message_id`

#### ThreadsNotifier (`threads_provider.dart`)
- Subscribes to `messageNew` to bump `last_message_at` and reorder thread list

#### Typing (`typing_provider.dart`)
- `typingProvider.family(threadId)` → `AsyncNotifier<Set<String>>`
- Subscribes to `typingStart`/`typingStop`; auto-clears userId after 3s timeout

### Messaging — UI Patterns

#### MessageBubble
- `onLongPress` → mobile long-press menu
- `onSecondaryTap` → web right-click menu (same callback)
- Shows `_QuotedReply` block if `message.replyToId != null`
- Shows `_ReactionChip` row below bubble if `reactions` non-empty; highlighted if `currentUserId` in `reaction.userIds`

#### Composer
- `replyTo: MessageModel?` → dismissable quoted bar above input row
- Emoji toggle button: `Icons.emoji_emotions_outlined` / `Icons.keyboard` → shows 250px `EmojiPicker` panel
- **emoji_picker_flutter v4**: `textEditingController` auto-inserts selected emoji. `onEmojiSelected` must NOT also insert manually → double emoji. Use: `onEmojiSelected: (_, __) => setState(() {})`

#### Thread Detail Options Sheet
Long-press or right-click opens bottom sheet with:
- Quick-react row: 6 emojis (`👍 ❤️ 😂 😮 😢 🔥`), highlighted if already reacted
- Reply → sets `_replyTo` state → dismissable bar in `Composer`
- Edit → `AlertDialog` with pre-filled text (sender only, non-deleted)
- Forward → thread picker bottom sheet, skips current thread, calls `sendMessage` on target thread
- Copy → `Clipboard.setData`
- Delete → soft delete via REST (sender only)

### Appearance
- 3 card templates: `minimal`, `bold`, `glass` — rendered in `CardWidget`
- Accent color: hex string in `CardData.accentColor`, picker via `flutter_colorpicker`
- Import `flutter_colorpicker` with `hide colorToHex` to avoid conflict with `color_utils.dart`

---

## API Endpoints (NestJS backend)

### Auth & Users
| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Register → `{access_token, refresh_token, user}` |
| POST | `/auth/login` | Login → `{access_token, refresh_token, user}` |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/refresh` | Refresh tokens (Bearer refresh_token) |
| GET | `/users/me` | Current user |
| PATCH | `/users/me` | Update name/email/password |

### Cards
| Method | Path | Description |
|--------|------|-------------|
| GET | `/cards` | All cards for user |
| POST | `/cards` | Create card |
| PATCH | `/cards/:id` | Update card |
| DELETE | `/cards/:id` | Delete card |
| GET | `/public/:slug` | Public card (no auth) |

### Contacts
| Method | Path | Description |
|--------|------|-------------|
| GET | `/contacts` | List accepted contacts |
| POST | `/contacts/scan` | Add contact by slug (QR scan) |
| POST | `/contacts/add-by-email` | Add contact by email |
| POST | `/contacts/share` | Share my card to an email |
| GET | `/contacts/pending` | Pending requests (incoming + outgoing) |
| PATCH | `/contacts/:id` | Update notes |
| POST | `/contacts/:id/accept` | Accept incoming request |
| POST | `/contacts/:id/block` | Block contact |
| DELETE | `/contacts/:id` | Remove contact |
| GET | `/contacts/search?q=` | Search users by email/name |

### Messaging (REST)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/messaging/threads` | Start or get existing thread (idempotent) |
| GET | `/messaging/threads` | List threads (sorted by `last_message_at DESC`) |
| GET | `/messaging/threads/:id` | Thread detail |
| GET | `/messaging/threads/:id/messages` | Cursor-paginated messages |
| POST | `/messaging/threads/:id/messages` | Send message (rate limited 30/min) |
| POST | `/messaging/threads/:id/read` | Update read cursor |
| GET | `/messaging/threads/:id/unread-count` | Unread count |
| PATCH | `/messaging/messages/:id` | Edit message (sender only) |
| DELETE | `/messaging/messages/:id` | Soft-delete (sender only) → 204 |
| POST | `/messaging/messages/:id/reactions` | Add emoji reaction |
| DELETE | `/messaging/messages/:id/reactions` | Remove emoji reaction → 204 |

### Messaging (WebSocket — `/messaging` namespace)
Connect: `io('http://localhost:3000/messaging', { auth: { token: '<access_token>' } })`

| Direction | Event | Payload |
|-----------|-------|---------|
| C→S | `thread:join` | `{ threadId }` → ack `{ ok }` |
| C→S | `thread:leave` | `{ threadId }` |
| C→S | `message:send` | `{ threadId, body, clientNonce? }` → ack `{ ok, message }` |
| C→S | `message:read` | `{ threadId, lastReadAt }` |
| C→S | `typing:start` | `{ threadId }` |
| C→S | `typing:stop` | `{ threadId }` |
| S→C | `message:new` | Full `SafeMessage` |
| S→C | `message:updated` | Updated `SafeMessage` |
| S→C | `message:deleted` | `{ id, thread_id }` |
| S→C | `read:updated` | `{ threadId, userId, lastReadAt }` |
| S→C | `typing:start` | `{ threadId, userId }` |
| S→C | `typing:stop` | `{ threadId, userId }` |
| S→C | `reaction:updated` | `{ message_id, reactions: ReactionSummary[] }` |

---

## Tests
```
test/unit/
├── validators_test.dart
├── color_utils_test.dart
├── card_data_test.dart
├── auth_state_test.dart
└── card_builder_notifier_test.dart
```
Run: `flutter test test/unit/` — 49 tests, no mocks needed.

---

## Known Gotchas

### Web-Specific
1. `CHROME_EXECUTABLE=/usr/bin/chromium` required (Arch Linux)
2. `baseUrl` must be `http://localhost:3000` (not `http://10.0.2.2:3000` — Android emulator address)
3. Right-click → options menu via `GestureDetector.onSecondaryTap`; long-press = mobile
4. `flutter_colorpicker` exports `colorToHex` — import with `hide colorToHex`
5. `ActionChip` has no `deleteIcon`/`onDeleted` — use `FilterChip` for deletable chips
6. `WidgetsFlutterBinding.ensureInitialized()` needed in `main()` before `runApp`
7. Router must use `ref.read` (not `ref.watch`) to avoid GoRouter stream lifecycle errors

### emoji_picker_flutter v4
- v4 **auto-inserts** emoji into `textEditingController` on selection
- `onEmojiSelected: (_, __) => setState(() {})` — do NOT manually insert emoji here
- Manually inserting again = double emoji

### Socket / Messaging
- `thread:join` emitted on connect and after reconnect (flushed from `_activeThreads`)
- `sendMessage` optimistic: insert with `pending=true` and nonce → match by nonce on WS `message:new` → replace; on REST error → `failed=true`
- Thread creation requires the peer to be an accepted contact with a registered account (403 otherwise)
- Soft-deleted message: `body` → `null` from server; `isDeleted` getter checks `deletedAt != null`; UI shows `[message deleted]`

### Backend Rebuild Required
After any TS source change in the NestJS backend:
```bash
docker compose up --build -d api
```
`docker compose restart api` reuses the old compiled image — changes won't apply.
