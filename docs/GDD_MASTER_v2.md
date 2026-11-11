# INFLUENCER SIMULATOR: ZERO TO FAME

Complete Game Design, Narrative, Economy, UX, Monetization and Engineering Master Specification — v2.0

- **Date:** 2026-11-11
- **Status:** authoritative product design proposal / implementation handoff, NOT built code
- **Owner’s source:** original six-minute-plus game-reference recording and iterative requirements
- **First launch:** iOS; architecture: Flutter portable to Android
- **Originality:** genre mechanics only from reference; no copying of proprietary assets, text, layouts or code
- **Working title:** Influencer Simulator: Zero to Fame (legal clearance and ASO validation pending)
- **Languages:** English first, localization-ready including Hebrew RTL, with strings as resource IDs
- **Definitions:** MVP = shippable experience, not a demo; vertical slice = first polished coherent gameplay circuit.

> **NON-NEGOTIABLE**: This document is the product definition and the instruction source for coding agents. Do not implement every future feature in one pass. Follow milestone gates, tests, interfaces and acceptance criteria. Never claim an SDK is installed or configured until it has actually been verified in the target project.

---

## PART A — DECISIONS, PILLARS AND SCOPE

### A1. Locked decisions

1. Fantasy: unknown creator with a modest phone → multi-network celebrity → media mogul.
2. Three independently maintained simulated platforms, represented by original invented brands (working names Loop short videos, TubeCast long videos, Vibe photos/lifestyle), visibly explained as TikTok/YouTube/Instagram-style mechanics without using a confusingly similar trademark, logo or UI.
3. Player sees Total Fans headline plus per-platform followers, engagement, views, revenue, fan trust and unlocks. Do not sum overlapping cross-platform followers as verified unique humans: label Total Followers Across Platforms if summing and separately show Estimated Unique Reach as a modeled estimate.
4. Game is single-player, portrait, polished 2D narrative/idle/life sim; graphics, micro-animations, dashboards and share cards; no rendering a real video per simulated publication.
5. Content is simulated locally; optional player-selected personal photo/video file can furnish a local-only visual preview/thumbnail (no server upload). Player media must never affect economics in a way that requires real-video analysis.
6. Career contains authored branching narratives, multiple endings, personal life, relationships/homes, lifetime completion, archive of previous lives and creation of new lives. Free players have at least one archived life and a new-life action; Pro may raise simultaneous slots, never erase existing paid content.
7. Monetization: AdMob mediation with rewarded ads first; RevenueCat + App Store Connect IAP; offers eligible only at relevant, safe moments; entirely configurable exposure and content remotely, with store-controlled final real-money prices.
8. Tech: Flutter/Dart, Riverpod, go_router, Drift/SQLite, Firebase Auth/Firestore/Functions/Remote Config/Crashlytics/Analytics, Singular iOS attribution, RevenueCat, Google Mobile Ads; native platform bridge as needed; no hard dependency on production AI generation at runtime.
9. iOS-first TestFlight/soft-launch; Android compatibility planned but Android release is separate milestone.
10. User-facing design: understandable to a first-grader in navigation and numerical causality, not targeted specifically at young children. If targeting children, redesign monetization/data collection per applicable child privacy and ads rules.

### A2. Product pillars

- Clear 3-second answer to “What can I do next?” on every major screen.
- Every action shows cost, expected benefit, conditions, and time before commitment.
- Each session yields an immediate meaningful progress beat; no obligation to watch ads or pay.
- Choice-driven plot: meaningful relationships and reputation, no false choices.
- Three-platform strategy: different audiences, economics, eligibility and viral curves.
- Player autonomy: multiple valid paths (authentic star, luxury commercial celebrity, empire builder, community-first creator).
- Delight: subtle spring animations, quality images, micro-interactions, positive celebrations, readable copy.
- Fair monetization: ads opt-in where possible; never manipulate urgency or hide real money price.
- Future-proof: content catalogs, economy rules, store catalog, story graphs, visual assets and feature flags versioned separately from UI.

### A3. MVP / future scope arbitration

**MVP:** onboarding; avatar (limited preset options); three simulated networks, with first network immediately available and others unlocked via chapters; post composer and timeline; revenue and follower simulation; 6 skills; 10 pieces of gear; 3 jobs; 10 sponsor templates; 8 NPCs; 3 home tiers; relationship light system; 4 acts + 2–3 distinct endings; Life Archive + start over; local user photo/video media preview and deletion; shareable achievement cards; rewarded ads; 3–5 IAP SKUs; Firebase + Singular instrumentation; deterministic offline simulator; cloud sync and restore.

**Phase 2:** faceless creator preset/branch, live streaming, events, team/agency, wider niche breadth, more relationships, rival mechanics, home customization, more sponsor verticals, creator awards.

**Phase 3:** creator companies, generational legacy, tours, community events, cross-device media sync opt-in only, creator economy seasons, richer reputation simulation, optional AI-authored content reviewed and shipped as a pack.

**Exclude:** public UGC feed, live streaming user media to servers, actual platform APIs or social-platform account access, real crypto, real sponsorship matching, user-to-user chat, real-money wagering, multiplayer marketplace, open world 3D, manipulative randomized paid loot.

### A4. References and research caveats

- The linked Music Star Idle Life Simulator is a structural genre reference, not a cloning instruction. The original reference’s shop includes Pro, skill points and cash pack product classes; the specific current live SKU configuration must be rechecked before using it in competitive analysis.
- BitLife is inspiration for life completion → summary → archived life → new life; exact competitor internals cannot be inferred from screenshots.
- All numerical thresholds/prices/timers in this specification are initial balance hypotheses and must be tuned in simulations/soft launch. Do not label them as measured market benchmarks.

---

## PART B — GAME DESIGN, NARRATIVE AND USER JOURNEYS

### B1. One-line pitch and primary loop

**Pitch:** Grow from zero followers to fame on three social networks, publish content, negotiate sponsorships, build friendships and a life, make consequential choices, and retire as one of multiple celebrity archetypes.

Choose niche → produce post → publish → watch 6–48-hour simulated performance → earn cash/fans/skill XP → unlock collabs and deals → invest in gear/lifestyle → reach next act → decide what kind of famous person to become → end life → archive and restart.

**Session models**

- First 90 seconds: avatar name + niche, first post, first animated follower reward; no store interruption.
- First 5 minutes: a second post, first gear upgrade, friend/rival message, a career objective.
- First 10–15 minutes: short-viral spike, first sponsor teaser, network strategy preview. Pace subject to playtest.
- Daily return: claim accumulated income (free offline accrual), check two top posts, fulfill optional contract, make one meaningful choice, upgrade one thing.
- Long session: queue videos, multi-platform decisions, interact with NPCs, manage brand affinity and property.

### B2. High-level timeline / acts / ending reachability

Story progresses via Acts plus a separately displayed Creator Level (skills/progress) and independently tracked platform followers. An act milestone is not solely total followers. Alternate eligibility exists for niche success/high trust to avoid forced platform switching. Target first complete life: roughly 5–12 hours of engaged play spread over sessions; tune after tests.

| Act | Working name | Indicative trigger | New ability | Story pivot | Typical completion beat |
|---|---|---|---|---|---|
| Prologue | The First Post | new game | content + short platform + room/job | first post / first comment | first 100 followers |
| I | The Breakout | short platform 1k or creator lvl 3 | second platform + 1st collab | trend vs own voice | first viral moment |
| II | The Offer | one platform 10k + engagement threshold or trust alt | sponsorships + lifestyle | sponsor honesty test | first paid brand post |
| III | Everyone’s Watching | major network 100k or combined quality | all three platforms + rival + manager | leaked context controversy | headline success or recovery |
| IV | The Crown | one platform 1M or equivalent career score | luxury, higher sponsorships, finale | independence vs empire | terminal ending + archive |

Act indicates narrative chapter and unlock gates; Creator Level increases by XP; networks have separate progress. On Life Completed a player can continue in sandbox post-ending or archive and launch a fresh life. Strong endings earned through explicit requirements, not arbitrary random assignment.

### B3. Narrative variables and branching policy

integrity 0..100, audienceTrust 0..100, burnout 0..100, creativeFreedom 0..100, businessPower 0..100, friendship[NPC] 0..100, rivalry[NPC] 0..100, legacyScore 0..100; per-network followers, avgEngagement, subscribers, reach, monetizationEligibility.

Each authored choice requires: a concise preview of at least the direction of effects; eligibility; immediate effects; deferred flags; at least one callback later; analytics. Do NOT promise outcomes that are actually random without revealing uncertainty. Store choices and one-time fulfillment IDs. No dead ends that force IAP to continue.

#### Narrative Arc 1 — THE FIRST VIRAL MOMENT (Prologue → Act I)

Characters: Maya supportive childhood friend; Kai ambitious peer; Coach Noor editing mentor.

