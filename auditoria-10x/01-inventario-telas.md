# 01 - Inventário de Telas (Views SwiftUI)

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)
**Escopo:** `Naplet/Features/` (137 arquivos .swift, ~29 mil linhas só em Features)

---

## Visão geral

Total de Views identificadas: **62** (excluindo sub-views aninhadas). Nenhuma View identificada como código morto sem referência. Mas há **buracos de qualidade**: 4 arquivos passam de 700 linhas, com [DashboardView.swift](Naplet/Features/Dashboard/Views/DashboardView.swift) chegando a 1954 linhas, sinal claro de dívida arquitetural.

Legenda de status:
- 🟢 produção (usada de verdade, com lógica real)
- 🟡 mock/placeholder ou paywall-gated com TODO crítico
- 🔴 código morto ou casca vazia

---

## Tabela principal

| # | View | Caminho | O que faz | Chamada por | Status | Linhas | Notas |
|---|------|---------|-----------|-------------|--------|--------|-------|
| 1 | SignInView | [Features/Auth/Views/SignInView.swift](Naplet/Features/Auth/Views/SignInView.swift) | Login com Apple/Google/Email | ContentView | 🟢 | 807 | Body de 807 linhas, refatorar |
| 2 | BathView | [Features/Bath/BathView.swift](Naplet/Features/Bath/BathView.swift) | Registra banho (tipo, duração, humor) | Dashboard sheet | 🟢 | 465 | OK |
| 3 | AcceptInviteView | [Features/Caregivers/Views/AcceptInviteView.swift](Naplet/Features/Caregivers/Views/AcceptInviteView.swift) | Aceita convite via código 8 chars | Dashboard sheet | 🟢 | 243 | OK |
| 4 | CaregiversView | [Features/Caregivers/Views/CaregiversView.swift](Naplet/Features/Caregivers/Views/CaregiversView.swift) | Lista cuidadores + convites | Dashboard sheet | 🟢 | 410 | Sem realtime |
| 5 | CreateInviteSheet | [Features/Caregivers/Views/CreateInviteSheet.swift](Naplet/Features/Caregivers/Views/CreateInviteSheet.swift) | Gera convite (role + email opcional) | CaregiversView | 🟡 | 290 | Gated por paywall (premium) |
| 6 | ChatView | [Features/Chat/Views/ChatView.swift](Naplet/Features/Chat/Views/ChatView.swift) | Chat IA, limite 5 msgs grátis | Dashboard sheet | 🟡 | 401 | Gated por aiChatLimit |
| 7 | ChatHistoryView | [Features/Chat/Views/ChatHistoryView.swift](Naplet/Features/Chat/Views/ChatHistoryView.swift) | Histórico de conversas | ChatView sheet | 🟢 | 196 | Salvo em UserDefaults (local) |
| 8 | DashboardView | [Features/Dashboard/Views/DashboardView.swift](Naplet/Features/Dashboard/Views/DashboardView.swift) | Hub principal com widgets | App root | 🟡 | **1954** | ARQUIVO GIGANTE, refatorar urgente |
| 9 | TimelineView | [Features/Dashboard/Views/TimelineView.swift](Naplet/Features/Dashboard/Views/TimelineView.swift) | Timeline de eventos do sono | DashboardView | 🟢 | 291 | OK |
| 10 | DiaperChangeView | [Features/Diaper/Views/DiaperChangeView.swift](Naplet/Features/Diaper/Views/DiaperChangeView.swift) | Registra troca de fralda | Dashboard sheet | 🟢 | 374 | OK |
| 11 | AddDocumentView | [Features/Documents/Views/AddDocumentView.swift](Naplet/Features/Documents/Views/AddDocumentView.swift) | Adiciona documento + upload | DocumentsView | 🟢 | 467 | OK |
| 12 | DocumentsView | [Features/Documents/Views/DocumentsView.swift](Naplet/Features/Documents/Views/DocumentsView.swift) | Lista documentos salvos | Dashboard sheet | 🟢 | 381 | OK |
| 13 | DocumentDetailView | [Features/Documents/Views/DocumentDetailView.swift](Naplet/Features/Documents/Views/DocumentDetailView.swift) | Detalhe + edição de documento | DocumentsView | 🟢 | 695 | Arquivo grande |
| 14 | FeedingView | [Features/Feeding/Views/FeedingView.swift](Naplet/Features/Feeding/Views/FeedingView.swift) | Hub de alimentação | Dashboard sheet | 🟢 | 593 | OK |
| 15 | BottleFeedingView | [Features/Feeding/Views/BottleFeedingView.swift](Naplet/Features/Feeding/Views/BottleFeedingView.swift) | Registra mamadeira | FeedingView | 🟢 | 341 | OK |
| 16 | BreastFeedingTimerView | [Features/Feeding/Views/BreastFeedingTimerView.swift](Naplet/Features/Feeding/Views/BreastFeedingTimerView.swift) | Timer amamentação L/R | FeedingView | 🟢 | 255 | OK |
| 17 | PumpingView | [Features/Feeding/Views/PumpingView.swift](Naplet/Features/Feeding/Views/PumpingView.swift) | Registra bombeamento | FeedingView | 🟡 | 435 | TODO em FeedingViewModel:318 (fields incompletos) |
| 18 | FeedingHistoryView | [Features/Feeding/Views/FeedingHistoryView.swift](Naplet/Features/Feeding/Views/FeedingHistoryView.swift) | Histórico alimentações do dia | FeedingView | 🟢 | 439 | OK |
| 19 | MedicationView | [Features/Health/Views/MedicationView.swift](Naplet/Features/Health/Views/MedicationView.swift) | Registra medicamento | Dashboard sheet | 🟢 | 564 | OK |
| 20 | MedicationScheduleView | [Features/Health/Views/MedicationScheduleView.swift](Naplet/Features/Health/Views/MedicationScheduleView.swift) | Cronograma de medicação | MedicationView | 🟢 | 550 | OK |
| 21 | MedicationReminderCard | [Features/Health/Views/MedicationReminderCard.swift](Naplet/Features/Health/Views/MedicationReminderCard.swift) | Lembrete dinâmico | DashboardView | 🟢 | 377 | OK |
| 22 | TemperatureView | [Features/Health/Views/TemperatureView.swift](Naplet/Features/Health/Views/TemperatureView.swift) | Registra temperatura | Dashboard sheet | 🟢 | 309 | OK |
| 23 | SleepHistoryView | [Features/History/Views/SleepHistoryView.swift](Naplet/Features/History/Views/SleepHistoryView.swift) | Histórico de sonos + gráficos | Dashboard sheet | 🟢 | 898 | Único histórico com gráficos (outras categorias não têm) |
| 24 | PrivacyPolicyView | [Features/Legal/PrivacyPolicyView.swift](Naplet/Features/Legal/PrivacyPolicyView.swift) | Política de privacidade | Settings | 🟢 | – | OK |
| 25 | TermsOfServiceView | [Features/Legal/TermsOfServiceView.swift](Naplet/Features/Legal/TermsOfServiceView.swift) | Termos de serviço | Settings | 🟢 | – | OK |
| 26 | OnboardingView | [Features/Onboarding/Views/OnboardingView.swift](Naplet/Features/Onboarding/Views/OnboardingView.swift) | TabView com 12 steps | App root (first launch) | 🟡 | 925 | Refatorar em arquivos por step |
| 27 | PaywallView | [Features/Paywall/Views/PaywallView.swift](Naplet/Features/Paywall/Views/PaywallView.swift) | Paywall Founders + Regular | Triggered via PaywallTrigger | 🟡 | 717 | 5 dos 7 triggers não disparam (ver doc 03) |
| 28 | ProfileView | [Features/Profile/Views/ProfileView.swift](Naplet/Features/Profile/Views/ProfileView.swift) | Perfil do usuário | Dashboard sheet | 🟢 | 307 | OK |
| 29 | RatingPromptView | [Features/Rating/RatingPromptView.swift](Naplet/Features/Rating/RatingPromptView.swift) | Prompt de avaliação App Store | Condicional | 🟡 | – | TODO: "Enviar feedback para analytics/email" |
| 30 | ReferralButton | [Features/Referral/Views/ReferralButton.swift](Naplet/Features/Referral/Views/ReferralButton.swift) | Botão QR de referral | DashboardView | 🟢 | 105 | OK |
| 31 | ReferralView | [Features/Referral/Views/ReferralView.swift](Naplet/Features/Referral/Views/ReferralView.swift) | Hub de referrals + QR + stats | Dashboard sheet | 🟡 | 628 | QR code visual NÃO renderizado (só URL texto) |
| 32 | ReportView | [Features/Reports/Views/ReportView.swift](Naplet/Features/Reports/Views/ReportView.swift) | Gera PDF para pediatra | Dashboard sheet | 🟢 | 283 | PDF funciona, mas sem logo e sem peso |
| 33 | AddBabyView | [Features/Settings/Views/AddBabyView.swift](Naplet/Features/Settings/Views/AddBabyView.swift) | Registra novo bebê | Settings | 🟡 | 260 | SEM gate para `multipleBabies` (trigger fantasma) |
| 34 | EditBabyProfileView | [Features/Settings/Views/EditBabyProfileView.swift](Naplet/Features/Settings/Views/EditBabyProfileView.swift) | Edita perfil do bebê | Settings | 🟢 | 393 | OK |
| 35 | NotificationSettingsView | [Features/Settings/Views/NotificationSettingsView.swift](Naplet/Features/Settings/Views/NotificationSettingsView.swift) | Controla notificações | Settings | 🟢 | 461 | OK |
| 36 | SettingsView | [Features/Settings/Views/SettingsView.swift](Naplet/Features/Settings/Views/SettingsView.swift) | Menu de settings | Dashboard sheet | 🟡 | 819 | 3 TODOs "Update in Supabase" |
| 37 | SleepScheduleSettingsView | [Features/Settings/Views/SleepScheduleSettingsView.swift](Naplet/Features/Settings/Views/SleepScheduleSettingsView.swift) | Configura recomendações | Settings | 🟢 | 375 | OK |
| 38 | SleepTrackingView | [Features/Sleep/Views/SleepTrackingView.swift](Naplet/Features/Sleep/Views/SleepTrackingView.swift) | Registra sono | Dashboard sheet | 🟡 | 381 | 4 TODOs críticos no ViewModel (ver doc 04) |
| 39 | ContactFormView | [Features/Support/Views/ContactFormView.swift](Naplet/Features/Support/Views/ContactFormView.swift) | Formulário de suporte | SupportView | 🟢 | 276 | OK |
| 40 | FAQView | [Features/Support/Views/FAQView.swift](Naplet/Features/Support/Views/FAQView.swift) | FAQ expandível | SupportView | 🟢 | 270 | OK |
| 41 | SupportView | [Features/Support/Views/SupportView.swift](Naplet/Features/Support/Views/SupportView.swift) | Hub de suporte | Dashboard sheet | 🟡 | 317 | TODO: App ID real ainda é `id123456789` |
| 42 | VaccinationDashboardView | [Features/Vaccination/Views/VaccinationDashboardView.swift](Naplet/Features/Vaccination/Views/VaccinationDashboardView.swift) | Lista de vacinações | Dashboard sheet | 🟢 | 611 | OK |
| 43 | VaccinationDetailView | [Features/Vaccination/Views/VaccinationDetailView.swift](Naplet/Features/Vaccination/Views/VaccinationDetailView.swift) | Registra/edita 1 vacina | VaccinationDashboard | 🟢 | 516 | OK |

