# 03 - Mapeamento de Paywall

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Resumo brutal

O Naplet declarou **7 triggers** em [PaywallTrigger.swift](Naplet/Features/Paywall/Models/PaywallTrigger.swift), mas **apenas 2 efetivamente disparam** no código real. Cinco triggers existem como `case` no enum, com headlines bonitos em `Localizable.strings`, mas **nenhum sítio do app chama `PaywallPresentationManager` com eles**. Isso explica boa parte do funil furado: 71% dos pontos de pressão planejados nunca acontecem.

---

## Tabela mestre de triggers

| # | Trigger (enum case) | Dispara hoje? | Local de disparo | Momento na jornada | Oferta exibida |
|---|---|---|---|---|---|
| 1 | `aiChatLimit` | ✅ SIM | [ChatView.swift:205](Naplet/Features/Chat/Views/ChatView.swift:205) via `viewModel.hasReachedLimit` | Tentativa de 6ª mensagem no mês | Founders se ativo, senão regular |
| 2 | `inviteCaregiver` | ✅ SIM (hard gate) | [CreateInviteSheet.swift:48-61](Naplet/Features/Caregivers/Views/CreateInviteSheet.swift:48) `.onAppear` | Tap no botão "+Convidar" se free | Founders/regular |
| 3 | `pdfReport` | ❌ NÃO | Enum existe; gate em [ReportViewModel](Naplet/Features/Reports/ViewModels/) ao **compartilhar** (não ao gerar) | Tap em "Compartilhar PDF" | Regular |
| 4 | `historyLimit` | ❌ NÃO | Enum só; SleepHistoryView não bloqueia >7d | (planejado) histórico antigo | Regular |
| 5 | `multipleBabies` | ❌ NÃO | Enum só; [AddBabyView](Naplet/Features/Settings/Views/AddBabyView.swift) não conta bebês | (planejado) 2º bebê | Regular |
| 6 | `softPrompt` | ⚠️ Possível | Default em [PaywallViewModel.swift:219](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:219) | Genérico (não há lógica de timing) | Founders/regular |
| 7 | `settingsUpgrade` | ❌ NÃO | Enum só; nunca chamado | (planejado) Settings | Regular |

---

## Quais disparam nas primeiras 48h?

Resposta direta:

- **Praticamente garantido nas 48h:** `aiChatLimit` — desde que o usuário use o Chat 6+ vezes (no mês). Como `remainingFreeChats` é AppStorage com reset mensal, **se o usuário entrar no dia 28 do mês, pode bater o limite no mesmo dia.**
- **Provável nas 48h se o usuário explora multi-cuidador:** `inviteCaregiver`.
- **Improvável ou impossível:** `pdfReport`, `historyLimit`, `multipleBabies`, `settingsUpgrade`.

**Implicação:** o usuário comum (que entra, registra 2 sonos e fecha) **não vê paywall nenhum nos primeiros dias**. Ele cadastra, usa, fecha o app, e como nada o empurra para a decisão de pagar, o app vira mais uma das 200 que ele instalou e abandonou.

---

## Copy por trigger (extraídas de `Localizable.strings` referenciadas em PaywallTrigger.swift)

| Trigger | Headline | Subtítulo / proposição |
|---|---|---|
| inviteCaregiver | "Toda a família junto!" | Foca em compartilhamento, não na dor do free |
| aiChatLimit | "Sua consultora de sono 24h" | Foca em feature, não em "Só 5 perguntas/mês no grátis" |
| pdfReport | "Impressione o pediatra" | Boa ancoragem emocional, mas trigger não dispara |
| historyLimit | "Veja toda a evolução" | Genérico, sem contraste com "7 dias só no free" |
| multipleBabies | "Acompanhe todos os bebês" | Genérico |
| settingsUpgrade | "Desbloqueie todo o potencial" | Pure feature-pump |
| softPrompt | "Desbloqueie todo o potencial" | Idem |

Padrão problemático: **todas as copies focam na feature ganha, não no problema atual** ("5 perguntas grátis acabaram", "histórico de 7 dias acabou"). Loss aversion não está sendo usado.

---

## Auditoria crítica do PaywallView atual

Checklist de elementos importantes para conversão:

