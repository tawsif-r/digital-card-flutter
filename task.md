# ConnectPro — Backend API Task Breakdown

## Stack
- **Runtime**: Node.js + NestJS
- **Database**: PostgreSQL + TypeORM (or Prisma)
- **Auth**: JWT (access + refresh tokens) — already implemented
- **Prefix**: All new routes under `/` (no `/api` prefix, matching existing `/cards`, `/auth` conventions)

---

## Modules to Build

| # | Module | Routes | Status |
|---|--------|--------|--------|
| 1 | Users / Profile | GET/PUT `/users/profile` | 🔲 |
| 2 | User Settings | GET/PUT `/users/settings` | 🔲 |
| 3 | Dashboard | GET `/dashboard/overview` | 🔲 |
| 4 | Activity Feed | GET `/activity` | 🔲 |
| 5 | Tasks | GET/POST/PATCH/DELETE `/tasks` | 🔲 |

---

## Module 1 — Users / Profile

### Entity: `UserProfile`

```typescript
// users/entities/user-profile.entity.ts
@Entity('user_profiles')
export class UserProfile {
  @PrimaryColumn() userId: string;
  @Column({ nullable: true }) fullName: string;
  @Column({ nullable: true }) phone: string;
  @Column({ nullable: true }) designation: string;
  @Column({ nullable: true }) department: string;
  @Column({ nullable: true }) company: string;
  @UpdateDateColumn() updatedAt: Date;

  @OneToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;
}
```

---

### GET `/users/profile`

**Auth**: Bearer token required

**Request**
```
GET /users/profile
Authorization: Bearer <access_token>
```

**Response 200**
```json
{
  "id": "usr_abc123",
  "email": "alex@example.com",
  "fullName": "Alex Johnson",
  "phone": "+1 555 123 4567",
  "designation": "Senior Engineer",
  "department": "Engineering",
  "company": "Acme Corp"
}
```

**Response 401**
```json
{ "statusCode": 401, "message": "Unauthorized" }
```

---

### PUT `/users/profile`

**Auth**: Bearer token required

**Request**
```
PUT /users/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "fullName": "Alex Johnson",
  "phone": "+1 555 123 4567",
  "designation": "Senior Engineer",
  "department": "Engineering",
  "company": "Acme Corp"
}
```

**Validation** (all optional)
- `fullName`: string, max 100
- `phone`: string, max 30
- `designation`: string, max 100
- `department`: string, max 100
- `company`: string, max 100

**Response 200** — same shape as GET `/users/profile`

**Response 400**
```json
{
  "statusCode": 400,
  "message": ["fullName must be shorter than 100 characters"],
  "error": "Bad Request"
}
```

---

## Module 2 — User Settings

### Entity: `UserSettings`

```typescript
// users/entities/user-settings.entity.ts
@Entity('user_settings')
export class UserSettings {
  @PrimaryColumn() userId: string;
  @Column({ default: true }) showOnlineStatus: boolean;
  @Column({ default: true }) allowAudioCalls: boolean;
  @Column({ default: true }) allowVideoCalls: boolean;
  @UpdateDateColumn() updatedAt: Date;
}
```

---

### GET `/users/settings`

**Auth**: Bearer token required

**Request**
```
GET /users/settings
Authorization: Bearer <access_token>
```

**Response 200**
```json
{
  "showOnlineStatus": true,
  "allowAudioCalls": true,
  "allowVideoCalls": false
}
```

---

### PUT `/users/settings`

**Auth**: Bearer token required

**Request**
```
PUT /users/settings
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "showOnlineStatus": true,
  "allowAudioCalls": true,
  "allowVideoCalls": false
}
```

**Validation** (all optional booleans)
- `showOnlineStatus`: boolean
- `allowAudioCalls`: boolean
- `allowVideoCalls`: boolean

**Response 200** — same shape as GET `/users/settings`

---

