# Digital Card — API Schema & Task Breakdown

## Feature Flag

```dart
// lib/core/services/app_config.dart
AppConfig.useMock = true   // mock active
AppConfig.useMock = false  // hits real backend
```

---

## API Schema

All endpoints require:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

All responses follow:
```json
{ "success": true, "data": <payload> }
{ "success": false, "message": "<error string>" }
```

---

### Activity

#### GET `/api/activity`

Request:
```
Headers: { Authorization: Bearer <token> }
```

Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "a1",
      "type": "message",
      "title": "New message from Alice Chen",
      "description": "Hey, loved your digital card! Can we connect?",
      "timestamp": "2026-05-05T08:00:00.000Z"
    },
    {
      "id": "a2",
      "type": "meeting",
      "title": "Meeting scheduled",
      "description": "Product Team Sync · Tomorrow 10:00 AM",
      "timestamp": "2026-05-05T07:00:00.000Z"
    }
  ]
}
```

`type` enum: `message | meeting | connection | view | task`

---

### Tasks

#### GET `/api/tasks`

Request:
```
Headers: { Authorization: Bearer <token> }
Query:   ?status=pending&priority=high   (optional filters)
```

Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "t1",
      "title": "Review Q4 marketing materials",
      "description": "Go through deck and provide feedback",
      "status": "pending",
      "priority": "high",
      "due_date": "2026-05-07T00:00:00.000Z",
      "created_at": "2026-05-04T00:00:00.000Z"
    }
  ]
}
```

`status` enum: `pending | inProgress | completed`  
`priority` enum: `low | medium | high`  
`description` nullable  
`due_date` nullable  

---

#### GET `/api/tasks/count`

Request:
```
Headers: { Authorization: Bearer <token> }
```

Response:
```json
{
  "success": true,
  "data": {
    "pending": 4,
    "inProgress": 1,
    "completed": 2,
    "total": 7
  }
}
```

---

#### POST `/api/tasks`

Request:
```json
{
  "title": "Prepare client demo",
  "description": "Showcase new networking features",
  "status": "pending",
  "priority": "high",
  "due_date": "2026-05-10T00:00:00.000Z"
}
```

Validation:
- `title` — required, string, max 255
- `description` — optional, string
- `status` — required, enum
- `priority` — required, enum
- `due_date` — optional, ISO 8601

Response `201`:
```json
{
  "success": true,
  "data": {
    "id": "t6",
    "title": "Prepare client demo",
    "description": "Showcase new networking features",
    "status": "pending",
    "priority": "high",
    "due_date": "2026-05-10T00:00:00.000Z",
    "created_at": "2026-05-05T10:00:00.000Z"
  }
}
```

---

#### PATCH `/api/tasks/:id`

Request:
```
Params: id — task ID (string)
```
```json
{
  "title": "Prepare client demo (updated)",
  "status": "inProgress",
  "priority": "medium",
  "due_date": null
}
```

All fields optional (partial update).

Response `200`:
```json
{
  "success": true,
  "data": {
    "id": "t6",
    "title": "Prepare client demo (updated)",
    "description": "Showcase new networking features",
    "status": "inProgress",
    "priority": "medium",
    "due_date": null,
    "created_at": "2026-05-05T10:00:00.000Z"
  }
}
```

---

#### DELETE `/api/tasks/:id`

Request:
```
Params: id — task ID (string)
```

Response `200`:
```json
{
  "success": true,
  "data": null
}
```

Error `404`:
```json
{
  "success": false,
  "message": "Task not found."
}
```

---

### User Profile

#### GET `/api/user/profile`

Request:
```
Headers: { Authorization: Bearer <token> }
```

Response:
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "email": "john.doe@digitalcard.io",
    "fullName": "John Doe",
    "phone": "+880 1234-567890",
    "designation": "Software Engineer",
    "department": "Engineering",
    "company": "DigitalCard Inc"
  }
}
```

All fields except `id` and `email` are nullable.

---

#### PUT `/api/user/profile`

Request:
```json
{
  "fullName": "John Doe",
  "phone": "+880 1234-567890",
  "designation": "Software Engineer",
  "department": "Engineering",
  "company": "DigitalCard Inc"
}
```

Validation:
- `fullName` — required, string, max 100
- `phone` — optional, string, max 30
- `designation` — optional, string, max 100
- `department` — optional, string, max 100
- `company` — optional, string, max 150

Response `200`:
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "email": "john.doe@digitalcard.io",
    "fullName": "John Doe",
    "phone": "+880 1234-567890",
    "designation": "Software Engineer",
    "department": "Engineering",
    "company": "DigitalCard Inc"
  }
}
```

---

### User Settings