**Event V01: “Your Phone Is Blowing Up”**

- Trigger: 2 posts published, one > 500 simulated views; once per life.
- Maya: “You got 500 views before breakfast. That’s not nothing.”
- Kai: “Everyone’s doing the challenge. Copy it before it fades.”
- Choice A Ride the trend: trendBoost +20% for next short post; integrity -4; Kai relation +5. Follow-up Kai Offers a Collab.
- Choice B Make it yours: editing XP +15; trust +5; unlock Signature Series; delayed +quality bonus to 3 posts.
- Choice C Ask Maya for help: budget cost $100; friendship +8; unlock duet thumbnail option.
- Hook: first dramatic moment arrives within next few actions; visible near-term goal “Post your breakthrough video”.

**Event V02: “The Comment”:** first hostile comment; respond kindly (trust +), roast them (reach +/- with reputational risk), ignore (stress -), leading to a future fan community callback.

#### Narrative Arc 2 — THE FIRST SPONSOR (Act II)

Characters: Avery fictional drink brand representative; Noor; Maya.

**Event S01: “Your First Big Offer”**

- Trigger: eligible short platform >=10k and 4% modeled engagement (or alternative long platform >=5k and 3.5%). Deal payout example $800, 1 short sponsored post, 3 simulated days deadline.
- Avery: “Your audience listens to you. We’d love to partner for one post.”
- Maya: “Only say yes if you’d recommend it to your friends.”
- Choice A Take the deal: +cash on verified in-game fulfillment, integrity -3 if poor niche fit, future Sponsor Regret callback.
- Choice B Negotiate: consume one negotiation turn, roll against skill (display success probability range), possible $950 / unchanged / offer lost; no hard lockout.
- Choice C Decline politely: trust +7, next aligned-brand chance boost; immediate cash 0.
- Choice D Ask for creative control: smaller cash $650 but creativeFreedom +8 and trust +3.

**Event S02: “The Audience Notices”:** if low fit, fans ask why promoted; respond honestly/deflect/ignore, with delayed sponsor reputation outcomes.

**Event S03: “An Ethical Brand Returns”:** only if trust maintained, a better-aligned sponsor arrives with smaller upfront but relationship potential.

#### Narrative Arc 3 — FRIEND, RIVAL, MANAGER (Act II → III)

**Event R01: “The Collab Invite”**

- Kai (rival): “We’d both grow faster if we worked together. Don’t overthink it.”
- Accept: reach multiplier 1.3 on collab, rivalry -10, Kai friendship +8; or decline: independence +5 and rival event unlock.
- Optional third choice: invite Maya instead; lower short-term views, +trust +friendship.

**Event R02: “The Manager’s Contract”**

- Leah, agent: “I’ll open doors. I take 15% of your sponsor income.”
- Sign: deal pool quality +, commission on sponsorship only, manager relationship.
- Self-manage: negotiation workload +, full cash and +creative freedom.
- Trial contract: short 2-deal term, unlock via negotiation skill, lesser bonuses.

**Event R03: “The Misleading Clip”**

- Viral controversy caused by out-of-context edit. Choices: clarify thoughtfully (short-term views loss, trust recovery), attack rival (views increase, burnout/reputation cost), pause and focus on long content (recovery over next sessions). Consequences appear at V04 and final ending eligibility.

#### Narrative Arc 4 — THE LIFE BEHIND THE CAMERA (Acts II–IV)

**Event L01: “A Person, Not a Profile”**

- Alex potential partner (gender presentation configurable; no gender-specific assumption), relationship unlocked via home/social activity. Spend an evening together (time cost +relationship), skip for deadline (+cash chance and relationship tension), invite into content (reach + but privacy tension).

**Event L02: “The Move”**

- Choose apartment: small affordable home (+sleep/stress recovery), stylish studio (+production efficiency, maintenance cost), luxury penthouse (+prestige, large recurring expenses). No arbitrary romance restriction to expensive housing.

**Event L03: “The Boundary”**

- Partner requests privacy. Respect (+trust +relationship), publish couple content (+reach but -relationship), negotiate joint content (balanced if skill). Future fan reaction event.

**Event L04: “Burnout”**

- Trigger: burnout high; player can rest (lose production time but recover), delegate (cash cost), power through (temporary output gain with future quality penalties). Never weaponize absence from app as harm.

#### Narrative Arc 5 — THE ENDGAME OFFER (Act IV)

**Event F01: “The Seven-Figure Decision”**

- Nova Media, fictional company, offers a premium multi-year exclusive brand and network deal.
- Path 1 Sign the empire deal: high businessPower and net worth, low creativeFreedom, ending gate THE MOGUL.
- Path 2 Stay independent: requires integrity >=65 and followers threshold; ending THE ICON.
- Path 3 Build community nonprofit + own label: requires community choices & trust >=75, ending THE PEOPLE'S CREATOR.
- Path 4 Walk away and choose family/privacy: requires relationship threshold; ending A LIFE OFF-CAMERA.
- Path 5 Fame at any cost: high fame and low trust, ending THE CONTROVERSIAL LEGEND (not a moral ‘bad end’; reflects tradeoffs).

**Event F02: “Last Upload?”**

- “The whole world knows your name. But what do you want them to remember?”
- Player sees 2–4 ending options they have earned, plus locked options with readable criteria. Choose ending; view 5-card epilogue; archive save; offer New Life with fresh archetype. If no special ending gates, guaranteed fallback THE SELF-MADE CREATOR.

#### Script format per authored event

Every event JSON must contain id, act, trigger, oncePerLife, title, sceneAssetKey, speaker, lines[], choices[{id,label,preview,requirements,effects,deferredFlags,nextEventId}], fallback, analyticsTags, localizationKeys, designerNotes, version.

Narrative QA requires at least one callback for each meaningful choice within 3–10 gameplay beats; all endings reachable by automated path tests; no purchased-only ending. Keep event dialogue short (headline <= 50 characters, 1–3 speech bubbles <=100 characters each where possible); accessibility text can be longer.

### B4. Life Archive / replay system

- lifeId immutable UUID, playerId account identity, lifeNumber monotonic, saveVersion, createdAt, completedAt, endingId, finalStats, storyFlags, thumbnailAssetKey, summaryCardPath optional, archiveState, contentVersion.
- Primary buttons when life completed: Continue This Life (sandbox), Archive & Start New Life, Share Your Ending.
- No destructive overwrite: archival is immutable snapshot; opening archived life is read-only or resume only if explicitly designed.
- Start new life resets money/levels/followers/relationships but preserves account-level permanent IAP entitlements and earned non-pay-to-win collection badges. Consumable purchases must have clearly described scope before buy; unused consumable balance must not be silently lost by restart. Default safer approach: premium consumables held in account wallet or clearly disclosed per-life with confirmation.
- At least 1 archive slot + 1 active life free. Additional simultaneous active slots via Pro may be tested; no deletion forced as surprise; exportable summary.
- Avoid pretending generations/offspring are MVP. A future legacyMode can grant story cameos without giving unfair power advantages.
- Share cards for milestones (100k, 1M, brand deal, ending) rendered as image with stats and optional fictional avatar; use native OS Share Sheet, do not auto-post or require social login. No personal media in share by default; opt-in user preview and watermark free choice.

### B5. Optional minimal faceless mode

Do not build a separate game branch now. In MVP support Creator Persona with On-camera and Faceless as a display/cosmetic profile field, plus 2 visual thumbnails and 1 event copy variant; gameplay multipliers initially identical to avoid extra balance/testing matrices. Full faceless production strategy (voiceover, animation channels, automated workflows, licensing, staff outsourcing) reserved for Phase 2 behind `faceless_strategy_enabled` feature flag. Avoid promises of major path differences for MVP.

---

## PART C — PLATFORMS, METRICS, GAME ECONOMY

### C1. Network definitions

| Network ID | Player mental model | Content types | Strength | Typical monetization | Entry |
|---|---|---|---|---|---|
| `loop` | TikTok-like | short video/challenge | fast discovery, volatile | creator fund fiction + short sponsor | Prologue |
| `tubecast` | YouTube-like | long-form, series, shorts later | evergreen views, engaged audiences | fictional ad RPM + pre-roll sponsor | Act I |
| `vibe` | Instagram-like | photo, reel, story | aesthetics, lifestyle and brand affinity | lifestyle/affiliate sponsors | Act II or III |

Do not connect to live social services. Platform names/art/brand identity must be original. Explain the analogy in help and acquisition copy only if legally cleared; avoid fake representation of real social accounts.

**Per-network persisted metrics**

followers (int64), lifetimeFollowersGained, lifetimeViews, last7dViews, last7dLikes, last7dComments, last7dShares, engagementRateBps, activeAudienceBps, trustScore, nicheAffinityMap, revenueLifetime, revenueLast7d, activePostIds, networkUnlockAt, simLastUpdatedAt.

