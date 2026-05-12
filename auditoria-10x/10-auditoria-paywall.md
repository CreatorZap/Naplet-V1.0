# 10 - Auditoria Crítica do Paywall Naplet

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

> Este documento aprofunda o mapeamento já feito em [03-paywall-mapping.md](auditoria-10x/03-paywall-mapping.md). Aqui o foco é nos 5 ajustes críticos com **escopo de implementação**, **copy proposto** e **estimativa de impacto**.

---

## Foto atual do paywall

[PaywallView.swift](Naplet/Features/Paywall/Views/PaywallView.swift) tem 717 linhas. Visualmente bonito (gradientes, badges, animações). Funcionalmente: **50% implementado** como funil.

### Checklist resumido (versão completa em doc 03)

| Elemento | Estado |
|---|---|
| Founders visível | ✅ |
| Copy de economia concreta | ✅ |
| Countdown | ✅ (estático até 22-abr-2026) |
| Badge Founder prometido | ⚠️ promete, [PaywallViewModel.swift:325](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:325) TODO de implementação |
| Ancoragem de preço | ✅ |
| CTA verbo de ganho (Regular) | ❌ "Assinar Agora" |
| Oferta secundária pós-recuso | ❌ |
| Restaurar Compra | ✅ |
| Links Terms/Privacy | ✅ |
| Prova social numérica | ❌ |
| Trial destacado | ❌ (escondido em footer) |
| FAQ inline | ❌ |
| Trigger analytics | ❌ TODO em [PaywallTrigger.swift:201](Naplet/Features/Paywall/Models/PaywallTrigger.swift:201) |

---

## Os 5 ajustes mais críticos (com escopo)

### Ajuste #1 — Implementar os 5 triggers fantasmas

**Problema:** Apenas 2/7 triggers disparam de verdade. 71% da pressão planejada não acontece.

**Triggers não implementados:**

1. **`pdfReport`** — Gate em [ReportView.swift](Naplet/Features/Reports/Views/ReportView.swift) ao tentar **abrir** o relatório (não só ao share). Preview com watermark "AMOSTRA" para free; paywall ao tentar exportar.
2. **`multipleBabies`** — Gate em [AddBabyView.swift](Naplet/Features/Settings/Views/AddBabyView.swift) ao salvar o 2º bebê. Conta `BabyRepository.count` antes de save.
3. **`historyLimit`** — Gate em [SleepHistoryView.swift](Naplet/Features/History/Views/SleepHistoryView.swift) bloqueando datas anteriores a 7 dias com placeholder "Premium: veja desde o nascimento".
4. **`settingsUpgrade`** — Card "Atualizar para Premium" no topo do [SettingsView.swift](Naplet/Features/Settings/Views/SettingsView.swift) para usuários free.
5. **`softPrompt`** — Trigger temporal: após 3 sessões free na semana, abrir paywall com copy soft ("Curtindo? Desbloqueie todo o potencial.")

**Escopo de código (estimativa):**

```swift
// Em AddBabyView.swift, antes de saveBaby():
if !SubscriptionManager.shared.hasPremiumAccess {
    let currentCount = await BabyRepository.shared.count(for: userId)
    if currentCount >= AppConfig.Limits.maxBabiesFree {
        showPaywall = true
        return
    }
}

// Em ReportView.onAppear:
.onAppear {
    if !SubscriptionManager.shared.canExportPDF {
        showPreviewWithWatermark = true
    }
}
.sheet(isPresented: $showPaywall) {
    PaywallView(trigger: .pdfReport)
}
```

**Esforço:** 2-3 dias para os 5 triggers.
**Impacto estimado:** +15-25% em conversão pelo simples fato de o usuário VER o paywall mais vezes.

---

### Ajuste #2 — Reescrever copy com loss aversion

**Problema:** Headlines de paywall focam na feature ganha, não no problema atual do usuário no momento do trigger.

**Antes vs depois:**

| Trigger | Atual | Proposto |
|---|---|---|
| aiChatLimit | "Sua consultora de sono 24h" | "Suas 5 perguntas grátis acabaram. Continue agora — ou espere 23 dias." |
| inviteCaregiver | "Toda a família junto!" | "Convide o pai/a babá/a avó. Premium libera convites ilimitados." |
| pdfReport | "Impressione o pediatra" | "Próxima consulta esta semana? Exporte o PDF agora. (Premium.)" |
| historyLimit | "Veja toda a evolução" | "Sleep records antes de [data]: ocultos. Premium libera o histórico completo." |
| multipleBabies | "Acompanhe todos os bebês" | "Você já tem [Nome] cadastrado. Adicionar [Nome2] requer Premium." |

**Padrão:** sempre nomeia a perda (mensagens acabaram, histórico oculto, bebê já cadastrado) antes de pedir o pagamento. Loss aversion converte 2-3x melhor que pure feature-pump em paywalls reativos.

**Escopo:** atualizar `Localizable.strings` (PT-BR + EN se ativo). Nenhuma mudança de Swift.
**Esforço:** 1 dia.
**Impacto estimado:** +8-15% em CTR no paywall.

---

### Ajuste #3 — Reescrever o CTA do plano Regular

**Problema:** [PaywallView.swift:275](Naplet/Features/Paywall/Views/PaywallView.swift:275) usa string `paywall.cta.subscribe` → atualmente **"Assinar Agora"**. Verbo neutro de gasto.

**Antes:** "Assinar Agora"
**Depois:** "Desbloquear Premium" ou "Garantir Acesso Completo"

A versão Founders já usa "Garantir preço de Founder" — boa. Só falta nivelar a versão regular.

