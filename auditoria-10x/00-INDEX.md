# 00 - INDEX EXECUTIVO

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)
**Para:** Edy (Naplet) e Claude futuro nas próximas conversas

---

## O que é este pacote

Auditoria estratégica do app **Naplet** (iOS, SwiftUI, BR), publicado na App Store há alguns meses. Estado conhecido: **~46 usuários ativos, 0 assinaturas convertidas, 2 reviews 5⭐ (do círculo próximo)**. Concorrente direto: **Napper** (`id1491340863`).

A auditoria avalia **por que ninguém está pagando** e propõe um plano de inversão 10x.

---

## Top 5 conclusões (uma linha cada)

1. **0 conversões pode ter explicação técnica imediata:** RevenueCat possivelmente em modo TEST ([AppConfig.swift:49](Naplet/Core/Config/AppConfig.swift:49)) — confirmar antes de qualquer outra ação.
2. **5 dos 7 triggers de paywall declarados nunca disparam** ([PaywallTrigger.swift](Naplet/Features/Paywall/Models/PaywallTrigger.swift)) — usuário pode usar o app por semanas sem nunca ver o paywall.
3. **Onboarding pede SignIn ANTES de mostrar valor** — drop-off típico de 30-50% antes da tela 1 do "valor" do Naplet.
4. **Após o onboarding, NÃO há paywall com trial** — o Napper monetiza exatamente nesse pico de motivação; o Naplet desperdiça.
5. **Chave da OpenAI está hardcoded e exposta** ([AppConfig.swift:60](Naplet/Core/Config/AppConfig.swift:60)) — risco de abuso financeiro infinito; resolver hoje.

---

## Top 3 ações para começar amanhã

### 1. Confirmar RevenueCat em modo PROD (30 min)
Sem isso, todos os outros itens são esforço perdido. Pode ser **a explicação inteira** das 0 conversões.

### 2. Revogar e mover OpenAI key para proxy (1-2 dias)
Risco de abuso real e crescente a cada hora. Ver [14-auditoria-tecnica.md](auditoria-10x/14-auditoria-tecnica.md) seção 10.

### 3. Implementar paywall com trial-timeline ao final do onboarding (3-4 dias)
**Maior alavanca isolada do app inteiro.** Replica a estratégia do Napper (visto nos prints 7104-7108). Ver [15-plano-inversao-10x.md](auditoria-10x/15-plano-inversao-10x.md) item Q5.

---

## Métricas atuais conhecidas

| Métrica | Valor |
|---|---|
| Usuários ativos no Supabase | ~46 |
| Assinaturas convertidas | **0** |
| Reviews na App Store BR | 2 (ambas 5⭐, círculo próximo) |
| Versão | 1.1 |
| App Store ID | `id6758465410` |
| Concorrente | Napper (`id1491340863`), 4.9⭐ × 12K reviews BR, 1M+ famílias globalmente |
| Preço regular | ~R$ 114,90/ano |
| Preço Founders | R$ 89,90/ano |
| Trial | 14 dias (verificar) |

---

## Stack tecnológico real (confirmado por código)

| Camada | Tech | Status |
|---|---|---|
| UI | SwiftUI | ✅ |
| Auth | Supabase Auth (Apple/Google/Email) | ✅ |
| DB | Supabase Postgres com RLS em 13/13 tabelas | ✅ |
| Storage | Supabase Storage (avatares, docs, fotos) | ✅ |
| Realtime | **NÃO usado** (sync via fetch on demand) | ❌ |
| AI | OpenAI gpt-4o-mini (key hardcoded ⚠️) | ⚠️ |
| Pagamentos | RevenueCat (verificar se PROD) | ⚠️ |
| PDF | UIGraphicsPDFRenderer nativo | ✅ |
| Push | NotificationDelegate setup, sem APNs server enviando | ⚠️ |
| Apple Watch | Código existe, **`enableAppleWatch = false`** | 🔴 |
| Widgets | NapletSleepWidget funcional | ✅ |
| Sons | **`enableSounds = false`** (planejado para v1.2) | 🔴 |
| Cache offline | UserDefaults básico, sem CoreData/SwiftData | 🟡 |
| Analytics | TODO em PaywallTrigger.swift:201, **ZERO em produção** | 🔴 |

---