## Module 3 — Dashboard Overview

### GET `/dashboard/overview`

**Auth**: Bearer token required

Aggregates counts across modules. Use `Promise.all` for parallel DB queries.

**Request**
```
GET /dashboard/overview
Authorization: Bearer <access_token>
```

**Response 200**
```json
{
  "pendingTaskCount": 3,
  "totalCards": 5,
  "totalContacts": 12,
  "cardViewsThisWeek": 47
}
```

**Implementation notes**
- `pendingTaskCount`: `COUNT(*) FROM tasks WHERE userId=? AND status='pending'`
- `totalCards`: `COUNT(*) FROM cards WHERE userId=?`
- `totalContacts`: `COUNT(*) FROM contacts WHERE userId=?` (future module)
- `cardViewsThisWeek`: `COUNT(*) FROM card_views WHERE userId=? AND createdAt >= NOW() - INTERVAL '7 days'`

---

## Module 4 — Activity Feed

### Entity: `ActivityItem`

```typescript
// activity/entities/activity-item.entity.ts
export type ActivityType = 'message' | 'meeting' | 'connection' | 'cardView' | 'task';

@Entity('activity_items')
export class ActivityItem {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() userId: string;
  @Column({ type: 'enum', enum: ['message','meeting','connection','cardView','task'] })
  type: ActivityType;
  @Column() title: string;
  @Column() description: string;
  @Column({ type: 'timestamptz' }) timestamp: Date;
  @CreateDateColumn() createdAt: Date;
}
```

**Auto-generate activity** via NestJS event emitter or DB triggers when:
- Message sent → type `message`
- Meeting created → type `meeting`
- Connection accepted → type `connection`
- Card viewed (public endpoint hit) → type `cardView`
- Task marked done → type `task`

---

### GET `/activity`

**Auth**: Bearer token required

**Request**
```
GET /activity?limit=20&offset=0
Authorization: Bearer <access_token>
```

**Query params**
| Param | Type | Default | Max |
|-------|------|---------|-----|
| limit | int | 20 | 50 |
| offset | int | 0 | — |

**Response 200**
```json
[
  {
    "id": "act_xyz789",
    "type": "cardView",
    "title": "Card Viewed",
    "description": "Someone viewed your 'Acme Corp' card.",
    "timestamp": "2026-05-05T09:31:00.000Z"
  },
  {
    "id": "act_abc456",
    "type": "task",
    "title": "Task Completed",
    "description": "You completed 'Review Q2 report'.",
    "timestamp": "2026-05-05T08:15:00.000Z"
  }
]
```

**Ordered by**: `timestamp DESC`

---

## Module 5 — Tasks

### Entity: `Task`

```typescript
// tasks/entities/task.entity.ts
export type TaskStatus = 'pending' | 'inProgress' | 'done';

@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() userId: string;
  @Column() title: string;
  @Column({ nullable: true }) description: string;
  @Column({ type: 'enum', enum: ['pending','inProgress','done'], default: 'pending' })
  status: TaskStatus;
  @Column({ type: 'timestamptz', nullable: true }) dueDate: Date;
  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
}
```

---

### GET `/tasks`

**Auth**: Bearer token required

**Request**
```
GET /tasks?status=pending&limit=50&offset=0
Authorization: Bearer <access_token>
```

**Query params**
| Param | Type | Description |
|-------|------|-------------|
| status | `pending` \| `inProgress` \| `done` | Filter by status (optional) |
| limit | int | Default 50 |
| offset | int | Default 0 |

**Response 200**
```json
[
  {
    "id": "tsk_abc123",
    "title": "Review Q2 report",
    "description": "Go through slides and add notes.",
    "status": "pending",
    "dueDate": "2026-05-10T00:00:00.000Z",
    "createdAt": "2026-05-01T10:00:00.000Z",
    "updatedAt": "2026-05-01T10:00:00.000Z"
  }
]
```

