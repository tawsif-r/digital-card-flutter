# Contacts Module

## Overview

One-way address book. Any user (employer or employee) can save other platform users' cards as contacts. Supports QR scan, email lookup, and bulk phone-book import. Built-in "share my card" emails your card link to a contact.

**Ownership model:** Contacts use `owner_email` (not `owner_id`) as the primary owner identifier for scan and email-import flows. Phone-import uses `owner_id`. The entity carries both columns.

---

## Entity: `contacts`

```
src/contacts/entities/contact.entity.ts
```

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | UUID PK | — | Auto-generated |
| `owner_id` | UUID FK → `users.id` | Yes | Used by phone_import; CASCADE DELETE |
| `owner_email` | VARCHAR | Yes | Used by scan + email_import flows |
| `card_id` | UUID FK → `cards.id` | Yes | SET NULL on card delete |
| `card_slug` | VARCHAR | Yes | Denormalized; survives card deletion |
| `contact_user_id` | UUID FK → `users.id` | Yes | SET NULL; for future messaging |
| `source` | ENUM | No | `scan \| phone_import \| email_import` |
| `notes` | TEXT | Yes | Owner's personal note |
| `last_message_at` | TIMESTAMPTZ | Yes | Messaging hook — unused in V1 |
| `created_at` | TIMESTAMPTZ | — | Auto |
| `updated_at` | TIMESTAMPTZ | — | Auto |

**Unique constraint:** `(owner_id, card_id)` — prevents duplicate saves for phone_import. Scan/email-import dedup via `owner_email + card_id` query before insert.

---

## File Structure

```
src/contacts/
├── contacts.module.ts
├── contacts.controller.ts
├── contacts.service.ts
├── entities/
│   └── contact.entity.ts
└── dto/
    ├── add-contact-by-slug.dto.ts
    ├── import-phone-contacts.dto.ts
    ├── import-email-contact.dto.ts
    ├── share-my-card.dto.ts
    ├── update-contact.dto.ts
    └── contacts-query.dto.ts
```

**Module imports:** `TypeOrmModule.forFeature([Contact, Card, User])`, `MailModule`

---

## API Reference

All routes require `Authorization: Bearer <access_token>`. No role restriction.

### List Contacts

```
GET /contacts
```

**Query params:**

| Param | Type | Description |
|-------|------|-------------|
| `search` | string | ILIKE match against card `name`, `email`, `phone` (JSONB) |
| `source` | `scan \| phone_import \| email_import` | Filter by source |
| `page` | integer (≥1, default 1) | Pagination |
| `limit` | integer (1–100, default 20) | Page size |

**Response:**

```json
{
  "data": [Contact],
  "total": 42,
  "page": 1,
  "limit": 20
}
```

> **Note:** `findAll` filters by `owner_id`. Contacts created via scan/email-import (using `owner_email`) will not appear in this list unless they also have `owner_id` set. This is a known inconsistency to address.

---

### Get Contact

```
GET /contacts/:id
```

Returns single `Contact` with `card` relation loaded. 403 ownership check uses `owner_id`.

---

### Add via QR Scan

```
POST /contacts/scan
```

```json
{
  "slug": "john-a3f2",
  "notes": "Met at Dhaka Tech Summit"
}
```

**Logic:**
1. Find card by `{ slug, is_active: true }`
2. 400 if `card.email === ownerEmail` (self-add check — email based, not ID)
3. 409 if contact with `{ card_id }` already exists
4. Create contact with `owner_email`, `source: 'scan'`

**Response:** 201 `Contact`

---

### Add by Email

```
POST /contacts/import/email
```

```json
{
  "email": "john@example.com",
  "notes": "optional"
}
```

**Logic:**
1. Find `User` by email — 404 if not found
2. Find their most recently updated active card (matched by `card.email`) — 404 if none
3. 409 if `{ owner_email, card_id }` duplicate
4. Create contact with `owner_email`, `source: 'email_import'`

**Response:** 201 `Contact`

---

### Bulk Phone Import

```
POST /contacts/import/phone
```

