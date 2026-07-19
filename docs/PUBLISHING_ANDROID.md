# Android Publishing Plan — MyPlanr

App ID: `com.alnlabs.myplanr` · Version: `1.0.0+1` (bump per release)

Status legend: ✅ done · ⏳ pending · 🔴 blocker

---

## Phase 1 — Security & config ✅

- ✅ Secrets removed from the app bundle. `.env` (bundled) holds only
  `SUPABASE_URL` + `SUPABASE_ANON_KEY` (both public by design). Server secrets
  (DB password, SMTP, pooler) live in gitignored `.env.server`.
- ✅ Verified: a scan of the release `.aab` finds no DB password / SMTP / pooler.
- ✅ `targetSdk` pinned to 35 (Android 15) — required by Play in 2026.
- ⏳ **Rotate secrets** if any build with the old bundled `.env` was ever
  distributed (DB password + Gmail app password). Optional if never shared.

## Phase 2 — Signing ✅

- ✅ Upload keystore generated at `android/app/upload-keystore.jks`
  (alias `upload`), wired via `android/key.properties`. Both are gitignored.
- 🔴 **Back up** the keystore file + its password in a password manager. Losing
  it means you can't ship updates (Play App Signing can reset the *upload* key,
  but back it up anyway).
- ✅ Release build is signed with the upload key (not debug).

## Phase 3 — Build & verify ✅

- ✅ `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- ✅ `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
  (universal; use `--split-per-abi` for smaller test APKs)
- ✅ `flutter analyze` clean (lib); `flutter test` green.
- ⏳ **Smoke-test the release build on a physical device** (ProGuard/shrink can
  change behavior): notifications + exact alarms, camera → receipt scan, login,
  password-reset deep link, offline behavior.

## Phase 4 — Play Console listing & compliance ⏳

### 4.1 Create app & upload
- ⏳ Play Console → Create app → upload the `.aab` to **Internal testing** first.
- ⏳ Enroll in **Play App Signing** (recommended default).

### 4.2 App content / compliance forms
- ⏳ **Privacy Policy URL** (required). App collects account email + financial
  data and uses the camera, so a hosted policy is mandatory.
- ⏳ **Data Safety** form. This app:
  - Collects: name/email (account), app activity, and user content
    (expenses/income = financial info, photos = receipt images).
  - Data is sent to Supabase (our backend); encrypted in transit (HTTPS).
  - Provide account deletion path (in-app "Delete account" exists → link it).
- ⏳ **Permissions declarations**:
  - `SCHEDULE_EXACT_ALARM` / exact alarms — justify: time-critical reminders.
  - `CAMERA` — justify: scanning receipts.
  - `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` — reminder delivery/reschedule.
- ⏳ **Content rating** questionnaire.
- ⏳ **Target audience** & ads declaration (app has no ads).

### 4.3 Store listing assets
- ⏳ Title, short description (≤80 chars), full description (≤4000).
- ⏳ App icon (512×512), feature graphic (1024×500).
- ⏳ Phone screenshots (≥2). Use the demo family seed:
  run `supabase/seed/demo_family.sql`, log in as `demo.family@myplanr.app`.
- ⏳ Category, contact email, website.

## Phase 5 — Release ⏳

- ⏳ Internal testing → verify install/update on a real device.
- ⏳ Promote to Closed/Open testing (optional) → Production.
- ⏳ Roll out (consider staged rollout for the first release).

---

## Handy commands

```bash
# Release artifacts
flutter build appbundle --release          # Play upload (.aab)
flutter build apk --release --split-per-abi # smaller test APKs

# Version bump: edit pubspec.yaml `version: x.y.z+build` before each release

# Apply DB migrations (reads .env + .env.server)
set -a; source .env.server; set +a
./scripts/supabase_push.sh
```

## Pre-release checklist (each release)
- [ ] Bump `version:` in `pubspec.yaml`
- [ ] `flutter analyze` + `flutter test` green
- [ ] Smoke-test release build on device
- [ ] DB migrations applied to prod
- [ ] Build `.aab`, upload, update release notes
