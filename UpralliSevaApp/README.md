# ಪೂಜಾ ದಾಖಲೆ — Upralli Seva (Android app)

A Flutter Android app that shares the **same Firebase Firestore** as the web app
(`upralliseva` project). Edit on the web or the phone — both stay in sync live.

- Google Sign-In + the same `editors` whitelist (login required)
- Year picker + create new year
- Tap a ಮಾಗಣೆ → toggle pooja chips per person, saved live to the cloud
- **PDF export / share** (📄 in the app bar) with embedded Kannada font
- **Send to WhatsApp** (↗ in the app bar) — PDF goes straight to WhatsApp
  (falls back to the system share sheet if WhatsApp isn't installed)

The Dart source is in `lib/`. The platform scaffolding (`android/`) is generated
once with `flutter create` (below), so it matches your installed Flutter version.

---

## 1. Generate the platform scaffolding

You need Flutter installed (`flutter --version`). From this folder's **parent**:

```bash
# Generate android/ scaffolding WITHOUT clobbering the provided lib/ & pubspec.yaml.
flutter create --org com.upralliseva --project-name upralliseva_app --platforms=android temp_scaffold
```

Then copy these from `temp_scaffold/` into `UpralliSevaApp/`:
- the entire `android/` folder
- `.gitignore`
- `analysis_options.yaml`

Delete `temp_scaffold/` afterwards. (Do **not** copy its `lib/` or `pubspec.yaml` —
keep the ones provided here.)

> Simpler alternative: run `flutter create .` directly in this folder, let it
> overwrite, then paste the provided `lib/` files and `pubspec.yaml` back.

## 2. Set the package name to `com.upralliseva.app`

Open `android/app/build.gradle` and make sure:
```gradle
android {
    namespace "com.upralliseva.app"
    defaultConfig {
        applicationId "com.upralliseva.app"
        minSdkVersion 23        // firebase_auth needs >= 23
        // ...
    }
}
```

## 3. Register the Android app in Firebase

Firebase Console → your `upralliseva` project → **Add app → Android**:
- **Android package name:** `com.upralliseva.app`
- Download **`google-services.json`** and place it in `android/app/google-services.json`

Add the Google-services Gradle plugin (newer Flutter templates use the plugins block):

`android/settings.gradle` (plugins block) — add:
```gradle
id "com.google.gms.google-services" version "4.4.2" apply false
```
`android/app/build.gradle` — at the top plugins block add:
```gradle
id "com.google.gms.google-services"
```

## 4. Enable Google Sign-In for Android (IMPORTANT)

Google Sign-In on Android needs your app's **SHA-1** registered, or login fails
with `ApiException: 10`.

Get the debug SHA-1:
```bash
cd android
./gradlew signingReport      # Windows: gradlew signingReport
```
Copy the **SHA-1** under `Variant: debug`. Then in Firebase Console →
Project settings → your Android app → **Add fingerprint** → paste SHA-1 → Save.
Re-download `google-services.json` and replace the one in `android/app/`.

(Authentication → Sign-in method → **Google** must be enabled — already done.)

## 4b. Add the Kannada font (needed for PDF + consistent UI)

Download **Noto Sans Kannada** (free, OFL) from
https://fonts.google.com/noto/specimen/Noto+Sans+Kannada and copy
`NotoSansKannada-Regular.ttf` into:

```
assets/fonts/NotoSansKannada-Regular.ttf
```

It's already declared in `pubspec.yaml` (`fonts:`) and used by `lib/pdf_service.dart`
to embed Kannada in the exported PDF. See `assets/fonts/PLACE_FONT_HERE.txt`.

## 5. Install deps & run

```bash
flutter pub get
flutter run            # with a device/emulator connected
```

Build a release APK to share:
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
For a release build, also add the release keystore's SHA-1 to Firebase.

---

## Firestore rules (already used by the web app)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isEditor() {
      return request.auth != null
        && exists(/databases/$(database)/documents/editors/$(request.auth.token.email));
    }
    match /editors/{email} { allow read: if request.auth != null; allow write: if false; }
    match /pooja/{year}    { allow read, write: if isEditor(); }
  }
}
```

Add each allowed editor as a document in the **`editors`** collection
(document ID = their Gmail address). Same whitelist as the web.

## Releasing updates (so a shared APK *updates* instead of needing uninstall)

An installed app updates only when the new APK has the **same package** + **same
signing key** + a **higher versionCode**. Do this once, then repeat steps 3–4 per release.

**1. Create your release keystore (ONCE — keep it safe & backed up; losing it means
you can never update the app again):**
```bash
keytool -genkey -v -keystore upralli-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upralli
```
Put `upralli-release.jks` in the `android/` folder.

**2. Create `android/key.properties`** (copy from `key.properties.example`) with the
passwords/alias you just set. (Both files are already git-ignored.)

**3. Bump the version before each build** — edit `pubspec.yaml`:
```yaml
version: 1.0.0+1     # → 1.0.1+2 → 1.0.2+3 …  the "+N" (versionCode) MUST increase
```

**4. Build the release APK and share it:**
```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```
Send that APK (WhatsApp, Drive, etc.). Installing it over an older version **updates**
it, keeping data — because it's signed with the same key and has a higher versionCode.

**5. Add the release key's SHA‑1 to Firebase** (ONCE) so Google login works in release
builds — Google Sign-In is per-certificate:
```bash
keytool -list -v -keystore upralli-release.jks -alias upralli | findstr SHA1
```
Firebase Console → Project settings → Android app → **Add fingerprint** → paste →
re-download `google-services.json` into `android/app/`.

> Note: the **debug** APK from `flutter run` / `flutter build apk --debug` is signed with
> the machine's debug key. Debug↔debug updates work on your machine, but for APKs you
> distribute, always use the **release** build above so everyone gets consistent updates.

## Notes
- New-year creation copies the most recent year's name list with **blank**
  selections. The very first year must be created/seeded on the **web** (the
  full ಮಾಗಣೆ/ಹೆಸರು list lives in the web's `data.js`).
- Optional: bundle a Kannada font (e.g. Noto Sans Kannada) under `assets/fonts/`
  and declare `fontFamily: NotoSansKannada` in `pubspec.yaml` for consistent
  rendering across devices. Most Android devices already render Kannada fine.