```json
{
  "contacts": [
    { "name": "Alice", "email": "alice@example.com" },
    { "name": "Bob", "phone": "+8801700000001" },
    { "name": "Carol", "email": "carol@example.com", "phone": "+8801700000002" }
  ]
}
```

Max 500 entries. Unmatched entries silently skipped.

**Resolution order per entry:**
```
1. email provided?
   → lookup User.email → get their latest active card (by user id)
   → if not found: JSONB query  cards.data->>'email' = entry.email

2. still no card + phone provided?
   → JSONB query  cards.data->>'phone' = entry.phone

3. no match → not_found (skipped)
```

Runs in batches of 50. Uses `owner_id` (not `owner_email`). Duplicates are skipped.

**Response:**

```json
{
  "matched": [Contact],
  "not_found": 3,
  "skipped_duplicates": 1
}
```

---

### Update Notes

```
PATCH /contacts/:id
```

```json
{ "notes": "Updated note" }
```

**Response:** Updated `Contact`

---

### Delete Contact

```
DELETE /contacts/:id
```

204 No Content.

---

### Share My Card

```
POST /contacts/:id/share-my-card
```

```json
{ "card_id": "uuid" }
```

Emails your card link to contact's `card.data.email`.

| Scenario | Behavior |
|----------|----------|
| `card_id` provided | Validates ownership, uses that card |
| `card_id` omitted | Uses most recently updated active card |
| No active cards | 400 Bad Request |

422 if contact's card has no `email` field.

**Response:**
```json
{
  "message": "Card shared via email",
  "recipient_email": "john@example.com"
}
```

---

## Error Reference

| Status | When |
|--------|------|
| 400 | Self-add (`card.email === ownerEmail`), no active cards to share |
| 403 | Contact belongs to different user |
| 404 | Slug/email/contact/card not found |
| 409 | Duplicate contact |
| 422 | Contact's card has no email |

---

## Service Methods (actual signatures)

```
ContactsService
├── addBySlug(ownerEmail: string, slug: string, notes?)          → Contact
├── addByEmail(ownerEmail: string, email: string, notes?)        → Contact
├── importFromPhone(ownerId: string, dto: ImportPhoneContactsDto) → { matched, not_found, skipped_duplicates }
│   └── resolvePhoneEntry(ownerId, entry)  [private]
├── findAll(ownerId: string, query: ContactsQueryDto)            → paginated
├── findOne(id: string, ownerId: string)                         → Contact
├── update(id: string, ownerId: string, notes?)                  → Contact
├── remove(id: string, ownerId: string)                          → void
└── shareMyCard(owner: User, contactId: string, dto)             → { message, recipient_email }
```

**Controller passes:**
- `scan` → `user.email` as ownerEmail
- `import/email` → `user.email` as ownerEmail
- `import/phone` → `user.id` as ownerId
- `findAll`, `findOne`, `update`, `remove`, `shareMyCard` → `user.id` as ownerId

---

## Known Issues

1. **findAll uses owner_id** — contacts created via scan/email-import store `owner_email` only, so they won't appear in list queries that filter by `owner_id`.
2. **Unique constraint mismatch** — DB constraint is `(owner_id, card_id)` but scan/email-import dedup checks `owner_email + card_id` in application code.
3. **shareMyCard ownership check uses owner_id** — will 403 for contacts saved with only `owner_email`.

# Messaging Module

## Overview

Discord-style 1-on-1 DM threading between contacts. Each thread is a conversation between exactly two registered users. Users can only open threads with contacts who have a registered account (`contact_user_id IS NOT NULL` on the Contact row). Messages are persistent (PostgreSQL), real-time delivery via Socket.IO.

**Design decisions:**
- Thread uniqueness enforced by storing participants in canonical (sorted) UUID order: `user_a_id < user_b_id` lexicographically. Prevents duplicate threads for the same pair.
- No Redis — single-node Socket.IO, in-process rooms.
- Soft delete on messages — `deleted_at` set, body returned as `null` to clients. No hard data loss.
- Read receipts via per-user timestamp cursors on the Thread row (not a separate table).
- `last_message_at` on the Contact entity (reserved in V1) is updated on every send — drives contact list sort order on the frontend.

