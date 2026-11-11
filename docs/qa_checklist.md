# QA checklist

## Automated (every PR, `.github/workflows/ci.yml`)

- [x] `flutter analyze` clean (strict casts/inference/raw types)
- [x] `flutter test`: domain, save, content, architecture and widget flows
- [x] `dart run tool/validate_content.dart`: content cross-references
- [x] Balance smoke: `dart run tool/simulate_lives.dart 15 60`
- [x] iOS build `--no-codesign` on macOS

## Manual: M1 first-session script (iOS simulator + one device)

1. Fresh install → welcome → name → handle suggestion is editable → niche → avatar → Home with no popups.
2. Home shows Next goal "Publish your first post", the three network cards (TubeCast and Vibe locked with a reason) and a Create Post button that is visible without scrolling.
3. Create → "First Challenge" is marked "Start here" → quality 38/100 → Publish → "Publishing…" → "Published!" with rolling counters and the followers coachmark (only the first time).
4. Wait about 30 s → followers and views keep rising on Home → "Earnings ready" → Collect (a second tap is impossible because the card disappears).
5. Life → Cafe shift → cash +$60 → Gear → Desk Light shows "+8 → +10" → buy → Create preview quality +2.
6. Second post above 500 views → story card → V01 sheet → "Ask Maya" is locked under $100 → choose → chips match the result.
7. Kill the app → wait 2+ minutes → relaunch → "While you were away" and the state is intact.
8. Change the device clock back 1 day → relaunch → no loss and no gain, and the game keeps running.
9. VoiceOver: tabs, buttons and metrics have labels; "?" explainers read fully.
10. Settings → Accessibility → Reduce Motion: counters jump, there are no scale springs, and the chart has no reveal animation.
11. Largest Dynamic Type: no clipped primary actions (known risk: header pills).

## Manual: feel & reminders (M1.5)

12. Sounds: tap, publish whoosh, coin on Collect and jobs, ka-ching on gear, level-up arpeggio. The silent switch mutes them. Music from another app keeps playing.
13. Haptics on buttons and celebrations. Turning off Sound or Vibration in Life → Settings stops them.
14. First post → "Notify me" → iOS prompt → allow. Leave the app; within the offline cap a "post wrapped up" notification arrives with the same numbers the game shows on return. Nothing arrives between 22:00 and 09:00, and at most 3 per absence.
15. Reopen the app: pending reminders are gone (check with a second absence).
16. Deny permission: the toggle stays off and the explanation snackbar appears.

## Not yet covered

Device performance profiling (60 fps), cold-start timing, contrast audit, Hebrew RTL pass, and
everything from M2 onward.