For clarity, engagement = (likes+comments+shares)/impressions or views over fixed 7-day window, with formula indicated in UI; avoid dividing by followers and accidentally conflating metrics. Use basis points (e.g., 650 = 6.50%). Each network has its own rolling window.

**Global top row**

Total followers across networks (sum, label explicitly), Cash, Skill Points; second row Creator Level, Fame, Trust, Next Goal. A one-tap dropdown shows each network’s followers and why a milestone matters.

### C2. Sponsor/brand/offer gate rules

Offer eligibility is determined for a specific network and includes:

```
eligible = unlockedNetwork
       && followerCount >= minFollowers
       && avgEngagementBps >= minEngagementBps
       && last7dViews >= min7dViews
       && creatorTrust >= minTrust
       && niche in allowedNiches
       && notBlockedByExclusivity
       && sponsorCooldownElapsed
```

For novice friendliness show You need 2,300 more TubeCast followers, Engagement 4.1% / 3.5% required, Post 1 more lifestyle Reel with colored checkmarks, progress bars and term definitions.

**Initial sponsor tiers (BALANCE CANDIDATES)**

| Tier | Network | Followers | 7d views | Engagement | In-game cash reward | Unlock category |
|---|---|---:|---:|---:|---:|---|
| Seed | Loop | 1,000 | 5,000 | 3.0% | $100–$300 | sample creator product |
| Micro | Vibe | 10,000 | 25,000 | 4.0% | $500–$1,500 | lifestyle collaboration |
| Emerging | TubeCast | 25,000 | 50,000 | 3.5% | $1,000–$4,000 | long-form integration |
| Pro | Loop | 100,000 | 500,000 | 5.0% | $4,000–$12,000 | multi-post campaign |
| Major | TubeCast | 1,000,000 | 2,000,000 | 4.0% | $40,000–$150,000 | series + VIP event |
| Luxury | Vibe | 1,000,000 | 1,000,000 | 5.0% | $30,000–$120,000 | luxury brand ambassador |

These are designed values, not real sponsorship market prices. Contracts also have postCount, requiredFormat, deadlineGameDays, maxNegotiations, creativeControl, exclusivity, advance, completionReward, breachPenalty (capped, fair), relationshipEffect, brandFitScore, payoutStatus, fulfilledPostIds and idempotency token. In-game deadlines advance with intentional game days or while in foreground; do not allow real-world inactivity to silently fail active deals.

### C3. Core currencies and progression

| Variable | Type | Gain | Spend / effect | UX label |
|---|---|---|---|---|
| Cash | int64 minor currency units | job, simulated post revenue, deals | gear, home, staff, promotion | `Cash` |
| Skill Points | int32 | level-ups, missions, verified purchases | upgrade skill stat | `Skill Points` |
| Followers | per-network int64 | conversion from views based on content | never normally spent | `Followers` |
| Views | per post int64 | time curve | drives earning and follow conversion | `Views` |
| Likes/comments/shares | per post int64 | ratio to impressions | affect engagement, sponsored gating | `Engagement` |
| Creator XP | int64 | create, fulfill, decisions | level thresholds | `Creator Level` |
| Fame | 0–1000 | career accomplishments | unlock prestige/social circles | `Fame` |
| Audience Trust | 0–100 | fair creative choices, quality/fit | gates, reputation multiplier | `Trust` |
| Energy | 0–100 | rest, food, house bonus | content and job actions | `Energy` |
| Burnout | 0–100 | excessive actions, stressful choices | impacts efficiency if high | `Stress` |
| Relationship | NPC 0–100 | interactions, follow-through | opens scenes/life options | `Relationships` |
| Net Worth | derived | cash+assets-debt | milestone, never spend directly | `Net Worth` |

Cash is fictional gameplay currency; display $ as in-universe visual unit, not redeemable. No paid gems in MVP. Keep skill points and cash pack balances transactionally consistent even offline: validated receipts store grants on trusted backend; local receipt mirror never authoritative.

**Skills (6, one clear effect each)**

- Creativity: idea quality coefficient, +1.2% base quality per rank (cap 20).
- Editing: production quality +1.5% per rank and shorter editing duration (cap).
- On-camera: stronger watch retention for personality-based formats (faceless uses voiceover variant later).
- Storytelling: longer average watch time / evergreen tail boost.
- Negotiation: increases range of sponsor contract offers and shows odds, not guaranteed.
- Marketing: paid promotion cost reductions, cross-platform conversion and discoverability.

All six skills have a visible Before → After preview when spending a point; no hidden changes.

### C4. Simulation math and tuning model

Represent money and counters as integers; no floating-point money. Seed random deterministic PRNG by lifeId + postId + contentVersion for reproducible tests. Use simTime seconds, timeDelta clamped, and server trusted time for premium actions.

Initial illustrative formulas:

```
qualityScore = clamp(0,100, baseNicheFit + editingBonus + gearBonus + creativityBonus + hookBonus - burnoutPenalty)
trendFactor = 0.80..1.45, seeded per post and trend window
platformFit = 0.7..1.25
viralMultiplier = seededWeightedDistribution([0.65, 0.95, 1.15, 2.0, 4.0], weights=[10,45,30,12,3])
expectedViews = baselineReach * (0.4 + qualityScore/100) * platformFit * trendFactor * viralMultiplier
viewsEarned(t) = expectedViews * normalizedCumulativeCurve(network, elapsedHours)
newFollowers = floor(incrementalViews * viewToFollowRate * nicheAffinity * (0.5+trust/200))
postRevenue = eligibleMonetizedViews / 1000 * fictionalNetworkRPM
```

All coefficients externally configurable in versioned local catalog; sanity bounds enforced in code, no negative views/followers unless a clearly authored controversy mechanic. Use incremental deltas, not recomputing and awarding lifetime views every open.

Illustrative normalized CDF shapes:

- Loop short: 50% views in first 2 simulated hours, 85% by 12h, 100% by 36h.
- TubeCast long: 20% by 2h, 45% 12h, 75% 48h, trailing views over several simulated days.
- Vibe: 30% 2h, 70% 12h, 100% 48h.

Other posts gain fewer impressions as new posts compete for feed share; explain Audience fatigue with a friendly icon. Quality and niche affinity matter more than tap count.

**Economy controls / sinks**

Gear ($100–$100k), home ($1k–$3m), job shifts, content production fees, gear upkeep (small), staff commission (sponsor income %), marketing budgets, wardrobe/cosmetics and personal activities. Upgrades require clear income or creation benefits; purely cosmetic items are marked Appearance only. Define 5 archetypal stages and spend/gain targets; test first gear within first session, first home within the first several sessions, celebrity car in late game, etc.

**Offline rules**

- lastSimulationTimestamp updates atomically with credited delta, clamp max free accrual hours=4, Pro=24, configurable.
- No countdown breach, lost relationship, death or irreversible negative event solely due to real-world absence.
- Single source of truth for sim tick and accepted last-sim timestamp; robust to clock rollback. Offline locally estimated and reconciled on cloud sync with capped correction and understandable message.
- Show claim sheet with Views gained, Followers, Cash, Claim; optional 2× cash rewarded ad with limited per-day uses. Reward applied once via server verified callback and transaction ID.

### C5. Equipment, jobs, homes and cosmetics — MVP catalog seed

| ID | Product | Fictional cost | Clear effect | Unlock |
|---|---|---:|---|---|
| gear_phone_1 | Basic Phone | free | base post | start |
| gear_light_1 | Desk Light | 120 | quality +2 | tutorial |
| gear_mic_1 | Clip Mic | 350 | quality +3 | lvl 2 |
| gear_editor_1 | Editing App | 600 | edit time -10% | lvl 2 |
| gear_camera_1 | Creator Camera | 1,500 | quality +7 | lvl 4 |
| gear_pc_1 | Editing Laptop | 2,500 | video capacity +1 | lvl 5 |
| gear_studio_1 | Studio Starter | 9,000 | quality +10 | Act II |
| gear_light_2 | Pro Lighting | 12,000 | quality +5 | Act II |
| gear_camera_2 | Cinema Camera | 35,000 | quality +11 | Act III |
| gear_studio_2 | Pro Production Studio | 95,000 | queue +1 | Act III |

Jobs: Cafe shift $60/turn & energy -10; Delivery shift $120/turn & energy -18; Freelance editing $300/turn & editing XP +8 (unlock lvl 3). Homes: shared room/free; small apartment $3k and monthly upkeep; creator loft $40k; penthouse $500k. Homes improve stress recovery and prestige, not arbitrary platform eligibility. All numbers illustrative.

---

## PART D — IA, UX, VISUALS AND ACCESSIBILITY

### D1. Navigation / screen inventory

Root navigation (five tabs, icon + text labels):