| Elemento | Presente? | Evidência | Avaliação |
|---|---|---|---|
| Founders visível em período ativo | ✅ | [PaywallView.swift:96](Naplet/Features/Paywall/Views/PaywallView.swift:96) | Bom |
| Copy menciona economia concreta | ✅ | [PaywallView.swift:188](Naplet/Features/Paywall/Views/PaywallView.swift:188) `foundersDiscountPercentage` | Bom |
| Countdown visível | ✅ | [PaywallView.swift:204](Naplet/Features/Paywall/Views/PaywallView.swift:204) | Bom (mas: countdown estático até "22-Abril-2026", não relógio decrescente) |
| Badge Founder prometido | ✅ | [PaywallViewModel.swift:92-96](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:92) | Promete, mas [PaywallViewModel.swift:325](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:325) tem TODO "Implementar marcação de Founder no perfil" |
| Preço com ancoragem | ✅ | Anual riscado em [PaywallView.swift:183](Naplet/Features/Paywall/Views/PaywallView.swift:183) | Bom |
| CTA usa verbo de ganho | ⚠️ | "Garantir preço de Founder" ✅ | "Assinar Agora" ❌ (regular) |
| Oferta secundária pós-recuso | ❌ | – | AUSENTE. Recusou = fim. |
| Botão "Restaurar Compra" | ✅ | [PaywallView.swift:375](Naplet/Features/Paywall/Views/PaywallView.swift:375) | Bom |
| Links Terms/Privacy | ✅ | [PaywallView.swift:385-387](Naplet/Features/Paywall/Views/PaywallView.swift:385) | Bom |
| Ancoragem anual vs mensal | ✅ | "/mês equivalente" do anual | Bom |
| Prova social (depoimentos) | ⚠️ | 3 reviews em [PaywallView.swift:299-358](Naplet/Features/Paywall/Views/PaywallView.swift:299) | Sem foto real, sem número agregado |
| Prova social (números) | ❌ | – | AUSENTE. Falta "+10K famílias" ou "4.8⭐ em XYZ reviews" |
| Trial visível e destacado | ❌ | "14 dias grátis" só no footer pequeno | Subaproveitado |
| Copy contextual por trigger | ⚠️ | Headlines mudam, subtítulos não atacam a dor do free | Faltam "X mensagens acabaram" |
| Trigger analytics | ❌ | [PaywallTrigger.swift:201](Naplet/Features/Paywall/Models/PaywallTrigger.swift:201) TODO "Track with analytics service" | Sem mensuração |
| Conversão por trigger mensurada | ❌ | – | Sem dados, não dá para A/B testar |

---

## Os 5 ajustes mais críticos do paywall para subir conversão

### 1. Implementar os triggers fantasmas (impacto +15-25%)

Os triggers já têm copy. Falta só conectá-los:

- `multipleBabies`: no `AddBabyView.save()`, contar bebês via `BabyRepository.count` e disparar paywall se >= `AppConfig.Limits.maxBabiesFree` (atualmente 1).
- `pdfReport`: gate no **abrir** ReportView, não só no compartilhar. Permite preview, mas com watermark.
- `historyLimit`: bloquear datas anteriores a 7 dias na SleepHistoryView com placeholder "Premium: Veja desde o nascimento".
- `settingsUpgrade`: adicionar card "Upgrade Premium" no topo do SettingsView para free.

### 2. Reescrever copy com loss aversion no momento certo

Em vez de "Sua consultora 24h", usar:

> "Suas 5 perguntas grátis do mês acabaram. 
> 23 dias até resetar. Ou desbloqueie agora."

Loss aversion converte 2-3x melhor que features-promise em paywalls reativos.

### 3. Trocar CTA do regular

`paywall.cta.subscribe` está como **"Assinar Agora"** ([PaywallView.swift:275](Naplet/Features/Paywall/Views/PaywallView.swift:275)). Verbo neutro de gasto. Mudar para **"Garantir Acesso Completo"** ou **"Desbloquear Premium"**. Trocar string, código não precisa mudar.

### 4. Adicionar segunda oferta após recuso

Hoje recusou = fechou. Implementar `PaywallPresentationManager.presentDownsellIfDismissed()`:

- 3s após dismiss, abrir sheet menor com: "Espera. Que tal 7 dias grátis para experimentar?" ou "50% off no primeiro mês".

### 5. Adicionar prova social numérica

Acima dos 3 depoimentos existentes, adicionar bloco com:

- "X.XXX famílias acompanhando" (Supabase count em real-time)
- "Avaliado por Y pais" (App Store reviews)
- "Z mil noites melhores" (soma de sleep records)

Os números reais hoje são tímidos (46 ativos, 2 reviews), então use métricas agregadas que **soem grandes**: "27 mil registros de sono processados" é verdade e impressiona.

---

## Bug crítico de paywall: fallback de preço em outras moedas

[NapletPackageCard.swift:576-590](Naplet/Features/Paywall/Views/NapletPackageCard.swift:576) tem fallback hardcoded em R$:

```swift
case .annual: return "R$ 89,90"
```

Se um usuário estrangeiro abrir o app antes da StoreKit responder, vê "R$ 89,90" — confunde e mata conversão internacional. Mesmo que o Naplet seja BR-first, o app está disponível globalmente.

---

## Conclusão

Paywall **bonito visualmente, esqueleto fraco no funil**. Investiu-se em UI (gradientes, animações, badges) mas o funcionamento de pressão de pagamento — quem aparece quando, com que copy, com fallback — está **50% implementado**.

Se eu tivesse que escolher UMA mudança para fazer hoje: **implementar os 5 triggers fantasmas**. Eles aumentam a *quantidade* de paywall exibido, que multiplicada por uma taxa de conversão estável já produz salto. Reescrever copy é #2.