---

## Entities

### `threads`

```
src/messaging/entities/thread.entity.ts
```

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | UUID PK | — | Auto-generated |
| `user_a_id` | UUID FK → `users.id` | No | Lexicographically smaller UUID; CASCADE DELETE |
| `user_b_id` | UUID FK → `users.id` | No | Lexicographically larger UUID; CASCADE DELETE |
| `last_message_at` | TIMESTAMPTZ | Yes | Bumped on every send; drives thread list sort |
| `last_message_id` | UUID | Yes | Denormalized for fast thread-list preview |
| `user_a_last_read_at` | TIMESTAMPTZ | Yes | Read cursor for `user_a` |
| `user_b_last_read_at` | TIMESTAMPTZ | Yes | Read cursor for `user_b` |
| `created_at` | TIMESTAMPTZ | — | Auto |
| `updated_at` | TIMESTAMPTZ | — | Auto |

**Unique constraint:** `(user_a_id, user_b_id)` — one thread per pair.

**Indexes:**
- `(user_a_id, last_message_at)` — thread list query for user_a
- `(user_b_id, last_message_at)` — thread list query for user_b

---

### `messages`

```
src/messaging/entities/message.entity.ts
```

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | UUID PK | — | Auto-generated |
| `thread_id` | UUID FK → `threads.id` | No | CASCADE DELETE |
| `sender_id` | UUID FK → `users.id` | No | CASCADE DELETE |
| `body` | TEXT | No | 1–4000 chars; DB stores original even after delete |
| `edited_at` | TIMESTAMPTZ | Yes | Set on edit; null if never edited |
| `deleted_at` | TIMESTAMPTZ | Yes | Soft delete; body returned as `null` when set |
| `created_at` | TIMESTAMPTZ | — | Pagination cursor (ISO timestamp + `id` as tiebreak) |
| `updated_at` | TIMESTAMPTZ | — | Auto |

**Indexes:**
- `(thread_id, created_at)` — message history pagination
- `(sender_id)` — unread count queries

---

## File Structure

```
src/messaging/
├── messaging.module.ts
├── messaging.controller.ts
├── messaging.service.ts
├── messaging.gateway.ts         # Socket.IO WebSocket gateway
├── messaging.service.spec.ts
├── entities/
│   ├── thread.entity.ts
│   └── message.entity.ts
└── dto/
    ├── create-thread.dto.ts     # { contactId?, userId? }
    ├── send-message.dto.ts      # { body, clientNonce? }
    ├── update-message.dto.ts    # { body }
    ├── messages-query.dto.ts    # { cursor?, limit?, direction? }
    ├── threads-query.dto.ts     # { page?, limit? }
    └── mark-read.dto.ts         # { lastReadAt? }
```

**Module imports:** `TypeOrmModule.forFeature([Thread, Message, Contact, User])`, `UsersModule`, `JwtModule`

---

## REST API

