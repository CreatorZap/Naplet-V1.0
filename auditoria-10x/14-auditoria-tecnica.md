# 14 - Auditoria Técnica Bruta

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)
**Escopo:** 137 arquivos `.swift` em `Naplet/`

---

## Sumário de números

| Métrica | Valor | Status |
|---|---|---|
| Arquivos Swift | 137 | OK |
| `print(` em produção | 46 | ⚠️ Muitos |
| Force unwraps `!` | 14-15 | ⚠️ Alguns perigosos |
| TODOs / FIXMEs | 12 | ⚠️ 4 são bloqueadores |
| Views >300 linhas | 10 | ⚠️ Refatorar |
| Sheets sem `onDismiss` | 5+ | ⚠️ UX risk |
| Tabelas com RLS | **13/13** | ✅ Excelente |
| Retry implementado | NÃO | ❌ Config existe, sem uso |
| Cache offline (CoreData/SwiftData) | NÃO | ❌ Apenas UserDefaults |
| API keys hardcoded | **2 críticas** | 🔴 **OpenAI exposta** |
| FatalError / Assertion | 0 | ✅ Bom |

---

## 1. Print statements em produção

**46 prints** em 11 arquivos.

**Top offenders:**

| Arquivo | Count |
|---|---|
| [LocalizationManager.swift](Naplet/Core/Managers/LocalizationManager.swift) | 17 |
| [iOSConnectivityManager.swift](Naplet/Core/Managers/iOSConnectivityManager.swift) | 10 |
| [PurchaseService.swift](Naplet/Data/Services/RevenueCat/PurchaseService.swift) | 7 |
| [SettingsView.swift](Naplet/Features/Settings/Views/SettingsView.swift) | 4 |
| Outros 7 | 1-2 cada |

**Risco:** prints em produção vazam dados (nomes, IDs, contexto) para o Console.app. Em alguns casos, podem ser visíveis em logs de crash submetidos à Apple.

**Fix:** envolver tudo em `#if DEBUG`:

```swift
#if DEBUG
print("...")
#endif
```

Ou trocar para `Logger` (já existe em [Logger.swift](Naplet/Core/Utilities/Logger.swift)).

**Esforço:** 1 dia.

---

## 2. Force unwraps perigosos

**14-15 ocorrências.** A maioria em mock data e previews (aceitável). Mas algumas em produção real:

**Críticos (produção):**

- [Logger.swift:110](Naplet/Core/Utilities/Logger.swift:110) — `context!` em mensagem de erro. Se `context` for nil, log crasha. Ironia.
- [PDFReportService.swift:1025](Naplet/Data/Services/PDF/PDFReportService.swift:1025) — `applicationDate!` em vacina. Se vacina nunca foi aplicada, crash.
- [SleepTrackingViewModel.swift:66](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:66) — `startTime!`. Se sessão nunca iniciou, crash.
- [PaywallView.swift:385,387](Naplet/Features/Paywall/Views/PaywallView.swift:385) — `URL(string:)!` para terms/privacy. Hardcoded, baixo risco mas evitável com `URL(string:)?`.

**Não-críticos (mock/preview):**

- 11x `Calendar.current.date(byAdding:)!` em [Baby.swift](Naplet/Data/Models/Baby.swift), [SleepRecord.swift](Naplet/Data/Models/SleepRecord.swift), [Caregiver.swift](Naplet/Data/Models/Caregiver.swift). Em previews, OK. Mas se algum desses mocks vazar para produção…

**Fix:** trocar `!` por `guard let` ou default sensato. Esforço: 4-6h.

---

## 3. TODOs / FIXMEs / HACK

**12 TODOs**, dos quais **4 são bloqueadores**:

| TODO | Arquivo:linha | Severidade |
|---|---|---|
| "Get actual baby ID and user ID" | [SleepTrackingViewModel.swift:62](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:62) | 🔴 Salva com UUID errado |
| "Save to database" | [SleepTrackingViewModel.swift:100](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:100) | 🔴 Persistência incerta |
| "Save to Supabase" | [SleepTrackingViewModel.swift:159](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:159) | 🔴 |
| "SUBSTITUIR PELO APP ID REAL" | [SupportViewModel.swift:155](Naplet/Features/Support/ViewModels/SupportViewModel.swift:155) | 🔴 Link App Store quebrado |
| "Update in Supabase" (x3) | [SettingsViewModel.swift:213,268,308](Naplet/Features/Settings/ViewModels/SettingsViewModel.swift:213) | 🟡 Settings podem não persistir |
| "Implementar marcação de Founder no perfil" | [PaywallViewModel.swift:345](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:345) | 🟡 Promete badge, não entrega |
| "Track with analytics service" | [PaywallTrigger.swift:201](Naplet/Features/Paywall/Models/PaywallTrigger.swift:201) | 🟡 Sem analytics |
| "Add pumping-specific fields" | [FeedingViewModel.swift:318](Naplet/Features/Feeding/ViewModels/FeedingViewModel.swift:318) | 🟢 Cosmético |
| "Enviar feedback para analytics/email" | [RatingPromptView.swift:146](Naplet/Features/Rating/RatingPromptView.swift:146) | 🟡 |
| "Check ongoing session in DB" | [SleepTrackingViewModel.swift:155](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:155) | 🟡 Pode duplicar |