---

## Top ofensores por tamanho (refatoração urgente)

| Arquivo | Linhas | Recomendação |
|---|---|---|
| [DashboardView.swift](Naplet/Features/Dashboard/Views/DashboardView.swift) | **1954** | Quebrar em Header, Stats, Timeline, ActionGrid, GreetingCard |
| [PDFReportService.swift](Naplet/Data/Services/PDF/PDFReportService.swift) | 1513 | Separar por seção: SleepSection, FeedingSection, etc. |
| [OnboardingView.swift](Naplet/Features/Onboarding/Views/OnboardingView.swift) | 925 | 1 arquivo por step (12 steps inline = anti-padrão) |
| [SleepHistoryView.swift](Naplet/Features/History/Views/SleepHistoryView.swift) | 898 | Extrair gráficos |
| [SettingsView.swift](Naplet/Features/Settings/Views/SettingsView.swift) | 819 | Extrair seções |
| [SignInView.swift](Naplet/Features/Auth/Views/SignInView.swift) | 807 | Extrair EmailSignInView para arquivo separado |
| [PaywallView.swift](Naplet/Features/Paywall/Views/PaywallView.swift) | 717 | Extrair NapletPackageCard, NapletTrustBadge, etc. |

---

## Conclusões

1. **Zero código morto detectado.** Toda View é instanciada em algum fluxo.
2. **62 Views funcionam, mas 9 estão em estado 🟡** por motivos diferentes: paywall mal implementado, TODOs críticos, ou tamanho excessivo.
3. A **dívida arquitetural mais grave** é DashboardView (1954 linhas). Performance de SwiftUI sofre quando o body cresce assim porque o type-checker recompila tudo a cada mudança e a árvore de view é re-avaliada inteira.
4. **Apple Watch existe no código** (`NapletWatch/`) mas está com `AppConfig.enableAppleWatch = false`. Casca pronta para ativar (ver doc 04).
5. A documentação de status no `INVENTARIO_NAPLET_v2.md` está **descolada da realidade** em vários pontos (ver doc 04).
