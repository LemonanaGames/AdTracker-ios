# Economy & balance (M1)

All numbers are **balance hypotheses** (GDD A4), not market benchmarks. They live in
`game_content/balance/*.json`, so you can change them without touching code. Re-run the simulator
after every change.

## Core formulas (as implemented)

All math uses integers (permille ‰, basis points, cents):

```
quality   = clamp(0..100, nicheFit(26 own / 18 other) + Σgear + hook + ⌊Σskill tenths/10⌋ + storyBonus − ⌊stress/5⌋)
baseline  = baseReach + followers·reachPerFollower‰ + otherNetworksFollowers·crossReach‰
views     = baseline · (1+marketing) · (0.4 + quality/100) · platformFit · trend(0.80–1.45, seeded per topic/network/day)
            · fatigue(−6% per own post in last 12 game-h, floor 60%) · (1+storytelling on long-form) · viral[0.65,0.95,1.15,2,4]
credited(t) = views · curve(network, t)                      (pure function → idempotent crediting)
followers = credited · viewToFollow · (0.5 + trust/200) · nicheAffinity(1.0 own / 0.7 other)
revenue   = credited · RPM / 1000  → pending wallet → Collect (idempotent per claim id)
XP/post   = 20 + quality/5 ;  level L needs 100·(L−1)·L/2 XP ; +1 Skill Point per level
```

*Cross-promotion* (`crossReachPermille`, 10%) lets followers on one network help a newly unlocked
network get discovered. It adds **reach only**: followers are never copied (tested).

## Time

`simSecondsPerRealSecond = 120`, so 1 game hour = 30 real seconds and a Loop post finishes in 18
real minutes. Offline progress is capped at 4 real hours (free) and 24 hours (Pro, not yet grantable).
Energy and stress regenerate exactly; splitting time into ticks gives the same result as one big step.

## Simulator results (45 lives, 3 strategies, 180 real minutes in the foreground, no offline time)

```
$ dart run tool/simulate_lives.dart 45 180
milestone            reached   p10    median   p90   (real minutes)
first light          45/45       0.1     0.1     0.1
V01 story            45/45       0.4     0.7     1.0
level 2              45/45       1.0     1.0     1.0
loop 100             45/45       1.2     1.8     2.4
act1 (TubeCast)      45/45      11.7    11.7    11.7
act2                 42/45     152.4   163.9   177.3
loop 1k              15/45      28.7    34.5    38.0
loop 10k             14/45     159.8   169.7   177.8
final after 180 min:
  loop      p10 399    median 532    p90 11827
  tubecast  p10 0      median 5845   p90 7327
  level     p10 7      median 8      p90 8
  cash ($)  p10 854    median 3690   p90 4720
```

How to read it:
- The first-session beats in GDD B1 hit their targets: first gear in under 5 minutes (via one cafe
  shift), the V01 story beat in about 1 minute, and a network strategy preview (TubeCast) at about
  12 minutes.
- Different strategies take different routes to Act II. The Loop-only bot gets there via Loop 10K
  plus 4% engagement. Mixed bots get there via TubeCast 5K plus 3.5%.
- The bot plays continuously and posts whenever it has energy. Real players are slower in the
  foreground and faster thanks to offline accrual, so the playtest/soft launch must recalibrate.

## Known gaps

- Late game (100K → 1M) isn't tuned yet. It needs sponsors (M2) and lifestyle sinks (M3).
- Cash outpaces sinks after about 2 hours because gear beyond Level 4 is Act-gated. M2/M3 add homes,
  sponsors and promotion budgets as sinks.
