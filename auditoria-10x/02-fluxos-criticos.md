# 02 - Fluxos Críticos do Usuário

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## A. Onboarding completo (primeira abertura até dashboard)

```
App launch
  ↓
ContentView → checa AppState.hasCompletedOnboarding
  ↓ (false)
SignInView (Apple / Google / Email)   ← ❌ FRICTION ANTES DO VALOR
  ↓ (autenticado)
OnboardingView (TabView, 12 steps)
  ├─ 1. Welcome           "Noites tranquilas começam aqui"
  ├─ 2. Benefits          3 pilares (clareza, sono, sincronização)
  ├─ 3. Differentials     "3x mais barato" (ancoragem vaga, sem R$)
  ├─ 4. Attribution       (skip OK)
  ├─ 5. Goals             (skip OK)
  ├─ 6. Baby Name         OBRIGATÓRIO
  ├─ 7. Baby Birth        OBRIGATÓRIO
  ├─ 8. Baby Gender       OBRIGATÓRIO
  ├─ 9. Relationship      OBRIGATÓRIO
  ├─ 10. Confirmation     review
  ├─ 11. Loading          spinner com 4 mensagens
  └─ 12. Completion       confetti + "Começar a usar"
  ↓
DashboardView (MainTabView)
```

**Duração estimada (caminho feliz):** ~115 segundos (1m55s) entre primeiro toque e dashboard.
**Toques aproximados:** ~50 (formulários + next em cada step).
**Paywall durante onboarding:** ❌ **NÃO APARECE**. Usuário completa onboarding inteiro sem saber o preço.
**Frição principal:** SignIn vem ANTES do value prop ([ContentView.swift:66-68](Naplet/App/ContentView.swift:66)).

---

## B. Primeiro registro de sono

```
DashboardView (tap "Sono")
  ↓
SleepTrackingView (modal)
  ├─ Tap sleep type (crisp / nap / unknown)        1 toque
  ├─ Tap location (crib, bed, stroller, car)       1 toque
  ├─ Tap mood (happy / neutral / upset)            1 toque
  └─ Tap "Iniciar"                                  1 toque
  ↓ (timer roda em background)
  ↓
EndSleepSheet
  ├─ Tap "Encerrar"     1 toque
  └─ Tap "Salvar"       1 toque
  ↓
return DashboardView (dados atualizados via Combine)
```

**Toques totais:** ~6-7 (excluindo o tempo de timer).
**⚠️ Risco crítico:** [SleepTrackingViewModel.swift:62](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:62) tem TODO `Get actual baby ID and user ID` e linha 100 tem `TODO: Save to database`. Registros podem não estar persistindo corretamente para todos os casos.
**Paywall:** não dispara.

---

## C. Chat IA (com limite de 5 mensagens free)

```
DashboardView (tap "AI Chat")
  ↓
ChatView (modal)
  ├─ Vê primeira mensagem genérica:
  │   "Olá! Sou o assistente de sono do Naplet. Como posso ajudar?"
  ├─ Vê chips de "perguntas sugeridas" por idade (6-8 chips)
  └─ Tap em chip OU digita pergunta → send
  ↓
ChatViewModel.sendMessage()
  ├─ Verifica hasReachedLimit (5/mês)
  ├─ Monta BabyContext (nome + idade + sono de HOJE)
  │   ❌ não inclui: fraldas, alimentação, padrão da semana
  └─ OpenAI API call (gpt-4o-mini, sem retry)
  ↓
Resposta chega em bloco único (sem streaming) após 2-5s
  ↓
Counter `remainingFreeChats` decrementa
  ↓ (quando ≤3)
Banner amarelo: "3 mensagens restantes"
  ↓ (na 6ª tentativa)
PaywallView (trigger: .aiChatLimit)
```

**Triggers de paywall:** apenas `.aiChatLimit`, e só na 6ª tentativa.
**Limite resetado:** mensalmente (AppStorage em [ChatViewModel.swift:23](Naplet/Features/Chat/ViewModels/ChatViewModel.swift:23)).
**Falhas:** sem retry. Rede instável = mensagem perdida.

---

## D. Geração de PDF para pediatra

```
DashboardView (tap "Relatório")
  ↓
ReportView (modal)
  └─ .task { viewModel.generateReport() }    ← gera PDF na abertura
  ↓
PDFReportService.generateCompletePDF()  ← UIGraphicsPDFRenderer real
  ├─ Header roxo (sem logo)
  ├─ Sono (gráfico de barras qualitativo)
  ├─ Alimentação (tabela)
  ├─ Fralda (contagem)
  ├─ Temperatura
  ├─ Medicação
  └─ Vacinação
  ↓
PDFPreviewView (PDFKit, máx 400pt altura)
  ↓ (tap "Compartilhar")
  ↓
🚨 Checa SubscriptionManager.canExportPDF
  ├─ Free → PaywallView(.pdfReport)  *trigger declarado mas confirmou que NÃO está implementado em PaywallTrigger.swift uniformemente*
  └─ Premium → ShareSheet (UIActivityViewController)
```

**Nome do arquivo:** `Naplet_{baby.name}_{YYYY-MM-DD}.pdf` ✅
**Compartilhamento:** WhatsApp/Mail/AirDrop nativos.
**Buracos:** sem logo, sem campo de peso, sem assinatura do pediatra, sem espaço para notas. Design "amador" (cores fortes, sem tipografia consistente).

---

## E. Convite de cuidador