All routes require `Authorization: Bearer <access_token>`.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/messaging/threads` | Start or get existing thread (idempotent) |
| `GET` | `/messaging/threads` | List threads sorted by `last_message_at DESC` |
| `GET` | `/messaging/threads/:threadId` | Get thread detail |
| `GET` | `/messaging/threads/:threadId/messages` | Cursor-paginated message history |
| `POST` | `/messaging/threads/:threadId/messages` | Send message (rate limited: 30/min) |
| `POST` | `/messaging/threads/:threadId/read` | Update read cursor |
| `GET` | `/messaging/threads/:threadId/unread-count` | Count unread messages |
| `PATCH` | `/messaging/messages/:messageId` | Edit message (sender only) |
| `DELETE` | `/messaging/messages/:messageId` | Soft-delete message (sender only) → 204 |

---

## WebSocket Gateway

**Namespace:** `/messaging`  
**Transport:** Socket.IO  
**Auth:** JWT passed on handshake:

```js
const socket = io('http://localhost:3000/messaging', {
  auth: { token: '<access_token>' }
});
// OR via header: Authorization: Bearer <token>
```

Token verified in `handleConnection`. Invalid/missing token → `socket.disconnect(true)`.

### Rooms

| Room | Who joins | When |
|------|-----------|------|
| `user:<userId>` | Socket owner | On connect (auto) |
| `thread:<threadId>` | Participants | On `thread:join` event (validated) |

### Client → Server events

| Event | Payload | Description |
|-------|---------|-------------|
| `thread:join` | `{ threadId }` | Join thread room. Participant check enforced. Returns ack `{ ok }`. |
| `thread:leave` | `{ threadId }` | Leave thread room. |
| `message:send` | `{ threadId, body, clientNonce? }` | Persist + broadcast. Returns ack `{ ok, message }`. Rate limited: 20/10s per user (in-gateway token bucket). |
| `message:read` | `{ threadId, lastReadAt }` | Update read cursor + broadcast `read:updated` to room. |
| `typing:start` | `{ threadId }` | Relay to other room members. |
| `typing:stop` | `{ threadId }` | Relay to other room members. |

### Server → Client events

| Event | Target | Payload |
|-------|--------|---------|
| `message:new` | `thread:<threadId>` | Full message DTO |
| `message:updated` | `thread:<threadId>` | Updated message DTO |
| `message:deleted` | `thread:<threadId>` | `{ id, thread_id }` |
| `read:updated` | `thread:<threadId>` | `{ threadId, userId, lastReadAt }` |
| `typing:start` | `thread:<threadId>` | `{ threadId, userId }` |
| `typing:stop` | `thread:<threadId>` | `{ threadId, userId }` |
| `thread:bumped` | `user:<userId>` | `{ threadId, last_message_at, unread_count }` — for thread-list refresh when not in room |

---

## Key Service Logic

### `createOrGetThread(currentUserId, dto)`

```
1. contactId provided?
   → load Contact, assert owner_id === currentUserId
   → assert contact_user_id IS NOT NULL (400 otherwise)
   → peerId = contact.contact_user_id

   userId provided?
   → check Contact row where (owner_id = currentUserId AND contact_user_id = userId)
   → 403 if not found

2. peerId === currentUserId → 400 (self-message)

3. [user_a_id, user_b_id] = [currentUserId, peerId].sort()

4. findOne({ user_a_id, user_b_id })
   → return existing OR create
   → catch unique-violation race → re-fetch
```

### `sendMessage(threadId, senderId, dto)` — runs in a transaction

```
1. assertParticipant(thread, senderId)
2. INSERT message
3. UPDATE threads SET last_message_at, last_message_id WHERE id = threadId
4. UPDATE contacts SET last_message_at = now
   WHERE (owner_id = senderId AND contact_user_id = peerId)
      OR (owner_id = peerId AND contact_user_id = senderId)
5. After commit: broadcast message:new + thread:bumped
```

### `assertParticipant(thread, userId)`

```
if (thread.user_a_id !== userId && thread.user_b_id !== userId)
  throw ForbiddenException
```

### Read cursor

Thread has two columns: `user_a_last_read_at` and `user_b_last_read_at`.  
`markRead` updates the correct one based on whether caller is `user_a` or `user_b`.  
`getUnreadCount` counts messages from the peer with `created_at > caller's last_read_at`.  
`lastReadAt` is clamped to `now` — cannot be set in the future.

---

## Security

| Concern | Mitigation |
|---------|-----------|
| WS auth | JWT verified on every `handleConnection`; disconnect on failure |
| Room access | Participant check re-run on every `thread:join` |
| Message authorship | `sender_id === userId` check before edit/delete |
| Contact gate | Thread creation blocked unless peer is in caller's contacts with registered account |
| REST participant check | `assertParticipant` called on every thread-scoped operation |
| REST rate limit | `@Throttle({ limit: 30, ttl: 60000 })` on POST messages |
| WS rate limit | In-gateway token bucket: 20 sends / 10s per `userId` (Map in process memory) |
| Body validation | 1–4000 chars, trimmed, whitespace-only rejected |
| Soft delete | `deleted_at` set; body redacted in responses — no data loss for audit |
| Self-message | Rejected in `createOrGetThread` |

---

## Service Methods (actual signatures)

