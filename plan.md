# Contacts Module — Implementation Plan

> Backend spec: `contact.md` | Backend repo: `~/Documents/digital_card`

---

## Status

| Layer | File | Status |
|-------|------|--------|
| Domain | `lib/features/contacts/domain/contact_model.dart` | ✅ Done |
| Repository | `lib/features/contacts/data/contact_repository.dart` | ✅ Done |
| Provider | `lib/features/contacts/providers/contacts_provider.dart` | ✅ Done |
| Screen — List | `lib/features/contacts/screens/contacts_screen.dart` | ✅ Done |
| Screen — Detail | `lib/features/contacts/screens/contact_detail_screen.dart` | ✅ Done |
| Screen — Add | `lib/features/contacts/screens/add_contact_screen.dart` | ✅ Done |
| Router | `lib/core/router/router.dart` + `routes.dart` | ✅ Done |

---

## Architecture

```
lib/features/contacts/
├── domain/
│   └── contact_model.dart       # ContactModel, PhoneImportResult
├── data/
│   └── contact_repository.dart  # Dio-based API calls
├── providers/
│   └── contacts_provider.dart   # ContactsNotifier + contactDetailProvider
└── screens/
    ├── contacts_screen.dart      # List + search + filters
    ├── contact_detail_screen.dart
    └── add_contact_screen.dart   # 3-tab: slug / email / phone import
```

---

## Routes

| Path | Screen |
|------|--------|
| `/contacts` | `ContactsScreen` |
| `/contacts/add` | `AddContactScreen` |
| `/contacts/detail/:id` | `ContactDetailScreen` |

Navigate: `context.push(Routes.contactDetailPath(id))`

---

## API Coverage

| Method | Endpoint | Provider method |
|--------|----------|-----------------|
| GET | `/contacts` | `ContactsNotifier.build()` / `loadMore()` / `search()` |
| GET | `/contacts/:id` | `contactDetailProvider.family` |
| POST | `/contacts/scan` | `ContactsNotifier.addBySlug()` |
| POST | `/contacts/import/email` | `ContactsNotifier.addByEmail()` |
| POST | `/contacts/import/phone` | `ContactsNotifier.importFromPhone()` |
| PATCH | `/contacts/:id` | `ContactsNotifier.updateNotes()` |
| DELETE | `/contacts/:id` | `ContactsNotifier.delete()` |
| POST | `/contacts/:id/share-my-card` | `ContactsNotifier.shareMyCard()` |

---

## State Shape

```dart
class ContactsState {
  final List<ContactModel> contacts;
  final int total;
  final int page;
  final bool isLoadingMore;
  final String? search;       // active search query
  final String? sourceFilter; // 'scan' | 'email_import' | 'phone_import' | null
  bool get hasMore => contacts.length < total;
}
```

Pagination: 20 per page. Infinite scroll triggers at 200px from bottom.

---

## Key Behaviors

### List Screen
- Search debounced 400ms → `notifier.search(query)`
- Filter chips: All / Scan / Email / Phone → `notifier.setSourceFilter(source)`
- Pull-to-refresh → `notifier.refresh()`
- Infinite scroll → `notifier.loadMore()`
- FAB → `/contacts/add`

### Detail Screen
- Loads via `contactDetailProvider(id)` (FutureProvider.family)
- If `card` is null → shows deleted-card banner with `card_slug` as tombstone
- Edit notes → bottom sheet → PATCH
- Share my card → picks sender card (bottom sheet if multiple active) → POST share-my-card
- Delete → confirm dialog → optimistic remove → `context.pop()`

### Add Screen (3 tabs)
1. **Slug** — enter slug manually (QR decode → slug), optional notes → `addBySlug()`
2. **Email** — email + optional notes → `addByEmail()`
3. **Phone Import** — multiline text (`Name, email, phone`) → parsed → `importFromPhone()` → shows result summary (matched / skipped / not_found)

---

## Error Codes

| HTTP | Message shown |
|------|---------------|
| 400 | "Cannot add yourself." |
| 403 | "Permission denied." |
| 404 | "Card or user not found." |
| 409 | "Contact already saved." |
| 422 | "Contact has no email — cannot share." |

---

## Pending / Future Work

- [ ] **QR scanner** — replace slug text field with `mobile_scanner` camera scan. Decode QR → extract slug → call `addBySlug()`. Package: `mobile_scanner` (add to `pubspec.yaml`).
- [ ] **Device contacts picker** — phone import tab: use `flutter_contacts` to read phone book instead of manual text entry.
- [ ] **Primary card flag** — once backend adds `is_primary` to Card, `shareMyCard` should auto-pick primary card instead of "most recently updated".
- [ ] **Messaging** — `contact_user_id` is stored on `ContactModel`. When messaging module lands, use it as the target user ID.
- [ ] **Off-platform contacts** — backend V2 will add `source: 'manual'` and `off_platform_data` JSONB. UI needs a manual-entry form tab.
- [ ] **Functional DB indexes** — remind backend to add before phone import goes to prod scale:
  ```sql
  CREATE INDEX idx_cards_email ON cards ((data->>'email'));
  CREATE INDEX idx_cards_phone ON cards ((data->>'phone'));
  ```

---

## Testing Checklist

```
flutter run -d chrome
```

1. Contacts tab loads → GET /contacts?page=1&limit=20
2. Search "alice" → debounced query fires
3. Filter "Scan" chip → source=scan param
4. Scroll to bottom → loadMore fires page=2
5. Add by email → 201 → contact appears at top of list
6. Add duplicate → 409 → "Contact already saved." snackbar
7. Add self → 400 → "Cannot add yourself." snackbar
8. Tap contact → detail screen renders CardWidget
9. Edit notes → PATCH fires → updated notes shown
10. Share my card (single active card) → email sent → success snackbar
11. Share my card (multiple cards) → card picker shows
12. Delete → confirm → 204 → pops back, contact gone from list
13. Phone import → paste 3 entries → result summary shows matched/skipped/not_found
14. `flutter test test/unit/` → 49 tests pass
```