---

### GET `/tasks/count`

**Auth**: Bearer token required

**Request**
```
GET /tasks/count
Authorization: Bearer <access_token>
```

**Response 200**
```json
{ "count": 7 }
```

---

### POST `/tasks`

**Auth**: Bearer token required

**Request**
```
POST /tasks
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "title": "Review Q2 report",
  "description": "Go through slides and add notes.",
  "dueDate": "2026-05-10T00:00:00.000Z"
}
```

**Validation**
- `title`: string, required, max 200
- `description`: string, optional, max 1000
- `dueDate`: ISO date string, optional

**Response 201** — full `Task` object (same shape as GET list item)

**Response 400**
```json
{
  "statusCode": 400,
  "message": ["title should not be empty"],
  "error": "Bad Request"
}
```

---

### PATCH `/tasks/:id`

**Auth**: Bearer token required. User must own the task.

**Request**
```
PATCH /tasks/tsk_abc123
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "status": "done"
}
```

**Allowed patch fields** (all optional)
- `title`: string, max 200
- `description`: string, max 1000
- `status`: `pending` | `inProgress` | `done`
- `dueDate`: ISO date string | null

**Response 200** — updated `Task` object

**Response 403**
```json
{ "statusCode": 403, "message": "Forbidden" }
```

**Response 404**
```json
{ "statusCode": 404, "message": "Task not found" }
```

**Side effect**: When `status` changes to `done`, emit `task.completed` event → creates `ActivityItem` of type `task`.

---

### DELETE `/tasks/:id`

**Auth**: Bearer token required. User must own the task.

**Request**
```
DELETE /tasks/tsk_abc123
Authorization: Bearer <access_token>
```

**Response 204** — no body

**Response 403**
```json
{ "statusCode": 403, "message": "Forbidden" }
```

**Response 404**
```json
{ "statusCode": 404, "message": "Task not found" }
```

---

## NestJS Module Structure

```
src/
├── users/
│   ├── users.module.ts
│   ├── users.controller.ts       # GET/PUT /users/profile, GET/PUT /users/settings
│   ├── users.service.ts
│   ├── dto/
│   │   ├── update-profile.dto.ts
│   │   └── update-settings.dto.ts
│   └── entities/
│       ├── user-profile.entity.ts
│       └── user-settings.entity.ts
├── dashboard/
│   ├── dashboard.module.ts
│   ├── dashboard.controller.ts   # GET /dashboard/overview
│   └── dashboard.service.ts
├── activity/
│   ├── activity.module.ts
│   ├── activity.controller.ts    # GET /activity
│   ├── activity.service.ts
│   └── entities/activity-item.entity.ts
└── tasks/
    ├── tasks.module.ts
    ├── tasks.controller.ts       # GET/POST/PATCH/DELETE /tasks
    ├── tasks.service.ts
    ├── dto/
    │   ├── create-task.dto.ts
    │   └── update-task.dto.ts
    └── entities/task.entity.ts
```

---

## Database Migrations

| Migration | Description |
|-----------|-------------|
| `CreateUserProfiles` | `user_profiles` table |
| `CreateUserSettings` | `user_settings` table |
| `CreateTasks` | `tasks` table with status enum |
| `CreateActivityItems` | `activity_items` table with type enum |
| `CreateCardViews` | `card_views` table for analytics |

---

## Auth Guard

All new endpoints use the existing `JwtAuthGuard`. Apply at controller level:

```typescript
@UseGuards(JwtAuthGuard)
@Controller('tasks')
export class TasksController { ... }
```

Extract `userId` from request via the existing `@GetUser()` decorator or `req.user.id`.

---

## Error Response Convention

```json
{
  "statusCode": 400,
  "message": "string | string[]",
  "error": "Bad Request"
}
```

Use NestJS `ValidationPipe` globally with `whitelist: true, forbidNonWhitelisted: true`.
