# Contacts Module

## Overview

One-way address book. Any user (employer or employee) can save other platform users' cards as contacts. Supports QR scan, email lookup, and bulk phone-book import. Built-in "share my card" emails your card link to a contact. Schema includes contact_user_id and last_message_at as hooks for future in-app messaging.

---

## Entity: contacts


src/contacts/entities/contact.entity.ts


| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | UUID PK | — | Auto-generated |
| owner_id | UUID FK → users.id | No | CASCADE DELETE |
| card_id | UUID FK → cards.id | Yes | SET NULL on card delete |
| card_slug | VARCHAR | Yes | Denormalized; survives card deletion |
| contact_user_id | UUID FK → users.id | Yes | SET NULL; for future messaging |
| source | ENUM | No | scan \| phone_import \| email_import |
| notes | TEXT | Yes | Owner's personal note |
| last_message_at | TIMESTAMPTZ | Yes | Messaging hook — unused in V1 |
| created_at | TIMESTAMPTZ | — | Auto |
| updated_at | TIMESTAMPTZ | — | Auto |

*Unique constraint:* (owner_id, card_id) — prevents duplicate card saves. Same person with two different cards = two valid contact entries.

*Live card reference (not snapshot).* Card data always reflects the contact's current info. If card is deleted, card_id goes NULL; card_slug is preserved as tombstone.

---

## File Structure


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


*Module imports:* TypeOrmModule.forFeature([Contact, Card, User]), MailModule

*Registered in:* src/app.module.ts → entities: [User, Card, Company, Contact] and imports: [..., ContactsModule]

---

## API Reference

All routes require Authorization: Bearer <access_token>. No role restriction — employer and employee both.

### List Contacts


GET /contacts


*Query params:*

| Param | Type | Description |
|-------|------|-------------|
| search | string | ILIKE match against card name, email, phone |
| source | scan \| phone_import \| email_import | Filter by how contact was added |
| page | integer (≥1, default 1) | Pagination |
| limit | integer (1–100, default 20) | Page size |

*Response:*

json
{
  "data": [Contact],
  "total": 42,
  "page": 1,
  "limit": 20
}


---

### Get Contact


GET /contacts/:id


Returns single Contact with card relation loaded. 404 if not found, 403 if not owner.

---

### Add via QR Scan


POST /contacts/scan


json
{
  "slug": "john-a3f2",
  "notes": "Met at Dhaka Tech Summit"  // optional
}


*Logic:*
1. Look up card by { slug, is_active: true }
2. 400 if card.user.id === ownerId (self-add)
3. 409 if (owner_id, card_id) already exists
4. Create contact with source: 'scan'

*Response:* 201 Contact

---

### Add by Email


POST /contacts/import/email


json
{
  "email": "john@example.com",
  "notes": "optional"
}


*Logic:*
1. Look up User by email — 404 if not found
2. Find their most recently updated active card — 404 if none
3. 400 if self, 409 if duplicate
4. Create contact with source: 'email_import'

*Response:* 201 Contact

---

### Bulk Phone Import


POST /contacts/import/phone


json
{
  "contacts": [
    { "name": "Alice", "email": "alice@example.com" },
    { "name": "Bob", "phone": "+8801700000001" },
    { "name": "Carol", "email": "carol@example.com", "phone": "+8801700000002" }
  ]
}


Max 500 entries per request. Unmatched entries are *skipped* (not stored) — V1 is platform users only.

*Resolution order per entry:*


1. email provided?
   → lookup User.email
   → if found: get their latest active card
   → if not found: JSONB query  cards.data->>'email' = entry.email

2. still no card + phone provided?
   → JSONB query  cards.data->>'phone' = entry.phone

3. no match → counted as not_found (skipped silently)


Runs in batches of 50 concurrently. Duplicates are skipped and counted.

*Response:*

json
{
  "matched": [Contact, ...],
  "not_found": 3,
  "skipped_duplicates": 1
}


> *Performance note:* data->>'email' and data->>'phone' are JSONB sequential scans. For production, add functional indexes:
> sql
> CREATE INDEX idx_cards_email ON cards ((data->>'email'));
> CREATE INDEX idx_cards_phone ON cards ((data->>'phone'));
> 

---

### Update Notes


PATCH /contacts/:id


json
{ "notes": "Updated note" }


Only notes is editable — the card data belongs to the other person. 403 if not owner.

*Response:* Updated Contact

---

### Delete Contact


DELETE /contacts/:id


204 No Content. 403 if not owner.

---

### Share My Card


POST /contacts/:id/share-my-card


json
{ "card_id": "uuid" }  // optional


Emails your card link to the contact's email address (taken from their card's data.email).

*Card resolution (sender):*

| Scenario | Behavior |
|----------|----------|
| card_id provided | Validates ownership, uses that card |
| card_id omitted, 1 active card | Uses it |
| card_id omitted, multiple active cards | Uses most recently updated |
| No active cards | 400 Bad Request |

*422* if contact's card has no email field.

*Response:*

json
{
  "message": "Card shared via email",
  "recipient_email": "john@example.com"
}


---

## Error Reference

| Status | When |
|--------|------|
| 400 | Self-add, no active cards to share |
| 403 | Contact belongs to different user |
| 404 | Slug/email/contact not found |
| 409 | Contact already exists (owner_id + card_id duplicate) |
| 422 | Contact card has no email — cannot share |

---

## Service Methods


ContactsService
├── addBySlug(ownerId, slug, notes?)
├── addByEmail(ownerId, email, notes?)
├── importFromPhone(ownerId, ImportPhoneContactsDto)
│   └── resolvePhoneEntry(ownerId, PhoneContactEntryDto)  [private]
├── findAll(ownerId, ContactsQueryDto)
├── findOne(id, ownerId)
├── update(id, ownerId, notes?)
├── remove(id, ownerId)
└── shareMyCard(owner: User, contactId, ShareMyCardDto)


---

## Design Decisions

*One-way relationship.* Adding Bob's card doesn't notify Bob. When messaging is added, mutuality can be enforced at the service layer (check if a contact record exists in both directions) without schema changes.

*Platform users only (V1).* Phone import silently skips entries with no matching user/card. Off-platform storage (off_platform_data JSONB) was intentionally omitted to keep V1 simple.

*Live card reference.* No snapshot. Card owner updates their number → all contacts see it immediately. The card_slug column is the safety net: if card_id goes NULL from a SET NULL cascade, the slug string is still available to show "contact removed their card."

*Messaging readiness.* contact_user_id stores the platform User ID of the contact (separate from the card FK). The last_message_at column exists but is unused. Both fields are in place so the messaging module can JOIN directly without a migration.

---

## Future Work

- *Off-platform contacts:* Add off_platform_data JSONB column and 'manual' source value. Hook into AuthService.register to auto-upgrade off-platform entries when the person registers (same pattern as linkIssuedCards).
- *Primary card flag:* Add is_primary boolean to Card entity so shareMyCard has a deterministic default instead of "most recently updated."
- *Functional indexes* on cards.data->>'email' and cards.data->>'phone' before phone import goes to production scale.
- *Messaging module:* Use contact_user_id as the target user. Update last_message_at on send/receive.