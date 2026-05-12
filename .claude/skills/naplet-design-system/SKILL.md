---
name: naplet-design-system
description: Use this skill ALWAYS before creating any new UI in the Naplet project, or before modifying any existing View. The Naplet has a strict dark theme aesthetic with purple/magenta accents that must be preserved for premium perception. This skill defines the authorized color palette (NapletColors), typography rules, spacing constants, component reuse guidelines, animation patterns, glassmorphism specifications, and SF Symbols usage. Trigger this skill whenever editing files in Features/*/Views or creating new SwiftUI components.
---

# Naplet Design System

The Naplet app sells "premium" at R$59,90 to R$89,90. Every UI choice must reinforce that perception. Generic or inconsistent UI undermines pricing power.

## Color Palette (NapletColors)

**Use only these named colors.** Never hardcode hex values inside Views.

### Backgrounds
- `NapletColors.background` = `#0D0B1E` (primary dark)
- `NapletColors.backgroundSecondary` = `#1A1730`
- `NapletColors.backgroundTertiary` = `#252142`
- `NapletColors.backgroundCard` = `#1E1B33` (default card background)

### Accents
- `NapletColors.primaryPurple` = `#8B5CF6` (main brand)
- `NapletColors.primaryPink` = `#EC4899` (secondary brand)
- `NapletColors.primaryBlue` = `#3B82F6`
- `NapletColors.primaryCyan` = `#06B6D4`

### Text
- `NapletColors.textPrimary` = `#FFFFFF` (titles, primary content)
- `NapletColors.textSecondary` = `#A1A1AA` (descriptions, labels)
- `NapletColors.textMuted` = `#71717A` (helper text, timestamps)

### Status
- `NapletColors.success` = `#22C55E` (active, healthy)
- `NapletColors.warning` = `#F59E0B` (alerts, countdown)
- `NapletColors.error` = `#EF4444` (errors only, never decorative)
- `NapletColors.info` = `#3B82F6`

### Sleep-specific
- `NapletColors.sleepActive` = `#818CF8`
- `NapletColors.napColor` = `#A78BFA`
- `NapletColors.awakeColor` = `#FCD34D`

## Gradients

The hero gradient (use for premium moments, paywall hero, onboarding completion):

```swift
LinearGradient(
    colors: [NapletColors.primaryPurple, NapletColors.primaryPink],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

## Typography

Default to system fonts. Never import custom fonts.

| Use | Font | Size | Weight |
|---|---|---|---|
| Hero title | SF Pro Display | 34pt | .bold |
| Section title | SF Pro Display | 24pt | .bold |
| Card title | SF Pro Display | 18pt | .semibold |
| Body | SF Pro Text | 17pt | .regular |
| Description | SF Pro Text | 15pt | .regular |
| Caption | SF Pro Text | 13pt | .regular |
| Tiny label | SF Pro Text | 11pt | .medium |

Code example:

```swift
Text("Hero title")
    .font(.system(size: 34, weight: .bold, design: .default))
    .foregroundColor(NapletColors.textPrimary)
```

## Spacing

Use multiples of 4. Authorized values:

- `4` micro
- `8` small
- `12` default
- `16` standard
- `20` comfortable
- `24` generous
- `32` section
- `48` chapter break
- `64` major break

Never use odd numbers or values outside this list.

## Corner Radius

| Use | Radius |
|---|---|
| Buttons | 12 |
| Cards | 16 |
| Hero cards | 20 |
| Modal sheets | 24 (top corners only) |
| Avatars | 999 (circle) |

## Glassmorphism

For premium cards (paywall, onboarding hero, dashboard stats):

```swift
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(NapletColors.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            NapletColors.primaryPurple.opacity(0.3),
                            NapletColors.primaryPink.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
)
```

## Icons (SF Symbols only)

**No emojis in core features.** Emojis only in marketing copy or App Store descriptions.

| Concept | SF Symbol |
|---|---|
| Sleep | `moon.zzz.fill` |
| Nap | `sun.haze.fill` |
| Feeding (breast) | `heart.circle.fill` |
| Feeding (bottle) | `drop.fill` |
| Feeding (solids) | `fork.knife` |
| Diaper | `cross.case.fill` |
| Bath | `bathtub.fill` |
| Temperature | `thermometer.medium` |
| Medication | `pills.fill` |
| Vaccination | `syringe.fill` |
| Documents | `doc.text.fill` |
| Caregivers | `person.2.fill` |
| AI Chat | `sparkles` |
| PDF Report | `doc.richtext.fill` |
| Settings | `gearshape.fill` |
| Premium | `crown.fill` |
| Founder badge | `seal.fill` |

Default icon weight: `.medium`. For emphasis: `.bold`. For subtle: `.light`.

## Buttons

### Primary
- Background: hero gradient
- Foreground: white
- Corner radius: 12
- Padding: vertical 16, horizontal 24
- Font: 17pt semibold
- Haptic on tap: `.medium`

### Secondary
- Background: `NapletColors.backgroundCard`
- Foreground: `NapletColors.textPrimary`
- Border: 1pt `NapletColors.primaryPurple.opacity(0.3)`
- Corner radius: 12
- Same padding and font

### Tertiary (text link)
- Background: clear
- Foreground: `NapletColors.primaryPurple`
- Font: 15pt regular
- No padding besides hit target

## Cards

Default card structure:

```swift
VStack(alignment: .leading, spacing: 12) {
    // Content
}
.padding(16)
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(NapletColors.backgroundCard)
)
```

## Animations

Default easing: `.easeInOut(duration: 0.3)`.

For springy interactions (button taps, sheet presentations):
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.7), value: someState)
```

For loading indicators, use system `ProgressView` with tint:
```swift
ProgressView()
    .tint(NapletColors.primaryPurple)
```

## Empty States

Never leave a screen blank when there's no data. Always include:

1. Centered SF Symbol icon, 64pt, in `NapletColors.textMuted`
2. Headline in `NapletColors.textSecondary`, 17pt semibold
3. Description in `NapletColors.textMuted`, 15pt regular
4. Optional CTA button (secondary style)

## Haptic Feedback

Required on:
- Primary button taps: `.medium` impact
- Sheet presentations: `.light` impact
- Successful actions (sleep saved, etc): `.success` notification
- Errors: `.error` notification
- Toggles: `.light` impact

```swift
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

## Localization

All strings via `.localized` extension. Never hardcode.

```swift
Text("paywall_founders_title".localized)
```

Add to all three: `pt-BR.lproj`, `en.lproj`, `es.lproj`.

## Things to Avoid

- Generic system colors (`.blue`, `.green`) outside of error states
- Custom fonts
- Decorative emojis in core UI
- Asymmetric padding (use multiples of 4)
- Loading spinners without context (always pair with text)
- Toast notifications (use system alerts or in-screen feedback)
- Pull-to-refresh as primary refresh mechanism (use realtime instead)

## Reuse Before Creating

Before creating a new component:

1. Check `Core/Design/` for existing reusable components
2. Check similar Views for patterns
3. If genuinely new, place it in `Core/Design/Components/` for future reuse

## Visual Density

Naplet is calm, not crammed. Each screen should have:

- Clear visual hierarchy (one dominant element, max 2 secondary)
- Generous breathing room (32pt between major sections)
- One primary action per screen, never two

When in doubt, simplify.
