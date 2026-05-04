# Android Device Testing Setup

## 1. Enable Developer Options on the Phone

1. Open **Settings → About Phone**
2. Tap **Build Number** 7 times until "You are now a developer" appears
3. Go back to **Settings → System → Developer Options** (location varies by manufacturer)
4. Enable **USB Debugging**

---

## 2. Connect via USB

Plug the phone into your machine with a USB cable.

**Important:** When the phone asks _"Allow USB Debugging from this computer?"_ — tap **Allow**.

Also set the USB connection mode to **File Transfer (MTP)** — qg. Some phones show this in the notification shade when plugged in.

Verify the device is detected:
```bash
adb devices
```

Expected output:
```
List of devices attached
XXXXXXXXXXXXXXXX    device
```

If it shows `unauthorized`, unplug, re-plug, and accept the prompt on the phone again.

---

## 3. Run the App

```bash
flutter devices          # confirm your phone is listed
flutter run              # builds and installs on the connected device
```

---

## 4. What IP to Put in `constants.dart`

File: `lib/core/constants.dart`

```dart
static const String baseUrl = 'http://<IP>:3000';
```

| Scenario | IP to use |
|----------|-----------|
| Android Emulator (AVD) | `10.0.2.2` |
| Physical device, same WiFi as dev machine | Your machine's local LAN IP |
| Physical device, USB only (no WiFi needed) | `10.0.2.2` via `adb reverse` (see below) |

### Option A — Same WiFi (simplest)

Find your machine's local IP:
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
# look for something like 192.168.x.x or 10.x.x.x
```

Set in `constants.dart`:
```dart
static const String baseUrl = 'http://192.168.1.42:3000';  // example
```

Both phone and machine must be on **the same WiFi network**. Your NestJS server must be running and bound to `0.0.0.0` (not just `localhost`) — check your `main.ts`:
```typescript
await app.listen(3000, '0.0.0.0');
```

### Option B — USB via `adb reverse` (no WiFi needed, most reliable)

This tunnels the phone's requests through the USB cable to your machine's `localhost`.

```bash
adb reverse tcp:3000 tcp:3000
```

Then keep `constants.dart` as:
```dart
static const String baseUrl = 'http://localhost:3000';
```

The phone acts as if `localhost:3000` is your machine. Run this command each time you reconnect the phone.

---

## 5. Firewall (if using WiFi option)

If the phone can't reach the server, your firewall may be blocking port 3000:

```bash
# Allow port 3000 temporarily (Arch/systemd-based)
sudo firewall-cmd --add-port=3000/tcp --zone=public
# or with ufw:
sudo ufw allow 3000
```

---

## 6. Quick Checklist

- [ ] USB Debugging enabled on phone
- [ ] USB mode set to File Transfer (MTP)
- [ ] `adb devices` shows device (not `unauthorized`)
- [ ] NestJS backend running (`npm run start:dev`)
- [ ] Correct IP set in `lib/core/constants.dart`
- [ ] `flutter run` with device connected

---

## 7. Wireless Debugging (optional, Android 11+)

No USB cable after initial setup:

1. Connect phone via USB once and run the app at least once
2. In Developer Options → enable **Wireless Debugging**
3. Tap **Pair device with pairing code** — note the IP:port shown
4. Run:
   ```bash
   adb pair <phone-ip>:<pairing-port>
   # enter the 6-digit code shown on phone
   adb connect <phone-ip>:<port-shown-in-wireless-debugging>
   flutter run
   ```

After pairing, USB cable is no longer needed as long as both devices are on the same network.