## Mapa de pastas importantes

| Pasta / Arquivo | O que tem |
|---|---|
| [`Naplet/App/`](Naplet/App/) | `NapletApp.swift`, `ContentView.swift`, `AppDelegate.swift` — entrada do app |
| [`Naplet/Core/Config/`](Naplet/Core/Config/) | `AppConfig.swift` (ENV, keys, feature flags), `Environment.swift` |
| [`Naplet/Core/Design/`](Naplet/Core/Design/) | `NapletColors`, tokens de design |
| [`Naplet/Core/Managers/`](Naplet/Core/Managers/) | `LocalizationManager`, `HapticManager`, `iOSConnectivityManager` |
| [`Naplet/Core/Utilities/`](Naplet/Core/Utilities/) | `Logger.swift` |
| [`Naplet/Data/Models/`](Naplet/Data/Models/) | `Baby`, `SleepRecord`, `Caregiver`, `ChatMessage`, etc. |
| [`Naplet/Data/Repositories/`](Naplet/Data/Repositories/) | `SleepRepository`, `BabyRepository`, etc. (camada de acesso a Supabase) |
| [`Naplet/Data/Services/`](Naplet/Data/Services/) | `OpenAIService.swift`, `PDFReportService.swift`, `RevenueCat/PurchaseService.swift` |
| [`Naplet/Features/Auth/`](Naplet/Features/Auth/) | SignInView (807 linhas) |
| [`Naplet/Features/Onboarding/`](Naplet/Features/Onboarding/) | OnboardingView (925 linhas, 12 steps inline) |
| [`Naplet/Features/Paywall/`](Naplet/Features/Paywall/) | PaywallView (717 linhas), PaywallViewModel, PaywallTrigger (7 triggers, **2 ativos**) |
| [`Naplet/Features/Dashboard/`](Naplet/Features/Dashboard/) | DashboardView (**1954 linhas** — refatorar) |
| [`Naplet/Features/Chat/`](Naplet/Features/Chat/) | ChatView, ChatViewModel, sistema de chat IA |
| [`Naplet/Features/Reports/`](Naplet/Features/Reports/) | ReportView que usa PDFReportService |
| [`Naplet/Features/Sleep/Feeding/Diaper/Bath/Health/Vaccination/Documents/`] | Features de tracking |
| [`Naplet/Features/Caregivers/`](Naplet/Features/Caregivers/) | Multi-cuidador (**sem realtime**) |
| [`Naplet/Features/Referral/`](Naplet/Features/Referral/) | Referral (**QR visual NÃO renderizado**, só URL) |
| [`NapletWatch/`](NapletWatch/) | App Watch (**desabilitado**) |
| [`NapletWidget/`](NapletWidget/) | Widget de sono ativo |
| [`Database/migrations/`](Database/) | SQL de Supabase |
| [`concorrente-napper-prints/`](concorrente-napper-prints/) | 30 prints do Napper para análise (raiz do projeto, não no worktree) |

---

## Sumário dos 16 documentos da auditoria

| # | Documento | Foco |
|---|---|---|
| **00** | [INDEX](auditoria-10x/00-INDEX.md) | **Este arquivo.** Sumário executivo. |
| **01** | [Inventário de telas](auditoria-10x/01-inventario-telas.md) | 62 Views catalogadas + arquivos gigantes |
| **02** | [Fluxos críticos](auditoria-10x/02-fluxos-criticos.md) | 9 fluxos do usuário, tela a tela |
| **03** | [Mapeamento de paywall](auditoria-10x/03-paywall-mapping.md) | Os 7 triggers e quais disparam |
| **04** | [Estado das features](auditoria-10x/04-estado-features.md) | Quais funcionam de verdade |
| **05** | [Análise dos prints Napper](auditoria-10x/05-analise-prints-napper.md) | 30 screenshots dissecados |
| **06** | [Análise do site Napper](auditoria-10x/06-analise-site-napper.md) | napper.app/pt |
| **07** | [Análise da App Store Napper](auditoria-10x/07-analise-appstore-napper.md) | ASO de referência |
| **08** | [Comparativo Naplet vs Napper](auditoria-10x/08-comparativo-naplet-vs-napper.md) | 20 dimensões — placar 1×15×3 |
| **09** | [Auditoria do onboarding](auditoria-10x/09-auditoria-onboarding.md) | 12 telas + 3 erros maiores |
| **10** | [Auditoria do paywall](auditoria-10x/10-auditoria-paywall.md) | 5 ajustes críticos com escopo |
| **11** | [Auditoria do Chat IA](auditoria-10x/11-auditoria-chat-ia.md) | Diferencial vs Napper |
| **12** | [Auditoria do PDF](auditoria-10x/12-auditoria-pdf.md) | Trunfo subutilizado |
| **13** | [Auditoria de design](auditoria-10x/13-auditoria-design.md) | Sensação premium |
| **14** | [Auditoria técnica](auditoria-10x/14-auditoria-tecnica.md) | RED FLAGS técnicos |
| **15** | [Plano de Inversão 10x](auditoria-10x/15-plano-inversao-10x.md) | 3 horizontes + 29 ações priorizadas |

