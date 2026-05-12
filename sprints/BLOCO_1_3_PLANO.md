# BLOCO 1.3 — Paywall Pós-Onboarding

**Sprint:** 1 (Destravar receita)
**Branch:** `sprint-1/paywall-pos-onboarding`
**Estimativa:** 8 a 12 horas em sessão dedicada
**Status:** Plano consultivo concluído, pronto para implementação
**Criado em:** 12 de maio de 2026

---

## 1. Contexto e objetivo

### Problema

O Naplet está há mais de 60 dias na App Store com 150 usuários ativos, 134 cadastros novos no mês e **zero conversões**. O onboarding coleta 9 dados pessoais ao longo de 12 telas e libera todo o app gratuitamente. O sunk cost gerado durante o onboarding é desperdiçado.

### Hipótese

A ausência de um momento de decisão comercial no fluxo de primeira sessão é o gargalo principal. Ao inserir um paywall entre a tela de loading (11) e a tela de completion (12), aproveitamos o pico de investimento emocional do usuário para apresentar o Founders Plan com trial de 7 dias.

### Objetivo

Aumentar a conversão de trial a partir do onboarding de 0% para um patamar entre 8% e 15% em 30 dias, alinhado com benchmarks da categoria de subscription parental apps.

### Pré-requisitos atendidos

| Item | Estado |
|---|---|
| Edge Function OpenAI segura | OK (Bloco 1.1) |
| Privacy Manifest criado | OK (stub mínimo) |
| RevenueCat em produção validado | OK (Bloco 1.2 light) |
| Founders package ativo | OK (extended até 22-Jul-2026, Bloco 1.5) |
| Founders end date no AppConfig | OK (`AppConfig.swift:192-202`) |
| Logs runtime RevenueCat | OK (mostra ACTIVE 71 days remaining) |

---

## 2. Análise do onboarding atual

### Mapeamento completo das 12 telas

| Tela | Função | CTA primária | Skippable | Avaliação |
|---|---|---|---|---|
| 1 | Welcome | Começar agora | Não | Boa visual, copy fraca, triple CTA confusa |
| 2 | Benefits (3 cards) | Vamos lá! | Não | Cards bonitos, copy mediana |
| 3 | Differentials (3 cards) | Continuar | Não | **Melhor tela do fluxo, ancora preço** |
| 4 | Attribution | Próximo | Sim (Pular) | Funcional |
| 5 | Goals (multi-select) | Continuar | Sim (Pular) | UX adequada |
| 6 | BabyName | Próximo | Não | Padrão eficiente |
| 7 | BabyBirth (wheel) | Próximo | Não (toggle gestante) | Wheel picker bom |
| 8 | BabyGender | Próximo | Implícito (opcional) | Bem sinalizado |
| 9 | Relationship | Próximo | Não | Mamãe pré-selecionada (bias problemático) |
| 10 | Confirmation (resumo) | Confirmar e começar | Não | UX exemplar |
| 11 | Loading (spinner) | n/a | Não | **Subutilizada, oportunidade clara** |
| 12 | Completion | Começar a usar o Naplet | Não | Anti-clímax, perde momentum |

### Pontos fortes preservar

1. **Barra de progresso "X de 12"** com gradient roxo-pink mantém engajamento e reduz drop-off
2. **Tela 3 (Differentials)** já apresenta selo EXCLUSIVO e ancoragem de preço ("3x mais barato")
3. **Tela 7 (BabyBirth)** com toggle "Meu bebê ainda não nasceu" captura gestantes (momento de maior intenção de compra)
4. **Tela 10 (Confirmation)** com edição inline é referência de UX premium
5. **Personalização contínua** ("Alice é...", "E você, quem é para Alice?") cria conexão emocional

### Pontos críticos endereçar

