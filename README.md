# Smart Bus Tracking and Management System (Flutter)

A complete, ready-to-run Flutter/Android Studio project implementing the full spec:
authentication, live bus tracking (simulated), route/bus/stop search, GPS-based nearby
stops, camera + voice-recorded issue reporting, trip history, profile management, and
an admin module for managing buses/routes/reports — all backed by local SQLite.

## How to open this project

1. Open **Android Studio** → `File > Open` → select this `smart_bus_tracker` folder.
2. Let Android Studio detect it as a Flutter project (install the Flutter/Dart plugins
   if prompted: `Settings > Plugins > Flutter`).
3. In a terminal at the project root, run:
   ```
   flutter pub get
   ```
4. **Add Android permissions** — open `android/app/src/main/AndroidManifest.xml`
   (created automatically the first time you run/build) and paste the contents of
   `android_manifest_permissions.xml` (included at the project root) into it, as
   described in that file's comments.
5. Connect a device or start an emulator, then run:
   ```
   flutter run
   ```

> Note: this project was authored outside of Android Studio, so the `android/`, `ios/`,
> and other platform folders that Flutter normally scaffolds are not included here.
> The very first time you open it in Android Studio (or run `flutter create .` from
> the project root), Flutter will generate those platform folders automatically around
> the existing `lib/` and `pubspec.yaml` — nothing in `lib/` needs to change.

### Quick platform scaffold (if `android/` is missing)
```
cd smart_bus_tracker
flutter create .
flutter pub get
```
This regenerates the platform folders (Android/iOS/etc.) without touching your Dart code.

## Demo login
- **Admin:** `admin@bus.com` / `admin123` (unlocks the Admin Dashboard from Home)
- Or tap **Register** to create a new passenger account.

Demo buses/routes are seeded automatically on first launch (`Tambaram → Central
Station` on bus `21G`, `Sholinganallur → T Nagar` on bus `5C`).

## Project structure
```
lib/
  main.dart                     App entry point
  theme/app_theme.dart          Colors, gradients, typography, shared styles
  models/models.dart            AppUser, Bus, BusRoute, BusStop, Report, TripHistory
  db/db_helper.dart              SQLite (sqflite) schema + full CRUD
  providers/session_provider.dart  Login/session state (Provider)
  widgets/common_widgets.dart    Reusable buttons, cards, chips, text fields
  screens/
    auth/                        splash, login, register, forgot password
    home/                        dashboard, search bus, live tracking (map),
                                  nearby stops, report issue (camera+mic), trip
                                  history, profile
    admin/                       admin dashboard, manage buses, manage routes,
                                  view passenger reports
```

## Key implementation notes
- **Maps:** `flutter_map` with OpenStreetMap tiles (no API key required).
- **Live tracking simulation:** the selected bus "moves" along a generated polyline
  every 3 seconds via a `Timer`, updating its SQLite row (`lastLat`/`lastLng`) —
  satisfying "simulate real-time bus movement" without needing a real driver app.
- **Camera & voice:** `image_picker` (camera source) and `record` capture issue
  photos and voice complaints; files are saved to app documents and their paths
  stored in the `reports` table; playback via `audioplayers`.
- **GPS:** `geolocator` powers nearby-stop distance sorting and tagging report
  location.
- **Offline-first:** everything persists locally via `sqflite`; no backend required,
  ideal for offline demos/viva.

## Extending later
As the source spec notes, this can be extended with Firebase Auth + Firestore for
real multi-device sync, real driver-side GPS broadcasting (replacing the simulation
timer with live location updates), QR ticketing, and push notifications — without
needing to redesign the existing screens or database schema.
