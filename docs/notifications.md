# Smart reminders (local notifications)

Reminders are **local** notifications, scheduled on the device with `flutter_local_notifications`.
There is no push server and no third-party SDK.

## When we ask

The app never asks for permission at launch. It asks once, in context: on the result sheet after
the **first published post** ("Want a heads-up when this post finishes?"). The OS prompt appears
only if the player taps *Notify me*. Players can change their answer any time in
**Life → Settings → Reminders**. If the OS denies permission, the setting stays off and the app
explains how to enable it.

## What we send

`NotificationPlanner` (`app/lib/domain/notifications/notification_planner.dart`) is pure Dart and
runs when the app goes to the background. It **projects the life forward with the real engine**,
so every message describes something that will really have happened by the time it fires:

| Kind | Example | When |
|---|---|---|
| `postFinished` | *Your "Outfit Check" post wrapped up — 1,240 views and +52 followers on Loop.* | when the latest post's curve completes |
| `milestone` | *1K followers on Loop!* | first projected crossing of the next follower milestone |
| `canAffordGear` | *You can afford the Clip Mic now* | when cash + collectable earnings cover the next unlocked gear |
| `storyWaiting` | *Maya sent you a message* | 2 h after leaving, if a story beat is waiting |
| `energyFull` | *Energy's full* | when energy reaches max |
| `awayCap` | *$14.20 is ready to collect* | when the offline accrual cap is reached |
| `dailyReminder` | *Ready for today's post?* | next day, at the hour this player usually plays (median of the last 7 session starts) |

## Anti-spam rules (`NotificationPolicy`)

- At most **3** per absence. Candidates are ranked by priority (the order of the table above).
- At least **45 minutes** apart, and never sooner than 10 minutes after leaving.
- **Quiet hours** run from 22:00 to 09:00 local time. Anything that falls inside them moves to 09:00.
- Nothing is promised beyond the offline cap, and nothing uses guilt or loss framing. Absence never
  harms a life (GDD C4).
- Returning to the app cancels everything pending. A new plan is made the next time the player leaves.
- One pending notification per kind (stable ids), so nothing can duplicate.

## Tests

- `test/domain/notification_planner_test.dart`: the numbers match the engine, plus the cap, spacing,
  quiet hours, the daily-reminder hour, honest gear affordability and determinism.
- `test/app/notifications_flow_test.dart`: opt in → leave → localized notes scheduled → return →
  cancelled. Players who opted out get nothing.

## Platform setup (done)

- iOS: `AppDelegate` sets the `UNUserNotificationCenter` delegate, and permission is requested only from the opt-in.
- Android: `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` permissions, plus the scheduled and boot receivers. Core-library desugaring is on. Alarms are inexact, so no exact-alarm permission is needed.
- Web preview: a no-op scheduler (browsers cannot schedule after the tab closes).

**Not yet verified on a device.** Check on a real iPhone and an Android 14+ phone (QA checklist).