1. **Home** — total across network followers, 3 mini network cards, cash, skill points, profile & next objective; claim offline income; news feed card; prominent Create Post action.
2. **Create** — pick network, format, topic/trend, production options, thumbnail/local media, editor timer, preview, post; content backlog and performance timeline.
3. **Social** — three networks selector, channel profiles, post metrics, follower growth, engagement, collabs, creator NPC list, leaderboard fictional.
4. **Deals** — incoming sponsor proposals, locked eligible offers, negotiations, ongoing contracts, payout receipts; manager unlocked later.
5. **Life** — avatar, home, relationships, energy/burnout, jobs, equipment, skill tree, shop, achievements, Life Archive, settings.

Secondary overlays: Stories Inbox (home or life), Milestone celebration, Post results, Sponsor result, Compare gear, IAP Store, Pro paywall, Daily rewards if ever implemented, achievements share sheet, account, accessibility, privacy settings.

### D2. Child-level clarity without child targeting

- Use labels + icons; never icons only for primary functions.
- Use short, concrete words; explain with ? tooltip: Engagement = how many people react to your posts.
- Show one headline target on Home: Get 700 more Loop followers to unlock your first sponsor. Tap → relevant network.
- Every locked card: requirement, current status progress bar, How to unlock button.
- Each purchase button preview Cost → What changes, with numerical before/after e.g. Edit time 60m → 54m.
- First time each metric appears, one gentle contextual coachmark (dismissible, never blocks core action).
- Visual states: Ready (bright), Locked (neutral), In Progress (progress), Done (check). Do not depend solely on red/green colors.
- Text size scalable, large touch targets >=44×44 pt iOS, 60fps transitions target, respect Reduce Motion, high contrast and VoiceOver semantic labels.
- No less than 4-level deep maze to reach core: start new post <=2 taps from Home; sponsor <=1 tab; stats <=1 tap; skills <=2 taps.
- Consistent terms: Followers, Views, Likes, Engagement, Cash, Skill Points, Trust never use inconsistent fan/subscriber labels without explicit platform wording.

### D3. Visual and animation system

Theme concept: polished creator-pop editorial rather than copying reference; dark navy #10131F, warm surface #1C2230, off-white #F7F8FA, electric violet #8F5BFF, coral #FF6F78, success mint #54D6A1. These are design proposals, validate accessibility and contrast. Base font e.g. Inter or legally licensed equivalent; display font bold/rounded but legible. Use 8pt spacing grid, 12–20px radii, card shadows restrained.

Animations: tap spring 100–180ms, profile progress 250–450ms, follower count rolling 450–850ms, success card 500–900ms, animated confetti (rare and accessible), post chart eased reveal 400ms; navigation transition 180–300ms; paywall hero micro animation optionally Rive (not overly distracting). Respect reduced motion. Static fallback for every animation. Avoid expensive endless particles or shader overdraw in long scrolling lists.

**High-fidelity paywall content structure**

1. Context title anchored in player action (e.g., Your creator studio is ready to grow).
2. Exactly 2–4 benefits in plain language with icons and before/after previews.
3. Product image/hero and clear offer value.
4. App Store fetched localized product price and purchase CTA; no fake strike-through or unsupported savings claim.
5. Always visible close (for optional IAP), restore purchases, legal/privacy links, non-purchase continuation.
6. State for loading, purchase pending, purchase canceled, failed, restored, offline.
7. Do not obscure transaction price beneath animated art; support dynamic large text and VoiceOver.
8. Every paywall design version has a designId + tracking events and can be measured; no fabricated scarcity timers or repeated intrusive nudges.

### D4. Local-only personal media import

- User option Use my video/photo inside thumbnail selection; system PHPicker/photo picker via Flutter plugin. Never upload full media, embedded EXIF/GPS, or thumbnails to backend without separate, explicit opt-in (not in MVP).
- Validate media MIME/type/size; for video only extract local preview thumbnail and metadata needed for card, do not analyze actual video content; performance solely based on gameplay choices.
- Prefer storing a copied bounded compressed thumbnail inside local app sandbox, not large original video; if user asks full local playback, opt-in store copy with clear storage size and cleanup. Default selected source file is not copied into cloud or database; persistent local thumbnails can be deleted at any time.
- On device migration: saved post stats transfer via cloud but media previews do not. Show placeholder Local preview not available on this device, allow re-link.
- Backup (iCloud device backup) is distinct from Firestore cloud sync: document behavior, avoid accidentally backing up private imported media if pledge is local-only on device.
- Prompt Delete all imported media; no transfer to Singular/Firebase analytics; instrumentation only enum custom_media_used=true, never filename/path/raw content.
- If sharing a career card with the user’s photo, require deliberate explicit inclusion in share preview, default off.

### D5. Shareable achievements

Three share-card templates 1080×1920 (Story) / 1080×1080 (Square) / 1200×630 (landscape): First 100K, Million Creator, My Life Ending. Render locally using Flutter RepaintBoundary canvas, watermark Influencer Simulator, optional deep link to public store page, no sign-in required. Share via native iOS UIActivityViewController wrapped by share_plus (or direct native bridge). No public URL containing game save details unless user explicitly opts in.

---

## PART E — MONETIZATION, OFFER DECISION ENGINE AND TESTS

### E1. Foundational principle

Purchase offers should arrive after the player understands and values the benefit, at a relevant positive or decision moment; never interrupt story dialogue, active tap loops or onboarding before first completed post. The hypothesis is contextual relevance, tested against LTV/retention, not a claim that one universal timing maximizes conversion.

**IAP SKU seed and proposed merchandising (all real prices are experiments, not commitments)**

- `pro_lifetime`: non-consumable lifetime entitlement; candidate $9.99; benefits 24h offline accrual, 2 extra active life slots, exclusive cosmetics, optional ad-removal for forced ads only if introduced, +one starter bonus only once. Do not call rewarded ads “removed” unless replacement reward is designed.
- `starter_one_time`: non-consumable one-time grant controlled by backend grant ledger; candidate $2.99; starter gear + cash + SP; ideally only once per account.
- `cash_small` / `cash_medium` / `cash_large`: consumable; candidates $2.99/$5.99/$12.99.
- `sp_small` / `sp_medium`: consumable; candidates $2.99/$6.99.
- `visual_creator_bundle`: optional cosmetic bundle later; do not launch too many SKUs at MVP.

MVP prefer 4 SKUs: pro_lifetime, starter_one_time, cash_small, sp_small; add others once economy data exists. Display actual store prices from StoreKit/RevenueCat product objects.

**Product availability and price governance**

Remote Config can control: offer trigger enablement, offer-to-SKU mapping from already registered SKUs, bundle virtual item counts, copy/illustrations/layout variant ID, entry point, frequency cap, segment/experiment, engagement gating and presentation queue. RevenueCat controls remote Offerings/Packages/paywalls/placements/entitlements and target audiences subject to plan. App Store Connect controls actual charges and product price schedules. Remote Config cannot arbitrarily set a real money price; there is no invisible dynamic personalized Apple charge via arbitrary JSON value. For discounts choose separately configured eligible Apple products/store price schedules; auto-renewing subscription promo APIs apply only if subscriptions eventually exist. Keep backend signed config of grant contents and receipt mapping.

**Store transaction safety**

- Resolve products/prices from Apple/RevenueCat; never hardcode money strings.
- purchase_id dedupe; server validates Apple receipt/transaction via RevenueCat webhook and/or App Store Server API trusted backend; idempotent grant state pending → verified → granted → acknowledged.
- Non-consumable restore across reinstalls; entitlements account-scoped.
- Consumables must be accounted for as an append-only grant ledger; make grants idempotent and prevent tampering.
- Network failures: pending purchase screen then retry; don’t double-grant; don’t show false error after Apple success; restore path; family sharing eligibility per Apple product settings.

### E2. Contextual offer placements and eligibility table

| Placement ID | Context | Offered product hypothesis | Minimum conditions | Trigger frequency cap (starting hypothesis) | Player control |
|---|---|---|---|---|---|
| `shop_entry` | player taps store | full catalog | always | unlimited voluntary | clear close |
| `post_milestone` | first 1k/10k followers celebration ended | starter pack | tutorial done, nonpayer, one time | once per life milestone, max 1 per 24h | dismiss |
| `skill_gate` | user tries skill upgrade with insufficient points | SP small | has seen effect preview, repeat deficit | once per 48h | earn via play alternative |
| `offline_claim` | claim 4h cached revenue | Pro lifetime | after free claim, player has >=2 sessions | once per 7 days | no pressure |
| `life_archive_slots` | requests third simultaneous active life | Pro lifetime | free slots used, clear archive still available | on user action | return to archive |
| `gear_shortfall` | meaningful upgrade with small gap | cash small | <=25% missing currency, chapter >=II | once per 72h | play to earn |
| `brand_deal_success` | completion screen after sponsorship | no default paywall | avoid stacking at emotional peak | none initial | none |
| `end_of_life` | epilogue completed | Pro cosmetic/extra slots | only if value relevant | once per completed life, no forced offer | new life available free |