```
MessagingService
├── createOrGetThread(currentUserId: string, dto: CreateThreadDto)         → Thread
├── listThreads(userId: string, query: ThreadsQueryDto)                    → { data, total, page, limit }
├── getThread(threadId: string, userId: string)                            → Thread
├── getMessages(threadId: string, userId: string, query: MessagesQueryDto) → { data: SafeMessage[], nextCursor }
├── sendMessage(threadId: string, senderId: string, dto: SendMessageDto)   → SafeMessage
├── editMessage(messageId: string, userId: string, dto: UpdateMessageDto)  → SafeMessage
├── deleteMessage(messageId: string, userId: string)                       → { id, thread_id }
├── markRead(threadId: string, userId: string, dto: MarkReadDto)           → { lastReadAt }
├── getUnreadCount(threadId: string, userId: string)                       → { count }
└── getUnreadCountForThread(thread: Thread, userId: string)  [private]     → number
```

`SafeMessage` — body is `null` when `deleted_at` is set.

---

## Error Reference

| Status | When |
|--------|------|
| 400 | Empty/whitespace body, self-message, contact has no registered account, missing contactId/userId |
| 403 | Not a thread participant, not the message sender, peer not in contacts |
| 404 | Thread or message not found, contact not found |
| 429 | REST rate limit exceeded (30/min on POST messages) |


# Architecture Document — Digital Card

## System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter App                                │
│  ┌──────────┐  ┌──────────────┐  ┌──────────┐  ┌─────────────┐  │
│  │   Auth   │  │ Card Builder │  │ Contacts │  │  Messaging  │  │
│  └────┬─────┘  └──────┬───────┘  └────┬─────┘  └──────┬──────┘  │
│       └───────────────┴───────────────┴───────────────┘         │
│               Dio HTTP Client (JWT interceptor, retry)           │
│               socket.io-client (JWT handshake)                   │
└──────────────────────────────┬───────────────────────────────────┘
                               │ HTTPS + WSS
┌──────────────────────────────▼───────────────────────────────────┐
│                        NestJS Backend                             │
│  ┌──────┐ ┌───────┐ ┌───────┐ ┌─────────┐ ┌──────────┐ ┌─────┐  │
│  │ Auth │ │ Users │ │ Cards │ │ Company │ │ Contacts │ │ Msg │  │
│  └──┬───┘ └───┬───┘ └───┬───┘ └────┬────┘ └────┬─────┘ └──┬──┘  │
│     └─────────┴─────────┴──────────┴────────────┴──────────┘    │
│                          TypeORM                                  │
│              Socket.IO Gateway (/messaging namespace)            │
└──────────────────────────────┬───────────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────────┐
│                   PostgreSQL (Docker)                             │
│  tables: users, cards, companies, contacts, threads, messages    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Backend — NestJS

### Module Structure