1. **Paywall não existe no fluxo** — sunk cost desperdiçado
2. **Tela 11 (Loading)** dura ~2 segundos com spinner genérico, deveria ter 4-5 segundos com mensagens sequenciais de personalização
3. **Tela 12 (Completion)** é anti-clímax — usuário recebe acesso sem decisão comercial

---

## 3. Decisão arquitetural

### Posição do paywall

**Entre a Tela 11 (Loading) e a Tela 12 (Completion).**

### Justificativa

| Critério | Antes (10 e 11) | **Depois (11 e 12)** | Depois (pós-app) |
|---|---|---|---|
| Sunk cost acumulado | 9 cliques | **11 cliques + loading** | Evapora ao tocar feature |
| Antecipação emocional | Baixa | **Alta (loading prepara)** | Zero |
| Convenção de mercado | Raro | **Padrão (Calm, Napper, Aura)** | Anti-padrão |
| Visibilidade do Founders | Boa | **Ótima** | Ruim (deadline some) |
| Conversion lift esperado | 4-6% | **8-15%** | 1-3% |

### Fluxo final

```
1. Welcome
2. Benefits
3. Differentials                ← ancora preço pela primeira vez
4. Attribution
5. Goals
6. BabyName
7. BabyBirth
8. BabyGender
9. Relationship
10. Confirmation
11. Loading (estendido)          ← antecâmara emocional
12. ★ OnboardingPaywallView      ← NOVO
13. Completion                   ← celebração da decisão
```

---

## 4. Estrutura técnica

### Arquivos novos

```
Naplet/Features/Onboarding/Views/
└── OnboardingPaywallView.swift          (~500 linhas)
```

### Arquivos editados

```
Naplet/Features/Onboarding/Views/
├── OnboardingView.swift                  (orquestrador, inserir paywall)
└── OnboardingLoadingView.swift           (estender duração + mensagens)

Naplet/Resources/
├── pt-BR.lproj/Localizable.strings       (+30 strings)
├── en.lproj/Localizable.strings          (+30 strings)
└── es.lproj/Localizable.strings          (+30 strings)
```

### Dependências

| Componente | Já existe? | Localização |
|---|---|---|
| NapletColors design system | Sim | `Core/Design/NapletColors.swift` |
| PurchaseService | Sim | `Data/Services/PurchaseService.swift` |
| Founders package no RevenueCat | Sim, ativo | Dashboard RevenueCat |
| AnalyticsService | Verificar | Buscar referência no codebase antes |
| Logger | Sim | `Core/Utilities/Logger.swift` |

### Arquitetura do OnboardingPaywallView

```swift
struct OnboardingPaywallView: View {
    // Dependências
    @StateObject private var viewModel: OnboardingPaywallViewModel
    @EnvironmentObject var onboardingCoordinator: OnboardingCoordinator
    let babyName: String  // injetado para personalização
    
    // Estado
    @State private var isPurchasing = false
    @State private var showError: PurchaseError?
    
    // Computed
    private var foundersEndDate: String { /* formatada */ }
    private var daysRemainingInFounders: Int { /* AppConfig.foundersEndDate */ }
    
    var body: some View {
        ZStack {
            NapletColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    closeButton
                    header(babyName: babyName)
                    foundersHeroCard
                    valuePillars
                    trialHighlight
                    primaryCTA
                    secondaryCTA
                    socialProof
                    fineprint
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            AnalyticsService.track("onboarding_paywall_shown")
        }
    }
}
```

---

## 5. Layout do OnboardingPaywallView

### Estrutura visual (top to bottom)

