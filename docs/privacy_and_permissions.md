# Privacy & permissions

## Current build (M1)

- **No network access is needed or used.** No SDKs are installed: no Firebase, Singular, AdMob or RevenueCat.
- All data lives in an on-device SQLite database (`influencer_simulator.sqlite` in the app's
  documents directory) and is included in the normal iOS device backup.
- The only permission is **notifications**. It is requested once, in context, after the first post, and only if the player taps "Notify me" (see `notifications.md`). Reminders are local, with no push server and no token. There is no ATT, photos, camera or tracking.
- Sound and vibration can be switched off in Life → Settings.
- The account is a local UUID (`local-…`), not linked to any identity.
- The in-app "About" section says so in plain language.

## Planned (must be implemented as described, GDD D4/F5/K1)

- Consent (UMP) is shown before any identifier or personalised-ads SDK runs. ATT is asked only with
  honest context, and the game works fully if tracking is denied.
- Personal media (M6) is picked with the system photo picker. Only a bounded, compressed thumbnail
  is copied into the sandbox. It is never uploaded or analysed, can be deleted at any time with
  "Delete all imported media", and is excluded from analytics beyond `custom_media_used=true`.
  We need to decide whether imported thumbnails are excluded from iCloud device backup (Firestore
  sync never includes them).
- Account deletion/export flow and Sign in with Apple linking arrive with M4.
- Privacy Nutrition Labels and the privacy manifest are filled in from the SDKs actually installed (M7).