```
src/
├── main.ts                       # bootstrap, IoAdapter, global pipes, swagger
├── app.module.ts
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts        # POST /auth/register, /login, /refresh, /logout
│   ├── auth.service.ts
│   ├── strategies/
│   │   ├── jwt.strategy.ts
│   │   └── jwt-refresh.strategy.ts
│   └── dto/
│       ├── register.dto.ts
│       └── login.dto.ts
├── users/
│   ├── users.module.ts
│   ├── users.controller.ts       # GET/PATCH /users/me
│   ├── users.service.ts
│   ├── entities/
│   │   └── user.entity.ts
│   └── dto/
│       └── update-user.dto.ts    # name, email, current_password, new_password
├── cards/
│   ├── cards.module.ts
│   ├── cards.controller.ts       # CRUD /cards, issued card flows, GET /public/:slug
│   ├── cards.service.ts
│   ├── entities/
│   │   └── card.entity.ts
│   └── dto/
│       ├── create-card.dto.ts
│       └── update-card.dto.ts
├── company/
│   ├── company.module.ts
│   ├── company.controller.ts     # POST /company/onboard, GET /company/me
│   ├── company.service.ts
│   └── entities/
│       └── company.entity.ts
├── contacts/
│   ├── contacts.module.ts
│   ├── contacts.controller.ts    # scan, email import, phone import, share
│   ├── contacts.service.ts
│   ├── entities/
│   │   └── contact.entity.ts
│   └── dto/
│       ├── add-contact-by-slug.dto.ts
│       ├── import-email-contact.dto.ts
│       ├── import-phone-contacts.dto.ts
│       ├── share-my-card.dto.ts
│       ├── update-contact.dto.ts
│       └── contacts-query.dto.ts
├── messaging/
│   ├── messaging.module.ts
│   ├── messaging.controller.ts   # REST /messaging/threads, /messaging/messages
│   ├── messaging.service.ts
│   ├── messaging.gateway.ts      # Socket.IO /messaging namespace
│   ├── entities/
│   │   ├── thread.entity.ts
│   │   └── message.entity.ts
│   └── dto/
│       ├── create-thread.dto.ts
│       ├── send-message.dto.ts
│       ├── update-message.dto.ts
│       ├── messages-query.dto.ts
│       ├── threads-query.dto.ts
│       └── mark-read.dto.ts
├── mail/
│   └── mail.module.ts            # nodemailer wrapper, used by contacts + auth
└── common/
    ├── guards/
    │   ├── jwt-auth.guard.ts
    │   └── roles.guard.ts
    ├── decorators/
    │   ├── current-user.decorator.ts
    │   └── roles.decorator.ts
    ├── enums/
    │   └── user-role.enum.ts     # EMPLOYER | EMPLOYEE
    └── filters/
        └── http-exception.filter.ts
```

---

## Authentication Flow

```
Register:
  Client → POST /auth/register { email, password, name }
         ← 201 { access_token, refresh_token, user }

Login:
  Client → POST /auth/login { email, password }
         ← 200 { access_token, refresh_token, user }

Authenticated REST request:
  Client → GET /users/me  [Authorization: Bearer <access_token>]
         ← 200 { user }

Token refresh:
  Client → POST /auth/refresh  [Authorization: Bearer <refresh_token>]
         ← 200 { access_token, refresh_token, user }

Logout:
  Client → POST /auth/logout  [Authorization: Bearer <access_token>]
         ← 204

WebSocket connect:
  Client → io('/messaging', { auth: { token: '<access_token>' } })
         ← connected (or disconnect if token invalid)
```

**JWT config:**
- Access token: 15 min, signed with `JWT_SECRET`
- Refresh token: 7 days, signed with `JWT_REFRESH_SECRET`
- Passwords: bcrypt cost 12
- Refresh tokens stored as bcrypt hash in DB — revocable on logout

---

## Database Entities

### `users`

```typescript
@Entity()
class User {
  id: UUID (PK)
  email: string (unique)
  password_hash: string
  name: string | null
  role: 'employer' | 'employee'
  company_id: UUID | null (FK → companies)
  refresh_token_hash: string | null
  created_at, updated_at: Date
  // relations: cards[]
}
```

### `cards`

```typescript
@Entity()
class Card {
  id: UUID (PK)
  user_id: UUID (FK → users, CASCADE)
  email: string | null               // denormalized for contact lookup
  slug: string (unique)
  data: JSONB (CardData)
  is_active: boolean
  company_id: UUID | null (FK → companies)
  issued_by_id: UUID | null (FK → users)
  issued_to_id: UUID | null (FK → users)
  issued_to_email: string | null
  acknowledged_at: Date | null
  created_at, updated_at: Date
}
```

`CardData` interface: `{ name, title?, company?, phone?, email?, website?, socials?, photo_url?, template, accent_color }`

### `companies`

```typescript
@Entity()
class Company {
  id: UUID (PK)
  name: string
  description: string
  size: number
  owner_id: UUID (FK → users)
  created_at, updated_at: Date
}
```

### `contacts`

```typescript
@Entity()
class Contact {
  id: UUID (PK)
  owner_id: UUID | null (FK → users, CASCADE)    // used by phone_import
  owner_email: string | null                     // used by scan + email_import
  card_id: UUID | null (FK → cards, SET NULL)
  card_slug: string | null                       // denormalized; survives card delete
  contact_user_id: UUID | null (FK → users)      // messaging hook
  source: 'scan' | 'phone_import' | 'email_import'
  notes: string | null
  last_message_at: Date | null                   // updated by messaging module on send
  created_at, updated_at: Date
  // unique constraint: (owner_id, card_id)
}
```

