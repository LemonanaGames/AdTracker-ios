# Economy simulator

Seeded autoplay (`AutoPlayer`, `app/lib/domain/engine/autoplayer.dart`) over many lives and three
strategies (balanced, trend-chaser, single-network). It reports real-time pacing to key milestones.

```sh
cd app && dart run tool/simulate_lives.dart [lives=200] [minutes=180]
```

Results and their interpretation are recorded in `docs/economy_balance.md`. The GDD H5 target of
10,000 lives is a matter of the `lives` argument (allow about 20 minutes for 10k × 180 min).