```
┌─────────────────────────────────────┐
│                                  X  │  Close button (top-right)
│                                     │
│  Sua experiência Naplet            │  Header H1
│  está pronta                       │
│  Alice merece o melhor para         │  Subheader
│  crescer dormindo bem               │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  🎁 OFERTA FUNDADORES         │ │  Hero card (border primaryPurple)
│  │  Apenas até 22 de julho       │ │
│  │                               │ │
│  │  R$ 59,90 /ano                │ │  Preço hero (display large)
│  │  Depois R$ 89,90 /ano         │ │  Strikethrough no preço regular
│  │                               │ │
│  │  ⏱ 71 dias restantes          │ │  Countdown
│  └───────────────────────────────┘ │
│                                     │
│  🤖 Assistente de IA 24h           │  Pillar 1
│     Tire dúvidas a qualquer hora    │
│                                     │
│  📄 Relatórios para o Pediatra     │  Pillar 2
│     PDFs prontos para consultas     │
│                                     │
│  👨‍👩‍👧 Família sincronizada           │  Pillar 3
│     Mamãe, papai, avós e babás      │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  ✨ 7 dias grátis             │ │  Trial card (border success)
│  │  Cancele em 1 toque antes     │ │
│  │  do fim do período            │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  → Começar 7 dias grátis     │ │  CTA primária (gradient)
│  └───────────────────────────────┘ │
│                                     │
│  Continuar com versão básica       │  CTA secundária (text only)
│                                     │
│  ─────────────────────────────     │
│  Restaurar compras · Termos ·       │  Fine print
│  Privacidade                        │
└─────────────────────────────────────┘
```

### Especificações visuais