Global guardrails: no outbound offer during onboarding until first meaningful creation, no more than one unsolicited IAP paywall per session and two per 7 rolling days initial; configurable by cohort, not automatically optimized without retention safeguards. No paywall during accessibility announcements, app restore, in-flight IAP, or when external system sheet visible. Explicit Shop visits exempt unsolicited caps. Prompt suppression immediately after rejection/cancel for configurable cooling period, no repeat after ownership.

**Offer decision engine algorithm**

```
onEvent(event, player, config):
  if config.killSwitch: return noOffer
  candidatePlacements = match(event, context)
  candidates = filter(eligible, notOwned, cooldown, frequency, ageRating, consent, noStoryInterruption)
  rank by [explicit player request > contextual relevance > event priority]
  assign sticky experiment variant (playerId + experimentId)
  if safeUIBoundary && noActiveModal: enqueue first candidate
  return optional presentation (never auto-purchase)
```

All decisions logged locally, impression only when actually visible >=1 second; offer_eligible, offer_queued, offer_impression, offer_dismiss, offer_cta_click, purchase_started, purchase_success, purchase_failed with placementId, sku, productId, contentVersion, designId, variantId, playerAct, sessionIndex. Never log personal media or PII.

**Paywall storyboard concepts**

- A. Starter Milestone: creator avatar high-fiving + Your first 1,000 fans!; Build the next big video / bullets Studio light, $2k cash, 5 Skill Points; primary Get Starter Pack — {storePrice}, secondary Keep creating, close visible.
- B. Pro Offline: hero illustration creator asleep + notification bubble Your posts kept growing; side-by-side Free: 4 hours | Pro: up to 24 hours, plus Extra life slots and cosmetics, CTA {storePrice} one-time; no false promise of infinite growth.
- C. Skill Shortfall: existing editing skill side-by-side from level 3 → 4, Earn 1 Skill Point by completing a mission and optional Buy Skill Pack — {storePrice}. The free path appears as clearly as the paid path.

Motion: 150ms modal slide + 400ms hero subtle loop; no infinite flashy blinking CTA. Screen reader reads product / benefits / real price / cancel.

### E3. Rewarded Ad inventory

- `offline_double`: opt-in after claim, server-side verified, multiplies claimable virtual cash, not purchased money, cap 2/day.
- `editing_boost`: opt-in to shorten one pending post creation timer, cap 3/day.
- `post_boost`: one temporary post promotion (virtual) cap 2/day; not selling real-world views or platform likes.
- `negotiation_retry`: optional once per fictional contract, server validated and in-game preview.

No interstitial/banner/app-open MVP unless analytics warrant cautious experiment. Never show a forced ad after every post. AdMob mediation is SDK adapter-driven; only enable supported iOS networks and required privacy signals. Use AdMob SSV with reward idempotency, ATT consent handling if applicable, UMP and regional privacy controls; ensure contextual ads for users who do not consent where supported.

### E4. Monetization experimentation plan

- Phase 0 instrumentation correctness; ensure payer and ads revenue event dedupe.
- Exp 1: starter_milestone shown after 1k vs after second successful post (non-overlapping control cohort). Main metric D7 revenue per new install with retention/negative feedback guardrails.
- Exp 2: Pro paywall hero static vs Rive animated, identical price/benefits, monitor impressions → purchases and crash/memory.
- Exp 3: free 4h / pro 24h versus free 6h / pro 24h (economy integrity guardrails).
- Exp 4: Visual-only vs gear bundle on explicit shop entry; evaluate payer LTV and retention by source.

Do not test arbitrary discount messaging without legitimate Apple price configuration. Segment by acquisition channel, tenure, engagement and ownership; avoid exploitative targeting based on inferred vulnerability or sensitive personal attributes.

### E5. RevenueCat and Remote Config execution notes

- RevenueCat Offerings, Placements, Paywalls and optional targeting/experiments; verify current plan entitlements and Flutter SDK versions before implementation. RevenueCat Targeting may require Pro/Enterprise plan.
- Firebase Remote Config parameters have sensible local defaults and versioned offer_config_vN JSON. Use one fetch at startup/session boundary or real-time updates as appropriate, not fetch per modal; as of Sep 2026 Remote Config pricing changes above a daily free request tier.
- Buy flows resolved through RevenueCat SDK and iOS StoreKit; App Store real price must match button and confirmation sheet.
- Firebase config must not be used to bypass app review or to secretly alter disclosed purchase behavior.

---

## PART F — TECH STACK AND BACKEND

### F1. Flutter vs Swift vs Kotlin decision record (ADR-001)

- Select Flutter, iOS-first, because game is UI+data+2D asset heavy, with no native 3D engine requirement; one shared codebase reduces Android port cost. Flutter Impeller renders on iOS; measure on real hardware at 60fps target, validate 120Hz where supported.
- SwiftUI/Swift is excellent iOS-native UI but not mechanically reusable as Flutter UI; writing Swift first then rewriting UI in Flutter creates duplicate effort. Native Swift bridge may be used for PhotoPicker, ShareSheet, StoreKit edge cases or custom effects.
- Kotlin is Android-native and not relevant as primary language for iOS-first; Flutter is not Kotlin.
- Reconsider engine if actual interactive 2D scenes or physics dominate (Flame/Unity), with explicit engineering ADR before switching.

### F2. Architecture diagram

```
Flutter Views (Riverpod controllers / go_router)
  ↓ commands / read-only projections
Game Domain (pure Dart)
  |- ContentComposer + PostSimulationEngine + NetworkEconomy
  |- SponsorRules + NegotiationEngine + ContractFulfillment
  |- StoryEngine + FlagGraph + NPCRelationships + LifeEngine
  |- IdleClock + Progression + RewardGrants
  ↓ repository interfaces
Local Drift/SQLite (authoritative normal offline state) ↔ SyncService ↔ Firebase Firestore/Cloud Functions (cloud snapshots, verified grants)
                                                       ↑
RevenueCat <-> Apple StoreKit → verified entitlements → server idempotent grant ledger
AdMob rewarded SSV → verified ad reward ledger
Firebase Analytics / BigQuery + Singular attribution & ad-revenue measurement
Firebase Remote Config → config validation/versioning/experiments
```

### F3. Firebase data model (v2)

```
players/{uid}
  accountCreatedAt, activeLifeId, isAnonymous, displaySettings, privacyConsent,
  entitlementMirror (server-maintained), lastSyncVersion
players/{uid}/lives/{lifeId}
  act, creatorLevel, avatar, seed, contentVersion, currencySnapshot,
  progressionSummary, networkAggregates, relationshipSummary,
  storyFlags, simulationLastAt, revision, status [active|completed|archived]
players/{uid}/lives/{lifeId}/posts/{postId}
  networkId, formatId, topicId, publishedGameAt, qualitySeed,
  perPostStats, thumbnailAssetKey, hasLocalPreview [bool only]
players/{uid}/lives/{lifeId}/contracts/{contractId}
  offerTemplateId, state, terms, fulfillmentIds, rewardGranted
players/{uid}/lifeArchive/{lifeId}
  endingId, highlights, summaryStats, completedAt, immutableStorySnapshot
players/{uid}/verifiedGrants/{grantId}
  source, externalTransactionIdHash, sku, grantUnits, grantedAt, lifeId?, ledgerRevision
players/{uid}/entitlements/{entitlementId}
  state, source, verifiedAt, expiresAt? (server only)
gameContentVersions/{version}
  manifestHash, schema, rolloutStatus
```

Firestore rules deny writes to verifiedGrants/entitlements and price rules. User-private life docs writable under strict field/type/security constraints only if using client-authoritative offline model; safer version: Cloud Functions enforce economy-sensitive writes after sync. Minimize high-frequency document writes: only snapshot on meaningful event/periodic bounded sync, not per simulated view.

### F4. Offline and sync conflict model

- First player creation Firebase Anonymous Auth, link Sign in with Apple later (and optional email with privacy considerations).
- Local lifeState has revision, lastTrustedServerTime, deterministic events with UUID; cloud snapshot includes revision/hash and contentVersion.
- Conflict: detect two devices diverging; never silently overwrite with last write wins. Present Choose save with timestamps and key stats, or define one active device lock; retain losing version in temporary recoverable snapshot for limited time.
- Monetary grants have ledger and entitlement separate from client snapshot; reconcile additive verified entries only once; honor refunds/chargebacks.
- Device-clock changes: time jump capped, compare last server time when online, audit suspicious delta without punitive loss of legitimately earned rewards.
- Archive lives immutable to UI except explicit supported resume state; deterministic migration across app versions; maintain schema migration tests.

### F5. Integrations and startup sequence