---

## Os 10 pontos críticos (em ordem de impacto em conversão)

| # | Crítico | Por que importa | Ver doc |
|---|---|---|---|
| 1 | **RevenueCat possivelmente em modo TEST** | Pode explicar 0 conversões inteiras | 14, 15 (E1) |
| 2 | **OpenAI key exposta no código** | Risco de abuso financeiro | 14, 15 (E2) |
| 3 | **Sem paywall após onboarding** | Pico de motivação desperdiçado; Napper monetiza aqui | 09, 10, 15 (Q5) |
| 4 | **5/7 triggers de paywall fantasmas** | 71% da pressão planejada não acontece | 03, 10, 15 (Q1) |
| 5 | **SignIn antes do valor** | Drop-off de 30-50% antes da tela 1 de promessa | 09, 15 (Q6) |
| 6 | **Chat IA com primeira mensagem genérica e sem contexto completo** | Desperdiça o único diferencial real vs Napper | 11, 15 (Q8, M7) |
| 7 | **PDF amador (sem logo, sem peso, sem assinatura)** | Trunfo único contra Napper, mal entregue | 12, 15 (Q10, M8) |
| 8 | **Sem analytics no paywall** | Impossível medir/iterar/A-B test | 14, 15 (Q12) |
| 9 | **Multi-cuidador sem realtime + risco de RLS retroativo** | Promessa não entregue; risco de privacidade | 02, 04, 15 (M5) |
| 10 | **Sem sons de dormir (table stakes)** | Napper tem 30+, Naplet tem 0 | 04, 15 (M4) |

---

## Como o Edy deve usar este pacote

1. **Hoje:** ler 00-INDEX.md (este) + 14-auditoria-tecnica.md (seções E1, E2). Resolver os 3 itens de emergência.
2. **Esta semana:** ler 09 (onboarding), 10 (paywall), 15 (plano). Decidir os 3 primeiros Quick Wins.
3. **Próximas 2 semanas:** executar Q1, Q2, Q3, Q11, Q12 (impacto rápido, esforço baixo).
4. **Próximo mês:** Q5 (paywall pós-onboarding) e Q6 (SignIn pós-onboarding) — os dois maiores movimentos.
5. **Ler quando precisar de profundidade:** docs 02, 03, 11, 12 quando for mexer naquela feature específica.
6. **Mostrar para mim (Claude futuro):** este 00-INDEX.md basta para eu retomar contexto. Se quiser que eu execute algo do plano, anexa o doc específico (ex: doc 15) ao prompt.

---

## Conclusão do auditor

O Naplet não está com problema de **marketing**. Está com problema de **funil**. As features estão prontas (várias delas, melhores que o Napper). O paywall está bonito (mas sub-conectado). O onboarding está estruturado (mas na ordem errada). O Chat IA tem infraestrutura (mas não personaliza). O PDF é gerado de verdade (mas não impressiona).

Não falta capacidade técnica. Falta **estratégia de conversão amarrada às features que já existem**.

A boa notícia: a maior parte das mudanças de maior impacto custa **dias, não meses**. Se o Edy executar os 3 itens de emergência + 5-6 Quick Wins nos próximos 30 dias, é razoável esperar **conversão saindo de 0% para 1-3% real** — o que já transforma 46 usuários em 1-2 assinantes pagantes/mês, e cria base medível para iterar do plano daí em diante.

A direção é clara. Falta executar.