| Elemento | Spec |
|---|---|
| Background | `NapletColors.background` (#0D0B1E) |
| Header H1 | `.system(size: 28, weight: .bold)`, white |
| Subheader | `.system(size: 16)`, `NapletColors.textSecondary` |
| Hero card | `RoundedRectangle(cornerRadius: 20)`, border `NapletColors.primaryPurple` (2pt), background `NapletColors.backgroundCard` |
| Preço hero | `.system(size: 36, weight: .bold)`, `NapletColors.primaryPurple` |
| Preço strikethrough | `.system(size: 16)`, `NapletColors.textMuted`, `.strikethrough()` |
| Countdown | `.system(size: 14, weight: .semibold)`, `NapletColors.primaryPink` |
| Pillar icons | SF Symbols, size 28, gradient roxo-pink |
| Trial card border | `NapletColors.success` (#22C55E) |
| CTA primária | Gradient `[primaryPurple, primaryPink]`, height 56, cornerRadius 28 |
| CTA secundária | text only, `NapletColors.textSecondary`, padding 16 |
| Close button | SF `xmark`, color `NapletColors.textMuted`, position `.topTrailing` |

### Comportamentos

- **Pull to dismiss desativado** (`.interactiveDismissDisabled(true)`)
- **Swipe back desativado** na NavigationStack
- **CTA primária** desabilita durante `isPurchasing`, mostra `ProgressView()` inline
- **CTA secundária** dispara `onboarding_paywall_skipped` e segue para Completion
- **Close (X)** dispara `onboarding_paywall_dismissed_x` e segue para Completion (mesmo efeito do skip, mas evento diferente para analytics)

---

## 6. Copy completa

### Português brasileiro

```
HEADER
"Sua experiência Naplet está pronta"
"{babyName} merece o melhor para crescer dormindo bem"

HERO CARD
"🎁 OFERTA FUNDADORES"
"Apenas até 22 de julho de 2026"
"R$ 59,90 /ano · primeiro ano"
"Depois R$ 89,90 /ano"
"⏱ {N} dias restantes"

PILLARS
"🤖 Assistente de IA 24h"
"Tire dúvidas a qualquer hora, respostas personalizadas para {babyName}"

"📄 Relatórios para o pediatra"
"PDFs profissionais prontos para impressionar nas consultas"

"👨‍👩‍👧 Família sincronizada"
"Mamãe, papai, avós e babás na mesma página em tempo real"

TRIAL HIGHLIGHT
"✨ 7 dias grátis"
"Sem compromisso. Cancele em 1 toque antes do fim do período."

CTAs
PRIMÁRIA: "→ Começar 7 dias grátis"
SECUNDÁRIA: "Continuar com versão básica"

FINE PRINT
"Restaurar compras · Termos de uso · Política de privacidade"
"Renovação automática. Cancele a qualquer momento nas configurações da App Store."
```

### English

```
HEADER
"Your Naplet experience is ready"
"{babyName} deserves the best to grow while sleeping well"

HERO CARD
"🎁 FOUNDERS OFFER"
"Only until July 22, 2026"
"$14.99 /year · first year"
"Then $21.99 /year"
"⏱ {N} days remaining"

PILLARS
"🤖 24/7 AI Assistant"
"Ask anything anytime, answers personalized for {babyName}"

"📄 Pediatrician Reports"
"Professional PDFs ready to impress at checkups"

"👨‍👩‍👧 Family in sync"
"Mom, dad, grandparents and nannies on the same page in real time"

TRIAL HIGHLIGHT
"✨ 7 days free"
"No commitment. Cancel in 1 tap before the trial ends."

CTAs
PRIMARY: "→ Start 7-day free trial"
SECONDARY: "Continue with basic version"

FINE PRINT
"Restore purchases · Terms of use · Privacy policy"
"Auto-renewal. Cancel anytime in your App Store settings."
```

### Español

```
HEADER
"Tu experiencia Naplet está lista"
"{babyName} merece lo mejor para crecer durmiendo bien"

HERO CARD
"🎁 OFERTA FUNDADORES"
"Solo hasta el 22 de julio de 2026"
"$14.99 /año · primer año"
"Luego $21.99 /año"
"⏱ {N} días restantes"

PILLARS
"🤖 Asistente de IA 24h"
"Preguntá lo que quieras cuando quieras, respuestas personalizadas para {babyName}"

"📄 Informes para el pediatra"
"PDFs profesionales listos para impresionar en las consultas"

"👨‍👩‍👧 Familia sincronizada"
"Mamá, papá, abuelos y niñeras en la misma página en tiempo real"

TRIAL HIGHLIGHT
"✨ 7 días gratis"
"Sin compromiso. Cancelá en 1 toque antes de que termine el período."

CTAs
PRIMARIA: "→ Empezar 7 días gratis"
SECUNDARIA: "Continuar con versión básica"

FINE PRINT
"Restaurar compras · Términos de uso · Política de privacidad"
"Renovación automática. Cancelá cuando quieras en los ajustes de la App Store."
```

---

## 7. Strings localizadas necessárias

### Chaves a adicionar em `Localizable.strings`

```
// MARK: - Onboarding Paywall
"onboarding.paywall.header.title" = "Sua experiência Naplet está pronta";
"onboarding.paywall.header.subtitle" = "%@ merece o melhor para crescer dormindo bem";

"onboarding.paywall.founders.badge" = "🎁 OFERTA FUNDADORES";
"onboarding.paywall.founders.deadline" = "Apenas até %@";
"onboarding.paywall.founders.price" = "R$ 59,90 /ano · primeiro ano";
"onboarding.paywall.founders.priceRegular" = "Depois R$ 89,90 /ano";
"onboarding.paywall.founders.countdown" = "⏱ %d dias restantes";

"onboarding.paywall.pillar.ai.title" = "🤖 Assistente de IA 24h";
"onboarding.paywall.pillar.ai.body" = "Tire dúvidas a qualquer hora, respostas personalizadas para %@";

"onboarding.paywall.pillar.pdf.title" = "📄 Relatórios para o pediatra";
"onboarding.paywall.pillar.pdf.body" = "PDFs profissionais prontos para impressionar nas consultas";

"onboarding.paywall.pillar.family.title" = "👨‍👩‍👧 Família sincronizada";
"onboarding.paywall.pillar.family.body" = "Mamãe, papai, avós e babás na mesma página em tempo real";

"onboarding.paywall.trial.title" = "✨ 7 dias grátis";
"onboarding.paywall.trial.body" = "Sem compromisso. Cancele em 1 toque antes do fim do período.";

"onboarding.paywall.cta.primary" = "→ Começar 7 dias grátis";
"onboarding.paywall.cta.secondary" = "Continuar com versão básica";

"onboarding.paywall.fineprint.restore" = "Restaurar compras";
"onboarding.paywall.fineprint.terms" = "Termos de uso";
"onboarding.paywall.fineprint.privacy" = "Política de privacidade";
"onboarding.paywall.fineprint.autorenewal" = "Renovação automática. Cancele a qualquer momento nas configurações da App Store.";

// MARK: - Onboarding Loading (extended)
"onboarding.loading.step1" = "Analisando os dados de %@...";
"onboarding.loading.step2" = "Calculando janelas de sono ideais...";
"onboarding.loading.step3" = "Preparando seu assistente de IA...";
"onboarding.loading.step4" = "Configurando relatórios para o pediatra...";
"onboarding.loading.step5" = "Tudo pronto!";

// MARK: - Errors
"onboarding.paywall.error.purchaseFailed" = "Não foi possível processar a compra. Tente novamente.";
"onboarding.paywall.error.networkFailed" = "Sem conexão. Verifique sua internet e tente novamente.";
```

Replicar para `en.lproj/` e `es.lproj/` com os textos da seção 6.

**Total estimado:** 28 chaves novas em PT-BR + 28 em EN + 28 em ES = 84 strings.

---

## 8. Integração RevenueCat

### Fluxo de compra

```swift
@MainActor
final class OnboardingPaywallViewModel: ObservableObject {
    @Published var isPurchasing = false
    @Published var error: PurchaseError?
    
    private let purchaseService: PurchaseService
    private let analytics: AnalyticsService
    
    init(purchaseService: PurchaseService = .shared,
         analytics: AnalyticsService = .shared) {
        self.purchaseService = purchaseService
        self.analytics = analytics
    }
    
    func purchaseFounders() async -> Bool {
        analytics.track("onboarding_paywall_cta_tap", properties: [
            "package": "founders_annual"
        ])
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await purchaseService.purchaseFoundersPackage()
            
            if result.userCancelled {
                analytics.track("onboarding_paywall_cancelled")
                return false
            }
            
            analytics.track("onboarding_paywall_purchased", properties: [
                "package": "founders_annual",
                "transaction_id": result.transactionIdentifier ?? "unknown"
            ])
            
            return true
        } catch let purchaseError as PurchaseError {
            self.error = purchaseError
            analytics.track("onboarding_paywall_purchase_failed", properties: [
                "error": purchaseError.localizedDescription
            ])
            return false
        } catch {
            self.error = .unknown(error)
            return false
        }
    }
    
    func skip() {
        analytics.track("onboarding_paywall_skipped")
    }
    
    func dismissByX() {
        analytics.track("onboarding_paywall_dismissed_x")
    }
}
```

### Verificações pré-implementação

1. **Confirmar nome da função em `PurchaseService`** que compra o Founders package. Pode ser `purchaseFoundersPackage()`, `purchase(.founders)` ou outro. Investigar antes de codificar.
2. **Confirmar tipo de retorno** (`PurchaseResult`, `CustomerInfo`, etc.).
3. **Verificar se `AnalyticsService` existe** ou se há outro padrão de tracking (PostHog, Firebase, Mixpanel). Se não existir, criar stub mínimo que apenas faz `Logger.info` em Debug.

---

## 9. Eventos de Analytics

### Funil completo

| # | Evento | Quando dispara | Propriedades |
|---|---|---|---|
| 1 | `onboarding_paywall_shown` | View aparece (`onAppear`) | `days_remaining_in_founders: Int` |
| 2 | `onboarding_paywall_cta_tap` | Toque na CTA primária | `package: "founders_annual"` |
| 3 | `onboarding_paywall_purchased` | Compra completa com sucesso | `package`, `transaction_id` |
| 4 | `onboarding_paywall_cancelled` | Cancelou na sheet do Apple | nenhuma |
| 5 | `onboarding_paywall_purchase_failed` | Erro na compra | `error: String` |
| 6 | `onboarding_paywall_skipped` | Toque em "Continuar com versão básica" | nenhuma |
| 7 | `onboarding_paywall_dismissed_x` | Toque no X de fechar | nenhuma |

### Métricas derivadas (calcular em dashboard)

```
Show rate              = paywall_shown / onboarding_started
CTA tap rate           = paywall_cta_tap / paywall_shown
Purchase rate          = paywall_purchased / paywall_cta_tap
Skip rate              = paywall_skipped / paywall_shown
Dismiss rate           = paywall_dismissed_x / paywall_shown
Overall conversion     = paywall_purchased / paywall_shown
Hesitation rate        = paywall_cancelled / paywall_cta_tap
```

### Benchmark esperado em 30 dias

| Métrica | Pessimista | Realista | Otimista |
|---|---|---|---|
| Show rate | 70% | 85% | 95% |
| CTA tap rate | 18% | 25% | 35% |
| Purchase rate | 50% | 65% | 80% |
| Overall conversion | 6% | 12% | 18% |

---

## 10. Modificações em arquivos existentes

### OnboardingView.swift (orquestrador)

Investigar primeiro a estrutura atual. Provavelmente é um `TabView` com `PageTabViewStyle` ou um switch sobre um estado `currentStep`. A modificação consiste em:

1. Adicionar `case .paywall` no enum de steps (entre `.loading` e `.completion`)
2. Adicionar branch no switch para renderizar `OnboardingPaywallView`
3. Garantir que a transição `loading → paywall` aconteça automaticamente após `~4s` de loading
4. Garantir que ambas as ações no paywall (purchase OK ou skip) avançam para `.completion`

### OnboardingLoadingView.swift (estender)

Implementação atual: spinner único + texto fixo "Personalizando sua experiência..." por ~2s.

Implementação proposta:

```swift
struct OnboardingLoadingView: View {
    let babyName: String
    @State private var currentStep = 0
    @Binding var isComplete: Bool
    
    private var steps: [String] {
        [
            String(format: "onboarding.loading.step1".localized, babyName),
            "onboarding.loading.step2".localized,
            "onboarding.loading.step3".localized,
            "onboarding.loading.step4".localized,
            "onboarding.loading.step5".localized
        ]
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ProgressRingView(progress: Double(currentStep + 1) / Double(steps.count))
                .frame(width: 80, height: 80)
            
            Text(steps[currentStep])
                .font(.headline)
                .foregroundColor(NapletColors.textSecondary)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id(currentStep)
            
            Spacer()
        }
        .onAppear { runSequence() }
    }
    
    private func runSequence() {
        for index in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.9) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = index
                }
                if index == steps.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isComplete = true
                    }
                }
            }
        }
    }
}
```

Duração total: 5 × 0.9s + 0.6s = **5.1 segundos**.

---

## 11. Smoke test plan

### Cenário 1: Compra com sucesso (sandbox)

1. Criar conta nova com email teste (ex: `teste-paywall-01@naplet.app`)
2. Passar pelas 12 telas do onboarding
3. Validar que loading dura ~5s e mostra 5 mensagens sequenciais
4. Validar que paywall aparece após loading
5. Validar countdown de Founders (deve mostrar ~71 dias)
6. Tocar em "Começar 7 dias grátis"
7. Sheet do Apple aparece (sandbox)
8. Confirmar compra
9. Validar evento `onboarding_paywall_purchased` no console
10. Validar transição para tela 12 (Completion)
11. Tocar em "Começar a usar o Naplet"
12. Validar Dashboard mostra o bebê
13. Tocar em Chat IA: NÃO deve aparecer paywall de upgrade (já é premium)

### Cenário 2: Skip do paywall

1. Criar conta nova (`teste-paywall-02@naplet.app`)
2. Passar pelo onboarding
3. No paywall, tocar em "Continuar com versão básica"
4. Validar evento `onboarding_paywall_skipped`
5. Validar transição para Completion
6. Validar Dashboard normal
7. Tocar em Chat IA: paywall de upgrade DEVE aparecer

### Cenário 3: Close por X

1. Criar conta nova (`teste-paywall-03@naplet.app`)
2. Passar pelo onboarding
3. No paywall, tocar no X (close)
4. Validar evento `onboarding_paywall_dismissed_x`
5. Mesmo fluxo de skip a partir daqui

### Cenário 4: Cancelar na sheet do Apple

1. Conta nova, fluxo até paywall
2. Tocar em "Começar 7 dias grátis"
3. Na sheet do Apple, tocar em Cancelar
4. Validar evento `onboarding_paywall_cancelled`
5. Validar que volta para o paywall (não avança para Completion)

### Cenário 5: Erro de rede

1. Conta nova, fluxo até paywall
2. Desligar Wi-Fi do simulador (Network Link Conditioner)
3. Tocar em "Começar 7 dias grátis"
4. Validar mensagem de erro localizada
5. Validar evento `onboarding_paywall_purchase_failed`
6. Religar Wi-Fi e tentar novamente: deve funcionar

---

## 12. Definition of Done

### Funcional

- [ ] `OnboardingPaywallView.swift` criado e renderizando em ambiente Debug
- [ ] `OnboardingView.swift` orquestra a inserção entre tela 11 e 12
- [ ] `OnboardingLoadingView.swift` estendido com 5 mensagens sequenciais
- [ ] 28 strings localizadas em PT-BR + 28 em EN + 28 em ES (84 total)
- [ ] Integração RevenueCat via Founders package funciona em sandbox
- [ ] Todos os 7 eventos de analytics disparam corretamente
- [ ] 5 cenários de smoke test executados com sucesso

### Técnico

- [ ] Build verde no Xcode (iPhone 17 Pro simulador)
- [ ] Zero warnings novos introduzidos
- [ ] Nenhum print() em código de produção (usar Logger)
- [ ] Cores referenciadas existem em NapletColors
- [ ] Strings não hardcoded (tudo via .localized)
- [ ] Acessibilidade básica (VoiceOver lê CTAs corretamente)

### Comercial

- [ ] Countdown reflete `AppConfig.foundersEndDate` (22-Jul-2026)
- [ ] Preço hero mostra R$ 59,90 em pt-BR e $14.99 em en/es
- [ ] Trial de 7 dias destacado visualmente
- [ ] Link Termos abre `TermsOfServiceView` existente
- [ ] Link Privacidade abre `PrivacyPolicyView` existente
- [ ] Restore purchases funcional

### Git

- [ ] 1 commit por mudança lógica (paywall view, loading extension, strings, orchestrator)
- [ ] Mensagens de commit seguem padrão `feat(paywall): ...` ou `feat(onboarding): ...`
- [ ] Push para `sprint-1/paywall-pos-onboarding`
- [ ] PR aberto contra `main` (mas não merged até validação completa)

---

## 13. Issues secundários (sprint de cleanup futura)

Detectados durante análise do onboarding, **não tratar no Bloco 1.3:**

| # | Tela | Issue | Severidade | Effort |
|---|---|---|---|---|
| WL-01 | Tela 1 | "bebe com confianca" sem acentos | Alta | 2 min |
| WL-02 | Tela 1 | "ajuda seu bebê dormir melhor" falta "a" | Alta | 2 min |
| WL-03 | Tela 1 | Triple CTA divide atenção | Média | 30 min |
| WL-04 | Tela 2 | "Para você E para o seu bebê" com "E" maiúsculo | Baixa | 1 min |
| WL-05 | Tela 9 | Mamãe pré-selecionada cria bias | Média | 5 min |

**Total cleanup:** ~40 minutos para todas as 5 correções. Agendar para sprint dedicada de polish após Bloco 1.3 entregue.

---

## 14. Cronograma sugerido

### Sessão única dedicada (8-12 horas)

| Fase | Duração | Atividade |
|---|---|---|
| Setup | 30 min | Verificar branch, ler OnboardingView atual, mapear PurchaseService |
| Strings | 1h | Adicionar 84 strings em PT-BR, EN, ES |
| Loading extended | 1h | Implementar OnboardingLoadingView com 5 steps |
| Paywall view (estrutura) | 2h | Layout + componentes (header, hero, pillars, trial, CTAs, fineprint) |
| Paywall view (estilo) | 1h30 | Cores, espaçamentos, animações, dark mode |
| ViewModel + analytics | 1h | OnboardingPaywallViewModel + 7 eventos |
| Integração RevenueCat | 1h | Conectar com PurchaseService, tratamento de erros |
| Orchestrator | 30 min | Modificar OnboardingView para inserir o paywall |
| Smoke test | 2h | 5 cenários no simulador, fix de bugs |
| Commit + push | 30 min | 4-5 commits separados, push para origin |

**Total estimado:** 11 horas. Recomendação: dividir em 2 sessões de 5-6h se possível, para preservar qualidade.

### Sessão dividida (recomendado)

**Sessão A (5h):** Setup + Strings + Loading extended + Paywall view (estrutura + estilo)
**Sessão B (6h):** ViewModel + Analytics + Integração + Orchestrator + Smoke test + Commits

---

## 15. Riscos identificados

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| `PurchaseService` não expõe método para Founders package específico | Média | Alto | Investigar antes de codificar, ajustar plano se necessário |
| `AnalyticsService` não existir no projeto | Alta | Baixo | Criar stub mínimo com Logger.info |
| Loading sequencial causar bug de timing | Baixa | Médio | Usar DispatchQueue.asyncAfter com cuidado, ou Timer |
| Sandbox do RevenueCat retornar erro inesperado | Média | Alto | Testar bem em sandbox antes de mergear |
| Dark mode quebrar contraste em algum elemento | Baixa | Médio | Testar com `.preferredColorScheme(.dark)` no preview |
| App Review rejeitar paywall por copy de Founders | Baixa | Alto | Manter copy fact-based, evitar superlativos não comprováveis |

---

## 16. Referências e benchmarks

### Apps de referência (estudados)

- **Napper** (concorrente direto): paywall com storytelling de transformação, sem trial visível, preço único alto
- **Calm**: paywall pós-onboarding com trial 7 dias, social proof, hero único
- **Headspace**: paywall com social proof prominente, tiers visuais comparativos
- **Aura**: paywall com countdown timer, urgency forte

### Convenções respeitadas

- Trial de 7 dias destacado (padrão Apple)
- Auto-renewal disclaimer obrigatório
- Restore purchases acessível
- Cancel anytime explícito
- Sem dark patterns (skip claramente disponível)

---

## 17. Próximos passos imediatos

### Antes da próxima sessão de implementação

1. **Salvar este documento** em `sprints/BLOCO_1_3_PLANO.md` no projeto
2. **Validar que branch correta está checada out** (`sprint-1/paywall-pos-onboarding`)
3. **Não codificar nada ainda** — descansar a cabeça

### Na próxima sessão

1. Abrir este documento como referência
2. Começar pela seção 10 (modificações em arquivos existentes), porque precisa entender o orquestrador atual
3. Seguir a ordem do cronograma da seção 14
4. Marcar checkboxes da seção 12 (DoD) conforme avança

---

**Status do documento:** Pronto para implementação
**Última atualização:** 12 de maio de 2026, 12h
**Próxima revisão:** Após sessão de implementação, atualizar com lições aprendidas
