---
name: naplet-paywall-patterns
description: Use this skill ALWAYS before creating, modifying, or wiring any paywall trigger in the Naplet project. This skill defines when paywalls should fire, when they should NOT, the structure of the Founders offer, copy patterns proven to convert, RevenueCat validation requirements, and how to avoid common monetization mistakes that cost conversion. Trigger this skill whenever editing files in Features/Paywall/, PaywallTrigger.swift, PaywallViewModel.swift, or implementing any new gate that requires subscription.
---

# Naplet Paywall Patterns

The Naplet had 0 conversions despite 46 active users for one main reason: the paywall is either invisible or appears at the wrong moments. This skill defines the corrected approach.

## Founders Offer Structure

Until 22/07/2026 (or extended date):

| Plan | Price BRL | Comparison |
|---|---|---|
| Founders Annual | R$59,90/ano | 48% less than Napper (R$114,90) |
| Regular Annual | R$89,90/ano | Default after Founders period |
| Regular Monthly | R$12,90/mês | Entry option |

Trial: 14 days, all features unlocked, no credit card required initially.

## When to Show Paywall (TIMING)

### Always show

1. **End of onboarding (tela 12, antes de Completion).** Pico de motivação. Maior alavanca isolada. **Não pular.**
2. **PDF generation attempt (free user).** Modal: "Relatórios para o pediatra são Premium."
3. **Second baby attempt (free user).** Modal: "Acompanhe quantos bebês quiser com Premium."
4. **Historical data beyond 7 days (free user).** Modal: "Veja todo o histórico de {nome do bebê} com Premium."
5. **5th sleep record in a single day (engagement signal).** Soft non-blocking modal: "Você está usando bastante o Naplet, conheça o Premium."
6. **Settings screen (permanent card).** Card with countdown of Founders offer.
7. **Chat IA after 5th message in a month (free user).** Hard gate: "Continue com Chat IA ilimitado no Premium."

### Never show

- During first 30 seconds of app use
- Immediately after error states
- During active sleep tracking (timer running)
- On launch if user has unfinished onboarding
- More than once per 48h after a recent skip (unless triggered by paid feature attempt)
- During grief moments (no baby data, just lost a baby flag)

## Copy Patterns

### What works

- **Use the baby's name.** "O sono da Alice começa agora", not "Plano Premium".
- **Anchor against Napper.** "Napper cobra R$114,90/ano. Naplet cobra R$59,90." Direct comparison.
- **Show savings concretely.** "Economize R$30/ano" beats "33% OFF".
- **Time pressure with real dates.** "Oferta válida até 22 de julho" not "por tempo limitado".
- **Verb of gain on CTA.** "Começar 14 dias grátis" not "Assinar agora".
- **Trial timeline visual.** Hoje → Dia 12 lembrete → Dia 14 cobra. Reduce anxiety.
- **Outcome over feature.** "Noites tranquilas" not "Histórico ilimitado".

### What kills conversion

- Generic "Unlock Premium"
- Feature list without context
- Vague pricing ("a partir de...")
- Hidden trial terms
- Multiple plans visible at once without clear primary
- "Save" or "Subscribe" as primary CTA verbs
- Showing pricing before establishing value
- Long lists of features (more than 4 in primary view)

## Paywall Visual Hierarchy

From top to bottom on any paywall screen:

1. **Emotional headline** with baby's name (largest type)
2. **Subhead** explaining the outcome (not feature)
3. **4 benefit bullets** max, with SF Symbols, focused on outcomes
4. **Price card** with Founders highlighted, regular price struck-through
5. **Comparison anchor** ("48% menos que Napper")
6. **Trial timeline visual** (3 dots, 3 labels)
7. **Primary CTA** (large, hero gradient)
8. **Secondary action** (discreet text link "Continuar grátis")
9. **Trust footer**: "Cancele quando quiser • Sem cartão para começar • Preço travado"
10. **Legal links** in tiny text

## RevenueCat Wiring

### Before any paywall change

```swift
#if DEBUG
print("[RC] modo: \(Purchases.shared.isSandbox ? "SANDBOX" : "PRODUCTION")")
#endif
```

This must show `PRODUCTION` in release builds. If it shows `SANDBOX`, **stop and fix**.

### Offering structure

```
OFFERING: "default"
├── Package: monthly → naplet_premium_monthly
└── Package: annual → naplet_premium_annual

OFFERING: "founders" (active until 22/07/2026)
└── Package: annual → naplet_founders_annual
```

### Selecting the right offering

```swift
func getCurrentOffering() async -> Offering? {
    let offerings = try? await Purchases.shared.offerings()
    
    if isFoundersPeriodActive() {
        return offerings?.offering(identifier: "founders") 
            ?? offerings?.current
    }
    
    return offerings?.current
}
```

### Purchase flow

```swift
do {
    let result = try await Purchases.shared.purchase(package: pkg)
    
    if !result.userCancelled {
        // Track success
        PostHog.shared.capture("paywall_purchase_completed", properties: [
            "package": pkg.identifier,
            "offering": offering.identifier,
            "price": pkg.localizedPriceString
        ])
        return true
    } else {
        // Track cancellation
        PostHog.shared.capture("paywall_purchase_cancelled")
    }
} catch {
    // Track failure
    PostHog.shared.capture("paywall_purchase_failed", properties: [
        "error": error.localizedDescription
    ])
}
```

## After First Refusal

Don't show the same paywall again immediately. Show a softer "downgrade offer":

1. "Que tal experimentar grátis primeiro?" (reinforce trial)
2. Monthly option more prominent
3. If refused again, wait 48h before next attempt

## Required Elements (legal and UX)

Every paywall **must** have:

- Restore Purchases button (visible, not hidden in menu)
- Terms of Service link
- Privacy Policy link
- Clear subscription terms (auto-renews, can be cancelled in App Store)

Apple rejects apps without these. Don't forget.

## Analytics (PostHog)

Every paywall interaction generates events:

- `paywall_shown` with `{trigger, offering}`
- `paywall_dismissed` with `{trigger, time_on_screen}`
- `paywall_cta_tapped` with `{trigger, package}`
- `paywall_purchase_completed` with `{package, price, trial}`
- `paywall_purchase_failed` with `{error}`
- `paywall_purchase_cancelled` with `{trigger}`
- `paywall_restore_tapped`

Funnel without these is invisible. Don't ship a paywall change without analytics.

## A/B Testing Readiness

For future iteration, design paywalls so that:

- Copy is in strings file (easy to swap)
- Visual variants can be toggled by feature flag
- Price ordering is configurable
- CTA text is variable

Don't hardcode anything you might want to test later.

## Common Mistakes to Avoid

1. **Showing paywall during onboarding before value is delivered.** Wait for the end.
2. **Multiple plans at once with equal visual weight.** Have one primary.
3. **Hiding the skip button or making it invisible.** Apple may reject. Be discreet but visible.
4. **Forgetting Restore Purchases.** Apple rejection.
5. **Trial without clear timeline.** Causes refunds and complaints.
6. **Founders countdown that goes negative.** Always check expiration.
7. **Disabling the offering before the date hits.** Causes empty paywall.

## Validation Checklist (before any release)

- [ ] RevenueCat in PRODUCTION confirmed via runtime log
- [ ] All 7 triggers fire correctly (manual test each)
- [ ] Purchase flow completes in sandbox
- [ ] Restore Purchases works
- [ ] Founders countdown displays correctly
- [ ] All copy localized (PT-BR, EN, ES)
- [ ] Analytics events firing (verify in PostHog dashboard)
- [ ] Smoke test passes with sandbox account