1. initialize local database and load cached content/RC defaults,
2. Firebase App initialization, anonymous Auth, Crashlytics,
3. privacy consent UI before personalized/identifier SDK operations as legally required; consent gating for ad requests,
4. init RevenueCat with stable user/app identity, fetch entitlements/offerings async,
5. init Singular attribution/ATT per SDK guidance and consent,
6. preload supported AdMob rewarded placements after consent; fail gracefully,
7. load and validate server content manifest/Remote Config with stale-safe fallback,
8. merge verified grants and local state then enter Home, no blocking startup ad.

Privacy detail: follow Apple ATT and privacy manifest requirements and applicable legal rules; do not trigger ATT purely to trick acceptance. Age rating is determined by actual content and ads, not preference.

### F6. Analytics taxonomy & source of truth

Firebase Analytics = granular gameplay; BigQuery = exploratory cohort and economy queries; Singular = acquisition attribution, paid UA source and selected revenue events only. Select one verified revenue event feed for IAP (RevenueCat integration or verified backend) to avoid duplicates. For ad revenue, Google Mobile Ads impression-level paid event → Singular supported API, and Firebase only if needed with ad_impression_id deduplication. No attachment/real user filenames logged.

Core event catalog:

```
app_first_open, tutorial_start, tutorial_step, tutorial_complete,
network_unlocked, content_composer_open, post_published,
post_view_milestone, post_quality_breakdown_open,
followers_milestone, engagement_tooltip_open,
sponsor_eligibility_seen, sponsor_offer_received, contract_accepted,
contract_rejected, negotiation_started, deal_fulfilled,
gear_viewed, gear_purchased, skill_spent, skill_shortage,
story_event_started, story_choice_made, story_act_complete,
relationship_changed, home_purchased, life_completed, life_archived,
new_life_started, milestone_share_clicked, share_sheet_open,
media_import_open, media_import_used, media_local_deleted,
offer_eligible, offer_impression, offer_dismiss, offer_cta_clicked,
purchase_started, purchase_completed, purchase_failed, purchase_restored,
rewarded_offer_shown, rewarded_started, rewarded_verified, rewarded_granted,
offline_claimed, sync_conflict_detected, cloud_restore_completed
```

Use event param fields life_id hashed/non-sensitive, act, network_id, niche_id, content_format, player_level, source, placement_id, offer_variant, app_version, content_version; avoid exceeding SDK parameter limits, use stable enum strings; analytics schema in docs/analytics_taxonomy.md with contract tests.

### F7. Operational quality targets (provisional)

- No crash during complete tutorial on supported launch iPhones; crash-free users >=99.5% target, monitor actual baseline.
- 60fps target on supported hardware for non-video scenes; frame timeline tracked in performance profiling.
- Cold start target <=3 seconds on representative midrange recent iPhone in release, excluding required consent/login; validate empirically.
- Save integrity: no lost verified purchases, no duplicated grants, no silent cloud overwrite, migration coverage.
- Offline: core production, story and locally earned currency remain usable without network; IAP/ads/remote sync not available offline, clearly communicated.
- App Store Sandbox/TestFlight IAP, refunds, restore, interrupted flow, consent, review account tested.

---

## PART G — ASSET PIPELINE AND GENERATIVE AI OPTIONS

### G1. Asset strategy and comparative options

1. Recommended hybrid: create asset bible + reference sheets using Gemini image API or assisted image generation, human review and crop/retouch, export optimized WebP/PNG; vector UI and chart components authored directly in Flutter; Rive animations authored as actual .riv files by designer/animator or built with Flutter primitives.
2. Automated batch generation: user provides Gemini API key to a local development-time pipeline, not shipped in app; script generates draft asset manifests, runs iterative prompt packs, QA checks and human approval. Cursor/Claude Code can write/orchestrate scripts but cannot create visual assets without executing an available generation tool/API and having valid credentials/quota.
3. Fully manual: use licensed 2D packs and freelance artist for coherent characters/backgrounds, custom UI/icons. Best consistency if budget exists; more coordination effort.
4. Never depend on dynamic Gemini image generation for every player post in MVP: latency/cost, moderation, offline failure, inconsistent visuals and privacy considerations. Runtime post thumbnails should use template composition and curated asset library.

**Preferred Gemini family (verify availability immediately before implementation)**

Per Google Gemini image generation docs, Nano Banana 2 / Gemini 3.1 Flash Image supports strong general image generation and reference consistency; Gemini 3 Pro Image for difficult complex art direction; lower-cost lite variant for mass ideation. Do not select legacy deprecated Imagen models. Model names are configs not hard-coded; verify pricing, output license, rate limits and project-region availability. Generated images may contain SynthID; don’t strip watermarks/metadata contrary to platform terms.

**Asset classes and estimates for MVP**

| Class | Count target | Source | Optimization |
|---|---:|---|---|
| Avatar base bodies/faces | 6–10 presets + layered variants | original AI-assisted drafts + manual layer cleanup | transparent PNG/WebP |
| NPC portraits | 8–12 characters × 2 expressions | consistent reference sheets | 512–1024px WebP |
| Backgrounds | 6–8 rooms/locations × 2 progress tiers | AI-assisted with art direction | 16:9/portrait crops WebP |
| Equipment | 10–15 icons + 5 large showcase renderings | AI/vector | SVG/PNG/WebP |
| Social post templates | 12–18 reusable layout styles | Flutter components & abstract art | local composition |
| Story scene art | 12–20 key scenes | AI-assisted | WebP 9:16 / 4:5 |
| App UI icons | 35–50 simple semantic icons | licensed outline icon family | Flutter vector |
| Milestone/share art | 6 variants | Flutter compositing + original assets | rendered locally |
| Animations | 6–10 micro-interactions | Flutter implicit/tween, optional Rive | no huge MP4 loops |

**Mandatory visual consistency / QA pipeline**

prompts/assets_bible.md includes palette, line weight, eye style, perspective, lighting, fictional brand safety, age range, transparent background rules, negative prompt, target canvas size. Generation pipeline: (1) character model sheet approved, (2) pose/action sprites consistent, (3) naming, (4) crop/mask/edit, (5) image hash duplicate check, (6) manual inspection, (7) license/provenance log, (8) compressed export, (9) manifest mapping keys, (10) app screenshot QA. Never expose Gemini API key in client/app assets or Git. Asset pipeline functions generate_drafts, validate_asset_dimensions, dedupe_assets, export_manifest, preview_asset_gallery can be built using Python/CLI scripts. All game references must resolve a local fallback.

### G2. Generative asset prompt template

```
Asset type: {NPC portrait | scene background | equipment object}
Style bible version: creatorpop-v1
Palette: deep navy, violet, coral, mint; modern readable cartoon / editorial 2D illustration
Subject: {detailed original fictional character/object/location}
Pose, expression: {requirements}
Continuity reference: {approved canonical character sheet}
Composition: {camera framing, safe text space, no text baked in}
Output: {transparent PNG | 4:5 background | 9:16 scene}, high-resolution, no logos
Restrictions: no real influencers, no trademark logos, no imitation of existing game designs
QA: identity consistency, anatomy/hands, clean silhouette, no illegible baked text, correct file naming
```

---

## PART H — DATA MODELS, CODE ORGANIZATION AND IMPLEMENTATION GATES

### H1. Suggested monorepo

```
influencer-simulator/
  README.md
  docs/
    GDD_MASTER_v2.md
    ADR/001_flutter_ios_first.md
    economy_balance.md
    story_graphs.md
    analytics_taxonomy.md
    monetization_policy.md
    privacy_and_permissions.md
    qa_checklist.md
  app/
    lib/
      app/ (bootstrap, routing, themes, localization)
      core/ (errors, clocks, RNG, telemetry, feature flags, IDs)
      domain/ (pure models, engines, commands, reducers)
      data/ (Drift repositories, Firebase adapters, catalogs)
      features/
        onboarding/ home/ create/ networks/ deals/ life/
        stories/ archive/ share/ store/ settings/
      integrations/ (firebase, singular, ads, revenuecat, platform)
    assets/
    test/ integration_test/
  game_content/
    schemas/
    balance/ (network_rules, economy, careers, equipment, homes)
    narrative/ (acts, characters, events, endings)
    deals/ (brands, products, negotiation rules)
    localization/
  tools/
    content_validator/
    asset_pipeline/
    economy_simulator/
  .github/workflows/
```

### H2. Minimal essential DTO schemas (illustrative)