**Esforço para fechar todos:** 3-5 dias.

---

## 4. Funções / Views com mais de 80-300 linhas

**Top 10 arquivos por LOC:**

| Arquivo | Linhas | Problema |
|---|---|---|
| [DashboardView.swift](Naplet/Features/Dashboard/Views/DashboardView.swift) | **1954** | Body de 185 linhas |
| [PDFReportService.swift](Naplet/Data/Services/PDF/PDFReportService.swift) | 1513 | Render gigante |
| [OnboardingView.swift](Naplet/Features/Onboarding/Views/OnboardingView.swift) | 925 | 12 steps inline |
| [SleepHistoryView.swift](Naplet/Features/History/Views/SleepHistoryView.swift) | 898 | – |
| [DashboardViewModel.swift](Naplet/Features/Dashboard/ViewModels/DashboardViewModel.swift) | 821 | – |
| [SettingsView.swift](Naplet/Features/Settings/Views/SettingsView.swift) | 819 | Body de 795 linhas (!!) |
| [SignInView.swift](Naplet/Features/Auth/Views/SignInView.swift) | 807 | Body de 807 linhas (!!) |
| [NotificationService.swift](Naplet/Core/Services/NotificationService.swift) | 747 | – |
| [PaywallView.swift](Naplet/Features/Paywall/Views/PaywallView.swift) | 717 | Body de 693 linhas (!!) |
| [SleepRecord.swift](Naplet/Data/Models/SleepRecord.swift) | 697 | Mock data inflando |

**Implicação prática em SwiftUI:** quanto maior o body, mais o type-checker demora a recompilar e a árvore precisa ser re-avaliada. DashboardView com 1954 linhas é um problema **medível** em build time e em FPS.

**Fix:** quebrar em sub-views por responsabilidade. Esforço: 5-10 dias acumulados.

---

## 5. Sheets/Covers sem `onDismiss`

**5+ casos** onde `.sheet(isPresented:)` não tem `onDismiss` callback:

- [SignInView.swift:70](Naplet/Features/Auth/Views/SignInView.swift:70) — sheet email signin
- [ChatView.swift:91,94](Naplet/Features/Chat/Views/ChatView.swift:91) — sheet de paywall e história
- [CaregiversView.swift:106,109](Naplet/Features/Caregivers/Views/CaregiversView.swift:106) — sheet de invite
- [DashboardView.swift:99-172](Naplet/Features/Dashboard/Views/DashboardView.swift:99) — múltiplos sheets

**Risco:** view fica fechada mas estado não atualiza, ou abre em race condition.

**Fix:** padronizar `.sheet(isPresented:onDismiss:)` em todo lugar. Esforço: 2-3h.

---

## 6. RLS no Supabase

✅ **EXCELENTE.** **13/13 tabelas com RLS habilitado**:

profiles, babies, caregivers, invites, sleep_records, night_wakings, baby_documents, document_files, document_types, baby_vaccinations, vaccines, referral_codes, referrals.

**Caveat:** ter RLS ativado não garante que as policies estão corretas. Audit recomendada das policies em si:
- Caregivers podem ver dados retroativos do bebê? (provavelmente sim, ver doc 04 — risco de vazamento)
- Usuário pode acessar bebê de outro usuário?
- Invite codes têm expiração validada server-side?

**Fix:** revisar policies de cada tabela com perspective "usuário malicioso". Esforço: 1 dia.

---

## 7. Tratamento de erro visível

**254 blocos `catch`** no código, muitos só fazem `Logger.error()` sem mostrar nada ao usuário.

**Exemplos:**
- [DocumentRepository](Naplet/Data/Repositories/DocumentRepository.swift) — múltiplos catch silenciosos
- [PurchaseService.swift:222](Naplet/Data/Services/RevenueCat/PurchaseService.swift:222) — falha silenciosa em compra
- [NotificationService.swift](Naplet/Core/Services/NotificationService.swift) — 8+ catches sem feedback

**Risco:** usuário toca em "Salvar", nada acontece visualmente, ele tenta de novo, frustração crescente.

**Fix:** padrão `@State var errorMessage: String?` + `.alert(item:)` em cada View que faz call de rede. Pode ser componente reusável `NapletErrorBanner`. Esforço: 2-3 dias.

---

## 8. Retry logic

❌ **NÃO IMPLEMENTADO.**

`AppConfig.API.retryAttempts = 3` e `retryDelay = 1` declarados, mas nenhuma função usa. Falha de rede transiente = mensagem perdida.

**Fix:** wrapper `withRetry`:

```swift
func withRetry<T>(attempts: Int = 3, delay: TimeInterval = 1.0,
                   operation: () async throws -> T) async throws -> T {
    var lastError: Error?
    for attempt in 0..<attempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            if attempt < attempts - 1 {
                try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt+1) * 1_000_000_000))
            }
        }
    }
    throw lastError!
}
```