#### GET `/api/user/settings`

Request:
```
Headers: { Authorization: Bearer <token> }
```

Response:
```json
{
  "success": true,
  "data": {
    "showOnlineStatus": true,
    "allowAudioCalls": true,
    "allowVideoCalls": false
  }
}
```

---

#### PUT `/api/user/settings`

Request:
```json
{
  "showOnlineStatus": true,
  "allowAudioCalls": true,
  "allowVideoCalls": false
}
```

Validation:
- `showOnlineStatus` — required, boolean
- `allowAudioCalls` — required, boolean
- `allowVideoCalls` — required, boolean

Response `200`:
```json
{
  "success": true,
  "data": {
    "showOnlineStatus": true,
    "allowAudioCalls": true,
    "allowVideoCalls": false
  }
}
```

---

### Dashboard Overview (optional aggregate endpoint)

#### GET `/api/dashboard/overview`

Response:
```json
{
  "success": true,
  "data": {
    "pendingTaskCount": 4,
    "connectionCount": 24,
    "recentActivityCount": 10
  }
}
```

> Currently fetched separately (`/api/activity` + `/api/tasks/count`).  
> This endpoint can replace both calls once backend ships it.

---

## Error Codes

| Status | Meaning |
|--------|---------|
| 400 | Validation error — check request body |
| 401 | Unauthorized — token missing or expired |
| 403 | Forbidden — resource belongs to another user |
| 404 | Resource not found |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

---

## Task Breakdown

### ✅ Domain Models

- [x] `ActivityItem` — id, type (enum), title, description, timestamp
- [x] `TaskModel` — id, title, description?, status (enum), priority (enum), dueDate?, createdAt
- [x] `UserProfile` — id, email, fullName?, phone?, designation?, department?, company?
- [x] `UserSettings` — showOnlineStatus, allowAudioCalls, allowVideoCalls

### ✅ Mock Service (`lib/core/services/mock_service.dart`)

- [x] 300–800ms artificial delay per call
- [x] 10 mock activity items (all 5 types covered)
- [x] 5 mock tasks (mixed status + priority)
- [x] Mock user profile
- [x] Mock user settings (defaults)
- [x] Mock update methods (echo back input)

### ✅ Feature Flag (`lib/core/services/app_config.dart`)

- [x] `AppConfig.useMock = true` — flip to `false` to go live

### ✅ Repositories

- [x] `DashboardRepository` — getActivity, getTaskCount, getTasks
- [x] `SettingsRepository` — getProfile, updateProfile, getSettings, updateSettings
- [x] Mock/real branch in every method

### ✅ Providers (Riverpod)

- [x] `DashboardNotifier` (AsyncNotifier) — parallel fetch activity + taskCount
- [x] `SettingsNotifier` (AsyncNotifier) — parallel fetch profile + settings
- [x] Optimistic update in `updateProfile` / `updateSettings`
- [x] `refresh()` on both notifiers

### ✅ Dashboard Screen (`/home`)

- [x] Greeting header ("Good morning, John!")
- [x] Date display
- [x] 3 stat cards — Activity, Pending Tasks, Connections
- [x] Tasks overview card with pending count + "Go to Todos" CTA
- [x] Recent activity list (icon + title + description + relative time)
- [x] Empty state for no activity
- [x] Loading shimmer
- [x] Error + retry
- [x] Pull-to-refresh

### ✅ Settings Screen (`/settings`)

- [x] Profile form — fullName, phone, designation, department, company
- [x] `fullName` required validation
- [x] Separate save buttons for profile and privacy sections
- [x] Loading spinner on save
- [x] Success/error snackbar feedback
- [x] Privacy toggles — showOnlineStatus, allowAudioCalls, allowVideoCalls
- [x] Loading shimmer
- [x] Error + retry

### ✅ Router

- [x] `/home` → `DashboardScreen` (was placeholder HomeScreen)
- [x] `/settings` → `SettingsScreen` (was PlaceholderScreen)

---

## Pending (Backend Tasks)

- [ ] Implement `GET /api/activity` — NestJS module, entity, controller
- [ ] Implement `GET /api/tasks` + `GET /api/tasks/count`
- [ ] Implement `POST /api/tasks`
- [ ] Implement `PATCH /api/tasks/:id`
- [ ] Implement `DELETE /api/tasks/:id`
- [ ] Implement `GET /api/user/profile` + `PUT /api/user/profile`
- [ ] Implement `GET /api/user/settings` + `PUT /api/user/settings`
- [ ] Add request validation (class-validator DTOs in NestJS)
- [ ] Add JWT guard to all endpoints
- [ ] Set `AppConfig.useMock = false` and test end-to-end