```
PlayerAccount {uid, activeLifeId, entitlementIds, createdAt, version}
LifeState {lifeId, seed, status, actId, creatorXP, cashMinor,
           skillPoints, skills, networkStates, gearIds, homeId,
           npcRelationships, narrativeFlags, availableMissions,
           simTimestamp, contentVersion, revision}
NetworkState {networkId, unlocked, followers, viewsTotal,
              engagementRateBps, trustScore, revenueMinor, posts}
ContentPost {postId, lifeId, networkId, formatId, topicId, qualitySeed,
             createdGameAt, publishedGameAt, views, likes, comments,
             shares, followersGained, revenueMinor, mediaLocalKey?}
SponsorContract {contractId, sponsorId, requiredNetworkId,
                 minFollowers, minEngagementBps, min7dViews,
                 requiredPosts, fulfilledPostIds, rewardMinor,
                 dueAtGameTime, status, payoutGrantId?}
StoryEvent {eventId, trigger, conditions, lines[], choices[],
            oncePerLife, consequenceFlags, nextEventRefs}
LifeArchive {lifeId, endingId, completionStats, finalChoices,
             startTime, endTime, archiveImmutableVersion}
StorePlacement {placementId, eligibleConditions, skuIds[],
                contentVariant, maxFrequency, cooldown, enabled}
```

Use versioned JSON Schema for all content, deterministic toJson/fromJson, migrations and null-safe handling; currency amounts are integer minor units, no floating-point money. Schemas and repository interfaces come before UI wiring.

### H3. Coding standards

- Dart analyzer strict mode; null safety; Riverpod state not business rules; pure domain engines and repository interfaces.
- Domain tests must not import Flutter/Firebase to keep speed and determinism.
- Localization keys in English even if initial copy English; copy never embedded across random widgets.
- Feature flags have safe defaults & kill switches; no permissionless server control of price/verification.
- No mock UI pretending live calculations when connected to production services; fixtures for tests/demo tagged.
- Build/release secrets in CI environment; never in repository. Security rules unit tests.
- All ContentPost economic rewards idempotent; retry-safe state transitions.

### H4. Milestone-by-milestone acceptance gates

- **M0 — foundation:** app launches on iOS simulator/device, home shell in theme, domain layer, all icons/assets resolving, routing, CI/test. Acceptance: clean flutter analyze, baseline unit tests.
- **M1 — playable core:** avatar/niche, first network, content creation, deterministic post curve, XP, first equipment purchase, SQLite save/restart. Acceptance: all increments once, first post 1 minute guided, migration test.
- **M2 — multi-network:** TubeCast/Vibe unlock, per-platform dashboards, eligible brand rules, engagement tooltips, chart and post list. Acceptance: locked offers show explainable requirements, platform progress independent.
- **M3 — narrative/life:** 4 acts, event scripts and choices, relationships, homes, endings, archive/new life. Acceptance: all endings automated reachable, one-life repeat replay safe, no stuck storyline.
- **M4 — services:** Firebase Auth/sync/security, Remote Config defaults/versioning, Crashlytics/Analytics/BigQuery export, Singular iOS SDK. Acceptance: device 2 sync conflict behavior proven, analytics verified with debug tools.
- **M5 — monetization:** AdMob rewarded + SSV, RevenueCat/App Store products, entitlements, transactional wallet, offer decision engine/visual paywalls. Acceptance: sandbox success/cancel/refund/restore tested and no duplicate grants.
- **M6 — UX polish:** animations, local media imports, share cards, accessibility, Reduce Motion, iOS performance, app privacy disclosure. Acceptance: QA scripted tests passed on minimum supported device and latest iPhone.
- **M7 — TestFlight soft launch:** product analytics, A/B baseline, tuning, asset QA, rating/consent compliance. Acceptance: data quality checks, no blockers, balanced progression, store review notes complete.

### H5. Playtesting / design simulation tests

- 10,000 seeded simulated lives to analyze milestone distribution and dead ends.
- 30 archetypes: high-trust quality, high-volume trends, rich sponsor path, lifestyle, romance, all-on-one-network, low-engagement, long absent offline, premium purchase, free player; each must finish some ending without paying.
- 0/negative currency, 64-bit overflow at late-game, rounding, duplicate collect, purchase restore, clock rollback, across-devices stale saves, asset missing, deleting imported image, denied permissions, Apple sandbox cancellation, offer fatigue caps, VoiceOver screen controls.
- UX research: 5–8 first-time players at minimum, ask them to find Create, sponsor requirements, what a skill point changes, difference between network followers and total fans. Do not claim tested unless actually observed.

---

## PART I — GAME CONTENT / REMOTE CONFIG EXAMPLES

### I1. Sponsor template example

```json
{
  "id":"brand_neonpop_loop_001", "sponsorName":"NeonPop", "nicheTags":["lifestyle","comedy"],
  "networkId":"loop", "minFollowers":10000, "minLast7dViews":25000,
  "minEngagementBps":400, "minTrust":45, "contentFormat":"short",
  "rewardCashMinor":80000, "requiredPostCount":1,
  "deadlineGameDays":3, "creativeControl":false,
  "affinityEffectOnCompletion":5, "storyHookId":"S01",
  "contentVersion":"2.0.0"
}
```

### I2. Narrative example

```json
{
  "id":"first_sponsor_choice", "act":"II", "oncePerLife":true,
  "trigger":{"event":"eligible_sponsor_seen","minTimes":1},
  "speaker":"Avery", "titleKey":"story.sponsor.title",
  "linesKeys":["story.sponsor.line1","story.sponsor.line2"],
  "choices":[
    {"id":"accept", "labelKey":"story.sponsor.accept", "preview":{"cash":"up","trust":"risk"}, "effects":{"relationshipAvery":5,"integrity":-3}, "deferredFlags":["brand_sponsor_accepted"]},
    {"id":"decline", "labelKey":"story.sponsor.decline", "preview":{"trust":"up"}, "effects":{"audienceTrust":7}, "deferredFlags":["brand_sponsor_declined"]}
  ],
  "fallbackEventId":"story_next_open_goal", "version":1
}
```

### I3. Offer config example (illustrative—not real store pricing)

```json
{
  "schemaVersion":3,
  "global":{"enabled":true,"maxUnsolicitedPerSession":1,"maxUnsolicitedPer7d":2},
  "placements":{
    "post_milestone":{"enabled":true,"trigger":"first_1000_followers","sku":"starter_one_time","minSessions":1,"cooldownHours":24,"designId":"starter_a"},
    "offline_claim":{"enabled":true,"trigger":"after_regular_offline_claim","sku":"pro_lifetime","minSessions":2,"cooldownHours":168,"designId":"pro_creator_v1"},
    "skill_gate":{"enabled":true,"trigger":"user_requested_skill_upgrade","sku":"sp_small","cooldownHours":48,"designId":"skill_shortfall_v1"}
  },
  "economy":{"freeOfflineHours":4,"proOfflineHours":24},
  "purchasePriceNotice":"Displayed prices always fetched from StoreKit / RevenueCat, not this config"
}
```

### I4. First session tutorial — complete screen/copy beat sheet

1. Splash 1 sec / start Become the Creator Everyone Knows / Start My Story.
2. Profile: What's your creator name? / recommended random generated handle editable / Continue.
3. Persona card: 3 simple niches: Comedy, Gaming, Lifestyle (different content topics only at first; all balanced).
4. Avatar: basic starter portrait variants, Looks Good.
5. Small bedroom, cheap smartphone, subtle camera wiggle, Maya text Every famous creator started with a first post. / Let's make yours.
6. Tap Create Post; select highlighted First Challenge; editing score 38/100 with Make Post.
7. 1–2 sec progress, Published! follower roll 0 → 17, sample positive comment.
8. Coachmark Followers are people who want to see your next post.
9. Home goal Get 100 Followers; suggested Make another video; no popups.
10. Second video + small monetized income/job; You can upgrade your light to make better posts; show before/after.
11. Maya presents story V01 and 3 choices. In-app tutorial complete, clear Next Goal, optional story skip/continue.
12. After first earned significant milestone, one optional offer eligibility evaluation, but do not preempt celebration.

### I5. Basic UI wireframes in textual form

```
Home:
[Top header: avatar | Cash $123 | Skill Points 3]
[TOTAL FOLLOWERS 12,430 ↑; Next Goal 15K]
[Loop 8.7K 6.2% | TubeCast 2.1K 4.3% | Vibe 1.6K 5.1%]
[BIG BUTTON: Create Post]
[Active post chart / Recent achievements / Sponsor invite badge / Story inbox]
[Bottom: Home | Create | Social | Deals | Life]
```

Post composer: Network → Type → Trend → Hook → Equipment → Preview quality + expected reach range → [Publish]; optional Use My Photo/Video file picker affects image preview only.

Deal: Brand cover → network badge → expected cash → 3 checkbox requirements + engagement progress bar → contract obligations → Accept / Negotiate / Decline.

End life: Final photo + Ending title + stats cards + choices that shaped you → Archive Life / Share Ending / New Life.

---

## PART J — MASTER PROMPT FOR CURSOR / CLAUDE CODE / CODEX

> Paste the following section **as the primary coding task**, together with this entire file in your repository under `docs/GDD_MASTER_v2.md`. Do not interpret it as an instruction to skip review/gates. The agent must report what is implemented versus scaffolded after each milestone.

