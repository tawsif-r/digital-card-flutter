# API Configuration

## Base URL

Defined in `lib/core/constants.dart` → `AppConstants.baseUrl`.

| Context | Value | When to use |
|---|---|---|
| Local dev (web/desktop) | `http://localhost:3000` | You run both Flutter + NestJS on same machine — **currently overridden to LAN IP** |
| Android emulator | `http://10.0.2.2:3000` | AVD maps `10.0.2.2` → host loopback |
| Physical device / teammate | `http://192.168.3.35:3000` | **ACTIVE** — colleague on same network |

### Finding your LAN IP

```bash
# Linux/macOS
ip addr show | grep 'inet ' | grep -v 127.0.0.1
# or
hostname -I

# Windows
ipconfig | findstr "IPv4"
```

Example: `http://192.168.1.42:3000`

> **ECONNREFUSED on another machine?** Almost always means `baseUrl` still points to `localhost`.
> Change it to the host machine's LAN IP and hot-restart the app.

---

## NestJS Backend Endpoints

Backend repo: `~/Documents/digital_card` — runs on port `3000`.

### Auth (`/auth`)

| Method | Path | Auth required | Description |
|---|---|---|---|
| POST | `/auth/register` | No | Register new user. Returns `{access_token, refresh_token, user}` |
| POST | `/auth/login` | No | Login. Returns `{access_token, refresh_token, user}` |
| POST | `/auth/logout` | Bearer access token | Revoke refresh token |
| POST | `/auth/refresh` | Bearer **refresh** token | Rotate token pair |

### Users (`/users`)

| Method | Path | Auth required | Description |
|---|---|---|---|
| GET | `/users/me` | Bearer access token | Fetch current user profile |

### Cards (`/cards`)

| Method | Path | Auth required | Description |
|---|---|---|---|
| GET | `/cards` | Bearer access token | All cards belonging to current user |
| POST | `/cards` | Bearer access token | Create new card |
| PATCH | `/cards/:id` | Bearer access token | Update existing card |
| DELETE | `/cards/:id` | Bearer access token | Delete card |

### Public (`/public`)

| Method | Path | Auth required | Description |
|---|---|---|---|
| GET | `/public/:slug` | No | Fetch a card by its public slug (share link) |

---

## Auth Flow (Flutter side)

1. Login/register → store `access_token` + `refresh_token` via `flutter_secure_storage`
2. Every request → `AuthInterceptor` attaches `Authorization: Bearer <access_token>`
3. 401 response → interceptor calls `POST /auth/refresh` with `refresh_token`
4. Refresh succeeds → retry queued requests with new token
5. Refresh fails → `forceLogout()` → redirect to login

Interceptor: `lib/core/network/auth_interceptor.dart`
Tokens: `lib/core/storage/secure_storage.dart`

---

## Quick Checklist for New Devs

- [ ] NestJS backend running: `cd ~/Documents/digital_card && npm run start:dev`
- [ ] Correct `baseUrl` set in `lib/core/constants.dart` for your context (see table above)
- [ ] If on physical device or testing with teammate: use host machine's LAN IP, not `localhost`
- [ ] Flutter web: `CHROME_EXECUTABLE=/usr/bin/chromium flutter run -d chrome` (Arch Linux)
- [ ] Android emulator: use `http://10.0.2.2:3000` as base URL