Aplicar em: OpenAIService, todos os Repositories.

**Esforço:** 4-6h.

---

## 9. Cache offline

- **UserDefaults:** 70 referências. Cache manual básico (preferences, founder period, profile parts).
- **CoreData / SwiftData:** zero.

**Implicação:** sem rede, app fica em estado degradado. Sleep tracking pode parar.

**Fix sugerido (médio prazo):** SwiftData (iOS 17+) para cache de `SleepRecord`, `FeedingRecord`, `DiaperRecord`. Sync periódico com Supabase. Esforço: 5-10 dias.

---

## 10. API keys hardcoded — **CRÍTICO**

🔴 **OpenAI key EXPOSTA** em [AppConfig.swift:60](Naplet/Core/Config/AppConfig.swift:60):

```swift
private static let embeddedAPIKey = "REDACTED_OPENAI_KEY_REVOKED_2026_05"
```

**Esta chave está no repositório git.** Se o repo for público (verificar), qualquer pessoa pode pegar e gerar custos infinitos na conta OpenAI do Edy.

**Mesmo se privado**, está exposta em qualquer build do app — basta extrair com `strings` no `.app` em qualquer iPhone.

**Ação imediata (hoje):**

1. **REVOKE a chave atual** em https://platform.openai.com/api-keys
2. Gerar nova chave
3. **NÃO colocar no código.** Mover para um proxy server (Edge Function no Supabase, por exemplo) que faz a chamada para OpenAI server-side.
4. App envia request ao proxy, proxy chama OpenAI com a chave que só ele conhece.

Outras keys:
- RevenueCat (`appl_ZmzpzrfPorQGHpEwFEdkpkkJtvq`) — chave pública por design, OK.
- Google OAuth IDs — públicos por design, OK.

**Esforço:** 1-2 dias para implementar proxy + remover chave.
**Severidade:** **MÁXIMA**. Cada hora que passa pode estar sendo abusada.

---

## 11. Modo TEST do RevenueCat

[AppConfig.swift:49](Naplet/Core/Config/AppConfig.swift:49) declara chave RevenueCat com prefixo `test_`:

```swift
static let revenueCatAPIKey = "appl_ZmzpzrfPorQGHpEwFEdkpkkJtvq"
```

(Prefixo `appl_` = produção iOS na verdade. Verificar se é mesma chave do dashboard de produção do RevenueCat.)

**O RELATORIO_APP_STORE_v2.md** dizia "RevenueCat API Key de TESTE" — confirmar com o Edy se hoje está em modo prod ou se ainda é dev key.

Se estiver em test mode:
- Compras são simuladas, **nunca** chegam à App Store Connect
- Receita zero porque nada está sendo cobrado
- **Pode explicar parte do "0 conversões"!**

**Ação:** confirmar com RevenueCat dashboard. Se test, trocar para produção e re-testar fluxo inteiro. Esforço: 30 min.

---

## 12. FatalError / Precondition / AssertionFailure

✅ **Zero.** Bom. Sem crashes intencionais.

---

## Os 7 RED FLAGS técnicos críticos (priorizados)

### 🔴 RF-1: API Key OpenAI exposta — **AÇÃO HOJE**
Custo potencial: ilimitado (key abusada). Esforço fix: 1-2 dias. **Faça primeiro.**

### 🔴 RF-2: Confirmar se RevenueCat está em modo PROD
Se test, **isto sozinho explica 0 conversões.** Esforço fix: 30 min.

### 🔴 RF-3: TODO crítico em Sleep tracking (4 TODOs)
Sono pode estar salvando errado. Esforço fix: 1-2 dias.

### 🔴 RF-4: TODO "SUBSTITUIR APP ID REAL" no SupportViewModel
Link "Avalie no App Store" quebra antes de bater. Esforço fix: 5 min.

### 🟠 RF-5: Sem retry em chamadas OpenAI/Supabase
Rede instável = dados perdidos. Esforço fix: 4-6h.

### 🟠 RF-6: 254 catches silenciosos
Falhas invisíveis ao usuário. Esforço fix: 2-3 dias.

### 🟠 RF-7: DashboardView com 1954 linhas
Performance e maintainability. Esforço fix: 5-10 dias (refatoração grande).

---

## Conclusão

A engenharia do Naplet é **boa em fundamentos** (RLS completo, zero fatalErrors, tipagem Swift forte, integração com Supabase/OpenAI/RevenueCat funcionando). Mas tem **3 buracos imediatos**:

1. **Segurança:** OpenAI key exposta. Resolver hoje.
2. **Receita:** RevenueCat possivelmente em test mode. Confirmar agora.
3. **Persistência:** TODOs em Sleep tracking. Resolver na próxima sprint.

E **2 dívidas estruturais**:

4. Files gigantes (DashboardView, OnboardingView, etc.)
5. Sem retry, sem cache offline robusto

A nota técnica é **6.5/10** — funciona, com alguns pontos crônicos para resolver no horizonte de 30-60 dias. Mas RF-1 e RF-2 não esperam.