**MASTER IMPLEMENTATION PROMPT — START**

You are the lead mobile game architect, Flutter engineer, narrative systems designer, monetization engineer, and QA lead for Influencer Simulator: Zero to Fame. Build an original iOS-first Flutter idle life simulator with Android-compatible architecture using the complete GDD/TDD provided in docs/GDD_MASTER_v2.md as source of truth. This is a commercially intended game, not a static mockup or clone of any referenced app.

**Working process (mandatory)**

1. Read the entire document and summarize architecture decisions and open configuration inputs in docs/IMPLEMENTATION_PLAN.md.
2. Inspect current repository and dependencies before changing anything; do not replace existing working features blindly.
3. Deliver one milestone at a time in the order M0→M7; for first invocation implement M0 then M1 only unless explicitly instructed otherwise.
4. Each milestone: (a) create task breakdown, (b) implement code, (c) add tests, (d) run flutter analyze, flutter test, build/run on iOS simulator if environment supports, (e) report concrete changed files and blockers, (f) only then proceed with approval or next instruction.
5. Never hardcode purchase prices, backend secrets, Apple product IDs, real user media, or fake telemetry. Use environment placeholders and README integration steps until actual credentials exist.
6. Core simulation engines are pure, deterministic, unit-testable Dart. UI uses Riverpod, go_router and localization keys. Data persistence Drift SQLite; external SDK boundaries use interfaces so app works offline/mock dev mode.
7. Always follow documented economy constraints: per-network state, independent sponsor requirements, idempotent rewards, clear metric explanations, deliberate game-day deadlines, fair offline progression, choices with consequences, multiple endings/archive.
8. Add verified analytics only when Firebase/Singular are configured. Do not silently send personal imported photos/videos to any service.
9. All IAP SKUs require store/RevenueCat configuration and backend validation; Firebase Remote Config determines offer experience not actual Apple billing prices. Never award premium virtual currency twice.
10. Shipping UX is portrait-first, polished, accessible, 60fps target, with animations that respect Reduce Motion, no mandatory ads and no disruptive store popups during dialogue.

**Architecture to establish**

- Flutter + Dart stable, Riverpod, go_router, Drift/SQLite; test packages and lints.
- domain models: PlayerAccount, LifeState, NetworkState, ContentPost, Skills, PostSimulationEngine, SponsorContract, StoryEvent, NPCRelationship, LifeArchive, RewardLedger, OfferPlacement.
- Typed repository interfaces, local data implementations, Firebase adapters separated by feature flags.
- Content files under game_content/, schemas + validators; all content IDs stable and versioned.
- Deterministic seeded content and idle simulation, with no 2× crediting.
- Story engine supporting requirements, outcome previews, flags, deferred callbacks, endings, fallback route.
- Distinct per-platform followers/engagement and sponsor eligibility, with explicit UI progress indicators.
- Life Archive enables finish, save, and create a new life; account entitlements survive restart.

**First milestone playable vertical slice specification**

M1: user names avatar, selects 1 of 3 niches, sees Home with three locked/unlocked network mini cards, creates a Loop post (choose topic, hook, gear), watches chart and follower counters update, receives cash and XP, buys a desk light showing before/after production benefit, sees clear next objective, closes/reopens app and state persists correctly. Provide seeded sample assets as simple placeholders and a clear image manifest; do not claim placeholders are finished original production art. The first event V01 stub may be hooked, but don’t falsely declare full branching narrative implemented.

**Required tests at M1**

- deterministic same seed → same post output;
- no negative views/followers/cash under normal operations;
- claim income twice → second claim grants 0;
- equipment purchase insufficient cash fails without state mutation;
- persisted save migration round-trip;
- platform independence (publishing Loop does not silently increase TubeCast unless cross-post rule explicitly applied);
- UI onboarding first published post reachable; state visible after restart.

**Output format for each engineering step**

1. Implemented (real files and behavior)
2. Tested (commands and actual outcomes)
3. Not implemented yet (no pretending)
4. Credentials/configuration required (e.g. Firebase plist, Apple/RevenueCat IDs)
5. Risks or open design decisions
6. Next milestone with 3–7 concrete acceptance criteria.

Stop and ask for missing secrets rather than inventing them, but build mock interfaces and testable code without secrets. Build no backend-generated image service for player runtime. Use Gemini/AI asset scripts only as optional offline development tools and keep all API calls on secured developer environment.

**MASTER IMPLEMENTATION PROMPT — END**

---

## PART K — LAUNCH, RISK, GROWTH & SOURCE REFERENCES

### K1. iOS-first launch and compliance

- Finalize original title, artwork, app icon and description with trademark/ASO clearance.
- Apple Paid Apps agreement, App Store Connect products, age rating questionnaire, Privacy Nutrition Labels, privacy policy, terms, support and deletion/export procedures.
- ATT permission / SKAdNetwork as required for ads attribution, consent via UMP and data disclosures. App should function if tracking denied.
- Account deletion/account linking flow appropriate to platform policy; anonymized account and local-only guest play.
- Advertising policies: no deceptive rewarded prompts or disruptive forced interstitials; never mix simulated in-game sponsor content with real ads in misleading way.
- UGC personal media remains device local; if user-generated imagery can be inappropriate, it is not published to other players, reducing moderation scope (but sharing still user-directed, review platform policies).
- Legal/use: no real official YouTube/TikTok/Instagram logos, real influencer faces, real brand deals without appropriate rights, no copying competitor scripts or distinctive visuals.
- Accessibility: VoiceOver, Dynamic Type, Reduce Motion, contrast, no colour-only status; localization-ready.

### K2. Source links / verification trail (read November 2026)

1. Flutter Impeller: https://docs.flutter.dev/perf/impeller
2. Apple IAP guidelines: https://developer.apple.com/app-store/review/guidelines/
3. Apple IAP price control: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/schedule-price-changes-for-in-app-purchases/
4. RevenueCat Offerings: https://www.revenuecat.com/docs/offerings/overview
5. RevenueCat Paywalls: https://www.revenuecat.com/docs/tools/paywalls
6. RevenueCat Placements: https://www.revenuecat.com/docs/tools/targeting/placements
7. RevenueCat Targeting: https://www.revenuecat.com/docs/tools/targeting
8. Firebase Remote Config Flutter: https://firebase.google.com/docs/remote-config/flutter/get-started
9. Firebase Remote Config pricing: https://firebase.google.com/docs/remote-config/pricing
10. Gemini API image generation: https://ai.google.dev/gemini-api/docs/image-generation
11. Gemini model catalog/pricing: https://ai.google.dev/gemini-api/docs/models and https://ai.google.dev/gemini-api/docs/pricing
12. Apple Photos picker: https://developer.apple.com/documentation/PhotoKit/selecting-photos-and-videos-in-ios
13. Apple share sheet: https://developer.apple.com/documentation/uikit/uiactivityviewcontroller
14. Source competitor listing: https://apps.apple.com/ye/app/music-star-idle-life-simulator/id6796768752
15. Apple subscription practices (only relevant for future subscriptions): https://developer.apple.com/app-store/subscriptions/

### K3. Explicit unresolved owner inputs / non-blocking defaults

- Confirm title and domain rights: provisional Influencer Simulator: Zero to Fame.
- Niche presets: Comedy, Gaming, Lifestyle initially; add Education/Beauty/Tech later.
- iOS minimum deployment version: let tooling and active SDK matrix decide; provisional modern iOS supported by active Flutter packages, do not assume a specific min version without checking.
- Pro grant bundle values to tune, final IAP SKUs and entitlement rules pending App Store Connect setup.
- Character/illustration art direction needs approval of one 1-page style bible and three generated test assets before batch generation.
- Content saturation and follower pacing should be tested with seeds, not finalized by intuition.
- App review disclosures and SDK Data Safety checks after actual packages installed.

### K4. Definition of done for overall MVP

- Onboarding instructive and skippable on replay; users find three networks and understand differing sponsor criteria.
- At least 20 complete story events with callbacks, four acts and at least three reachable endings; each path testable, no stuck gates.
- Character has homes/relationships, current life completion and archive/new life; IAP entitlements remain across lives.
- Post timelines and stats persist across app restart and offline sync; optional personal photo/video preview stays local.
- RevenueCat IAP, AdMob rewarded, Firebase, Singular iOS attribution, Analytics/BigQuery and crash reporting configured and verified on TestFlight before advertising spend.
- All offers have placement gating, remote disable/cap, close/restore, verified real Apple prices, and event data.
- Reliable, accessible, polished UI and coherent original assets; no policy-violating forced monetization or content copying.
- Change one content/economy JSON file and see a correctly validated content tweak without editing view widget code.
- Source is organized for Android adapter work after iOS soft launch, not tied to SwiftUI.