```
DashboardView (tap "Cuidadores")
  ↓
CaregiversView
  └─ Tap "+ Convidar"
  ↓
🚨 Checa SubscriptionManager.canInviteCaregivers
  ├─ Free → PaywallView(.inviteCaregiver)    ← paywall HARD ao tentar criar
  └─ Premium
       ↓
       CreateInviteSheet
       ├─ Seleciona role (parent/grandparent/nanny/other)
       ├─ Email opcional
       └─ Tap "Gerar Código"
       ↓
       CaregiverRepository.generateInviteCode()  → "AB12CD34" (8 chars)
       ↓
       Botão "Share" → UIActivityViewController
       ├─ WhatsApp/SMS com mensagem pré-formatada
       └─ Botão "Copy" → clipboard

Convidado:
  Abre app → AcceptInviteView → cola código → RPC accept_invite()
  ↓
  Registro em caregivers (accepted_at)
  ↓
  ❌ SEM realtime sync. Outro cuidador só vê mudanças ao reabrir o app.
```

**Falha de UX:** sem QR code, sem deep link. Só código manual.
**🔴 Risco de segurança:** cuidador aceito vê histórico COMPLETO retroativo (sem filtro por `accepted_at`).

---

## F. Carteira de vacinação (cadastro de 1 vacina)

```
DashboardView (tap "Vacinação")
  ↓
VaccinationDashboardView (lista vinda do Supabase, NÃO hardcoded)
  └─ Tap "+ Adicionar"
  ↓
VaccinationDetailView
  ├─ Tap nome da vacina (dropdown)        1 toque
  ├─ DatePicker data administração         1 toque
  ├─ Notas (opcional)                      0-1 toques
  └─ Tap "Salvar"                          1 toque
  ↓
return VaccinationDashboardView (status atualizado)
```

**Toques:** ~4-5.
**Paywall:** não dispara.

---

## G. Carteira de documentos (upload de 1)

```
DashboardView (tap "Documentos")
  ↓
DocumentsView (lista filtrável por tipo/favorito/expiração)
  └─ Tap "+ Adicionar"
  ↓
AddDocumentView
  ├─ Tap tipo (CPF, RG, Passaporte…)       1 toque
  ├─ Title (TextField)                     1 toque
  ├─ Número (opcional)                     0-1 toques
  ├─ Datas issue/expiration (opcionais)    0-2 toques
  ├─ PhotosPickerItem (upload)             1 toque
  └─ Tap "Salvar"                          1 toque
  ↓
return DocumentsView
```

**Toques:** ~5-6. Paywall não dispara.

---

## H. Referral por QR Code

```
DashboardView → ReferralView
  ├─ Mostra código texto (ex: "naplet-xyz")
  ├─ ❌ QR Code visual NÃO renderizado (só URL texto: https://naplet.app/r/{code})
  ├─ Tap "Share" → UIActivityViewController
  └─ Tap "Copy" → clipboard

Receptor:
  Scan QR (impossível, não há imagem) OU
  Cola código → AcceptInviteView → Accept
```

**Falha grave:** o componente principal (QR) não existe visualmente. Só URL texto. O share envia texto, não imagem QR.

---

## I. Compra de assinatura

```
Entry points (5 disparam, 2 não):
  ├─ aiChatLimit          ✅ DISPARA na 6ª msg
  ├─ inviteCaregiver      ✅ DISPARA ao tentar criar convite
  ├─ pdfReport            ❌ DECLARADO no enum, sem implementação no ReportView
  ├─ historyLimit         ❌ DECLARADO no enum, sem implementação
  ├─ multipleBabies       ❌ DECLARADO no enum, AddBabyView NÃO bloqueia
  ├─ settingsUpgrade      ❌ DECLARADO no enum, nunca acionado
  └─ softPrompt           ⚠️  Default genérico (pré-config como padrão no ViewModel)
  ↓
PaywallView
  ├─ Header: badge "OFERTA DE LANÇAMENTO" (se isFoundersPeriod)
  ├─ Countdown da Founders (até 22-Abril-2026)
  ├─ 2 planos: Mensal vs Anual (anual com "Best Value")
  ├─ Preço anual riscado (ancoragem temporal)
  ├─ 3 reviews fictícias (5⭐, sem números agregados)
  ├─ Trust badges no footer (pequenos, "14 dias grátis" escondido)
  ├─ CTA: "Garantir preço de Founder" (Founders) | "Assinar Agora" (Regular ❌)
  └─ Links Terms/Privacy ✅
  ↓
RevenueCat SDK processa
  ↓
✅ Sucesso → dismiss + benefícios desbloqueados
❌ Falha → alert padrão iOS
❌ Sem oferta secundária após recusa (sem fallback, sem trial estendido)
```

**Conclusão:** apenas **2 dos 7 triggers efetivamente disparam** nas primeiras 48h de uso. Trigger fantasma é o maior leak do funil.

---

## Frição agregada por fluxo

| Fluxo | Toques | Paywall? | Risco principal |
|---|---|---|---|
| A. Onboarding | ~50 | ❌ ausente | Auth antes do valor; sem upsell no pico de motivação |
| B. Sono | 6-7 | ❌ não | TODOs críticos no ViewModel (persistência) |
| C. Chat IA | depende | ⚠️ só no 6º msg | Sem streaming, sem retry, sem contexto completo |
| D. PDF | 2-3 | ⚠️ paywall ao share | Sem logo, sem peso, sem assinatura |
| E. Cuidador | 5-6 | ✅ HARD no free | Sem realtime, risco de RLS |
| F. Vacina | 4-5 | ❌ | OK |
| G. Documentos | 5-6 | ❌ | OK |
| H. Referral | 2-3 | ❌ | QR visual não renderizado |
| I. Assinatura | 1-2 | – | 5/7 triggers fantasma + CTA fraco em Regular |