**Escopo:** trocar 1 string em `Localizable.strings`.
**Esforço:** 10 minutos.
**Impacto estimado:** +5-10% no botão. Pequeno absoluto, mas custo de implementação é zero.

---

### Ajuste #4 — Adicionar oferta secundária após primeira recusa

**Problema:** Quando usuário fecha o paywall (X no topo), nada acontece. Sem fallback, sem trial estendido, sem downsell.

**Padrão proposto:** 3s após o dismiss, abrir um sheet menor com oferta de "última chance":

> "Espera. Você pode experimentar 7 dias grátis antes de decidir.
> Não cobramos nada hoje. Cancele a qualquer momento.
>
> [Começar trial grátis]   [Continuar gratuito]"

**Lógica de exibição:**
- Mostrar no máximo 1x por sessão
- Persistir flag `hasSeenSecondaryOffer` para não repetir no mesmo trigger
- Não mostrar se usuário ativou trial em sessão anterior

**Escopo:**

```swift
// PaywallPresentationManager.swift
func presentSecondaryOfferIfNeeded(after trigger: PaywallTrigger) {
    guard !UserDefaults.standard.bool(forKey: "secondaryOffer_\(trigger)") else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        // present new sheet with SecondaryOfferView
    }
}
```

**Esforço:** 2-3 dias (incluindo nova View, integração com RevenueCat trial, edge cases).
**Impacto estimado:** +10-18% sobre os que recusaram a primeira oferta.

---

### Ajuste #5 — Adicionar prova social numérica + FAQ inline

**Problema:** Hoje há 3 reviews fictícias com nomes em [PaywallView.swift:299-358](Naplet/Features/Paywall/Views/PaywallView.swift:299). Sem números agregados. Sem FAQ. Compare com o paywall do Napper que tem 4.9⭐ + 15K reviews + Editor's Choice + 1M famílias + FAQ.

**Bloco proposto (acima dos 3 reviews atuais):**

```
┌─────────────────────────────────┐
│  ⭐ 5.0 (BR · iOS)               │
│  📊 27.000+ sonos registrados    │
│  📋 1.200+ PDFs entregues        │
└─────────────────────────────────┘
```

Usar números REAIS, calculados de Supabase em build-time ou no fetch da view. Mesmo com 46 ativos, o app processou centenas de sonos — esse número soa grande.

**FAQ inline (4 perguntas, accordion):**

1. "Como cancelar a assinatura?" → "Em Ajustes do iOS > Apple ID > Assinaturas. A qualquer momento."
2. "Posso compartilhar com meu parceiro/cuidador?" → "Sim, multi-cuidador está incluso em Premium."
3. "E se eu desistir nos primeiros 7 dias?" → "Não cobramos durante o trial."
4. "Os dados ficam comigo?" → "Sempre. Você pode exportar tudo a qualquer momento."

**Escopo:**
- Componente `NapletStatRow` (3 itens horizontais)
- Componente `NapletFAQAccordion` (4 itens com DisclosureGroup)
- 8 strings novas em Localizable

**Esforço:** 1-2 dias.
**Impacto estimado:** +5-10% em conversão por redução de objeções.

---

## Resumo dos 5 ajustes

| # | Ajuste | Esforço | Impacto estimado | ROI |
|---|---|---|---|---|
| 1 | Implementar 5 triggers fantasmas | 2-3 dias | +15-25% | **MUITO ALTO** |
| 2 | Copy com loss aversion | 1 dia | +8-15% | **ALTO** |
| 3 | CTA "Desbloquear Premium" | 10 min | +5-10% | **MUITO ALTO** (custo zero) |
| 4 | Oferta secundária pós-recuso | 2-3 dias | +10-18% sobre quem recusou | **ALTO** |
| 5 | Prova social numérica + FAQ inline | 1-2 dias | +5-10% | **ALTO** |

**Composto:** se todos os 5 forem implementados sequencialmente, conversão atual pode subir **2-4x** (multiplicativo, não aditivo).

---

## Bugs/débito no paywall a corrigir junto

1. [PaywallTrigger.swift:201](Naplet/Features/Paywall/Models/PaywallTrigger.swift:201) — TODO "Track with analytics service". Sem isso não há mensuração de A/B. Implementar com PostHog ou similar (Mixpanel custa mais). **Crítico para iterar.**
2. [PaywallViewModel.swift:325](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:325) — TODO "Implementar marcação de Founder no perfil". Está prometendo badge no paywall sem entregar.
3. [NapletPackageCard.swift:576-590](Naplet/Features/Paywall/Views/NapletPackageCard.swift:576) — fallback hardcoded "R$ 89,90" mesmo em outras moedas. Quebra em usuários internacionais.
4. Countdown da Founders é **estático** (data fixa). Deveria ser **timer decrescente** real ("Termina em 14d 6h 32min").

---

## Conclusão

O paywall do Naplet **não precisa de redesign**. Precisa de **wiring**. A UI está pronta, o que falta é conectar triggers, copy e fallbacks. Custo total estimado: ~10 dias de trabalho concentrado para os 5 ajustes principais.

ROI: se a conversão atual é 0% (que é o caso), **qualquer melhora é infinitamente proporcional**. Mas tracking analítico (item #1 dos bugs acima) precisa entrar primeiro, senão não dá para medir o efeito de nenhum ajuste.

**Ordem recomendada de execução:**

1. Adicionar analytics (PostHog) → 1 dia
2. Ajuste #3 (CTA) → 10 min
3. Ajuste #1 (triggers fantasmas) → 2-3 dias
4. Ajuste #2 (copy com loss aversion) → 1 dia
5. Ajuste #5 (prova social + FAQ) → 1-2 dias
6. Ajuste #4 (oferta secundária) → 2-3 dias

Total: ~8-10 dias.
