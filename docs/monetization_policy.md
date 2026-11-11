# Monetization policy

**M1 status:** no monetization exists in code. There are no ads, no purchases, no paywalls and no
price strings. Gameplay cash is fictional and formatted by `Format.cash`, and no real money can buy it.

Binding rules for M5 (from GDD Part E):

1. Real prices come only from StoreKit/RevenueCat product objects. They are never hardcoded and never set by Remote Config.
2. Every grant is idempotent (`pending → verified → granted → acknowledged`) on a server ledger, so a purchase ID can never grant twice. Restores work across reinstalls.
3. Offers appear only at safe boundaries. Never during onboarding before the first post, during story dialogue, during in-flight IAP or over system sheets. At most one unsolicited paywall per session and two per 7 days, with suppression after a dismissal.
4. Each paywall has a visible close, restore, legal links and a free path at equal prominence. There are no fake timers, strike-throughs or scarcity claims.
5. Rewarded ads are opt-in, capped and verified server-side (SSV). There are no interstitials, banners or app-open ads in the MVP.
6. No ending, story branch or core progression can be bought exclusively. Every balance archetype must finish without paying (balance tests enforce the free path).
7. Targeting never uses sensitive or inferred-vulnerability attributes.