### `threads`

```typescript
@Entity()
class Thread {
  id: UUID (PK)
  user_a_id: UUID (FK → users, CASCADE)   // lexicographically smaller UUID
  user_b_id: UUID (FK → users, CASCADE)   // lexicographically larger UUID
  last_message_at: Date | null
  last_message_id: UUID | null
  user_a_last_read_at: Date | null        // read cursor
  user_b_last_read_at: Date | null        // read cursor
  created_at, updated_at: Date
  // unique constraint: (user_a_id, user_b_id)
}
```

### `messages`

```typescript
@Entity()
class Message {
  id: UUID (PK)
  thread_id: UUID (FK → threads, CASCADE)
  sender_id: UUID (FK → users, CASCADE)
  body: string                           // stored even after soft delete
  edited_at: Date | null
  deleted_at: Date | null                // soft delete; body returned null when set
  created_at, updated_at: Date
}
```

---

## Real-time — Socket.IO

**Adapter:** `IoAdapter` from `@nestjs/platform-socket.io`. Single-node, no Redis.

**Namespace:** `/messaging`

**Auth:** JWT verified in `handleConnection` → disconnect on failure.

**Rooms:**
- `user:<userId>` — joined on connect; receives thread-list bumps
- `thread:<threadId>` — joined via `thread:join` event; receives message events

See `messaging-module.md` for full event reference.

---

## Slug Generation

```
slug = sanitize(email_username) + "-" + nanoid(4)
e.g.  john-a3f2
```

Collision retry up to 5×.

---

## Rate Limiting

| Scope | Limit | Applied via |
|-------|-------|-------------|
| Global | 60 req/min | `ThrottlerModule` global |
| Auth endpoints | 10 req/min | `@Throttle` on auth controller |
| POST messages (REST) | 30 req/min | `@Throttle` on controller method |
| WS message:send | 20 / 10s per user | In-gateway token bucket (process memory) |

---

## Environment Variables

```env
DATABASE_URL=postgresql://user:pass@localhost:5433/digital_card
JWT_SECRET=change_me_in_production
JWT_REFRESH_SECRET=change_me_in_production_refresh
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
PORT=3000
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USER=noreply@example.com
MAIL_PASS=secret
MAIL_FROM="Digital Card <noreply@example.com>"
APP_URL=http://localhost:3000
```

---

## Docker Compose (dev)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: digital_card
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
    ports:
      - '5433:5432'
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

Single container. No Redis needed (single-node Socket.IO).

---

## Error Response Format

All HTTP errors:

```json
{
  "statusCode": 400,
  "timestamp": "2026-05-10T12:00:00.000Z",
  "path": "/users/me",
  "message": "string | string[]"
}
```

Validation errors return `message` as array.

---

## Security Considerations

- Passwords: bcrypt cost 12, never stored plain
- Refresh tokens: stored as bcrypt hash in DB, revocable on logout
- All authenticated routes behind `JwtAuthGuard`
- Role-based access (`RolesGuard`) on EMPLOYER-only endpoints
- `/public/:slug` intentionally unauthenticated — read-only card data
- Rate limiting on auth, message send endpoints
- Input validation via `class-validator` DTOs on all endpoints
- WebSocket: JWT validated on connect; participant check on every room join and message operation
- Messaging contact gate: thread creation requires peer to be in caller's contacts with registered account
- Soft delete for messages: audit trail preserved, body redacted in API responses
- CORS: restrict to app origin in production

---

## Module Dependency Graph

```
AppModule
├── AuthModule        → UsersModule, CardsModule, JwtModule, PassportModule
├── UsersModule       (exports UsersService)
├── CardsModule       → UsersModule
├── CompanyModule     → UsersModule
├── ContactsModule    → MailModule, TypeORM[Contact, Card, User]
├── MessagingModule   → UsersModule, JwtModule, TypeORM[Thread, Message, Contact, User]
└── MailModule
```