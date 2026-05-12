# 04 - Estado Real de Cada Feature

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Tabela de estado

Legenda: 🟢 funciona de verdade · 🟡 funciona com buracos · 🔴 casca vazia / desabilitado

| # | Feature | Status | Justificativa (arquivo:linha) | Maior problema |
|---|---|---|---|---|
| 1 | Registro de sono | 🟡 | [SleepTrackingViewModel.swift:54-78](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:54) tem 4 TODOs críticos: `Get actual baby ID`, `Save to database`, `Check ongoing session`, `Save to Supabase` | TODOs de persistência fazem suspeitar que parte dos registros pode estar perdendo em casos de borda |
| 2 | Registro de alimentação | 🟡 | [FeedingViewModel.swift:127-150](Naplet/Features/Feeding/ViewModels/FeedingViewModel.swift:127) e [318](Naplet/Features/Feeding/ViewModels/FeedingViewModel.swift:318) TODO "pumping-specific fields" | Bombeamento sem campos L/R, só total |
| 3 | Registro de fralda | 🟢 | [DiaperViewModel.swift:52-85](Naplet/Features/Diaper/ViewModels/DiaperViewModel.swift:52) com Repository real | Nenhum |
| 4 | Registro de banho | 🟢 | [BathViewModel.swift:53-85](Naplet/Features/Bath/BathViewModel.swift:53) com Repository | Nenhum |
| 5 | Registro de temp/medicamento | 🟢 | [HealthViewModel.swift:67-128](Naplet/Features/Health/ViewModels/HealthViewModel.swift:67) | Nenhum |
| 6 | Histórico com gráficos | 🟡 | Só Sleep tem gráficos ([SleepHistoryViewModel.swift:72-120](Naplet/Features/History/ViewModels/SleepHistoryViewModel.swift:72)). Feeding/Diaper não têm tela de histórico com chart. | Histórico desigual entre módulos |
| 7 | Estatísticas avançadas | 🟡 | [DashboardViewModel.swift:100-120](Naplet/Features/Dashboard/ViewModels/DashboardViewModel.swift:100) calcula totalSleepToday, wakeWindowProgress, babyStatus | Sem análise semanal, sem predições, sem ML |
| 8 | Chat IA (OpenAI) | 🟡 | [ChatViewModel.swift:109-150](Naplet/Features/Chat/ViewModels/ChatViewModel.swift:109) + [OpenAIService.swift:90-150](Naplet/Data/Services/OpenAIService.swift:90), gpt-4o-mini | Chave OpenAI **hardcoded** em [AppConfig.swift:60](Naplet/Core/Config/AppConfig.swift:60), sem retry, contexto incompleto (sem fraldas, alimentação, semana) |
| 9 | Geração de PDF | 🟡 | [PDFReportService.swift:239](Naplet/Data/Services/PDF/PDFReportService.swift:239) usa UIGraphicsPDFRenderer real | Sem logo, sem campo peso, sem campo assinatura pediatra, design amador |
| 10 | Multi-cuidador | 🟡 | [CaregiverViewModel.swift:96-120](Naplet/Features/Caregivers/ViewModels/CaregiverViewModel.swift:96), código de 8 chars | **Sem realtime sync**, sem QR, sem deep link, sem presence, **risco RLS retroativo** |
| 11 | Carteira de vacinação | 🟢 | Vacinas vêm do Supabase (NÃO hardcoded como o INVENTARIO sugere). [VaccinationRepository.swift:34-52](Naplet/Data/Repositories/VaccinationRepository.swift:34) | Nenhum (mas a quantidade real de vacinas depende de seed do banco) |
| 12 | Carteira de documentos | 🟢 | [DocumentsViewModel.swift:93-100](Naplet/Features/Documents/ViewModels/DocumentsViewModel.swift:93), upload real | Nenhum |
| 13 | Referral com QR | 🟡 | [ReferralViewModel.swift:22-38](Naplet/Features/Referral/ViewModels/ReferralViewModel.swift:22) gera URL e código | **QR visual NÃO renderizado** (apenas texto/URL). Nome da feature engana. |
| 14 | Apple Watch | 🔴 | [NapletWatch/](NapletWatch/) existe, mas [AppConfig.swift:131](Naplet/Core/Config/AppConfig.swift:131) `enableAppleWatch = false` | Feature DESABILITADA por flag |
| 15 | Widgets | 🟢 | [NapletWidget/](NapletWidget/) com NapletSleepWidget, atualiza 1/min quando dormindo. `enableWidgets = true`. | Nenhum |
| 16 | Push notifications | 🟡 | [NotificationDelegate.swift](Naplet/Core/Managers/NotificationDelegate.swift), categorias (START_NAP, SNOOZE_15) | App **recebe** notificações (setup) mas **não há backend enviando** (sem APNs server) |

---

## Documentação descolada da realidade

Comparação com `INVENTARIO_NAPLET_v2.md` e `RELATORIO_APP_STORE_v2.md`:

| Declarado | Realidade |
|---|---|
| "Apple Watch funcional" | `enableAppleWatch = false`. Feature desabilitada. |
| "36 vacinas (hardcoded)" | Não. Vacinas vêm do banco Supabase. Quantidade depende de seed. |
| "Sounds/Lullabies (Dream Engine)" | `enableSounds = false`. Não implementado. (v1.2 planejada) |
| "Estatísticas avançadas" | Básico. Soma diária + status, sem semanas, sem predição. |
| "Histórico com gráficos completos" | Só Sleep tem chart. Outras categorias sem. |
| "Geração de PDF" | Funciona, mas design amador e sem peso. |
| "QR Code Referral" | Só URL/texto. Sem QR visual. |
| "Multi-cuidador com sync realtime" | Fetch manual ao reabrir. Zero realtime. |
| "RevenueCat em produção" | [AppConfig.swift:49](Naplet/Core/Config/AppConfig.swift:49) usa chave `test_qzTPNPxcoPp...` — **modo TESTE**. ⚠️ Verificar com a chave de prod via Info.plist override. |
| "Push notifications funcionais" | Recebe; não envia (sem APNs server). |
| "Mock repositories removidos" | Mocks ainda presentes (RELATORIO_APP_STORE_v2.md já apontava, não foi corrigido). |
| "App Store URL configurada" | [SupportViewModel.swift:155](Naplet/Features/Support/ViewModels/SupportViewModel.swift:155) TODO "SUBSTITUIR PELO APP ID REAL" — ainda `id123456789`. Link da loja vai falhar. |

---

## TODOs críticos não fechados (impacto direto)

| TODO | Arquivo:linha | Impacto |
|---|---|---|
| Get actual baby ID and user ID | [SleepTrackingViewModel.swift:62](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:62) | 🔴 Pode salvar registro com UUID errado |
| Save to database | [SleepTrackingViewModel.swift:100](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:100) | 🔴 Persistência incerta |
| Check if there's an ongoing session in database | [SleepTrackingViewModel.swift:155](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:155) | 🟡 Pode duplicar |
| Save to Supabase | [SleepTrackingViewModel.swift:159](Naplet/Features/Sleep/ViewModels/SleepTrackingViewModel.swift:159) | 🔴 |
| SUBSTITUIR PELO APP ID REAL | [SupportViewModel.swift:155](Naplet/Features/Support/ViewModels/SupportViewModel.swift:155) | 🔴 Link App Store quebrado |
| Update in Supabase (x3) | [SettingsViewModel.swift:213, 268, 308](Naplet/Features/Settings/ViewModels/SettingsViewModel.swift:213) | 🟡 Algumas configs não persistem |
| Implementar marcação de Founder no perfil | [PaywallViewModel.swift:345](Naplet/Features/Paywall/ViewModels/PaywallViewModel.swift:345) | 🟡 Promete badge, não entrega |
| Track with analytics service | [PaywallTrigger.swift:201](Naplet/Features/Paywall/Models/PaywallTrigger.swift:201) | 🟡 Sem analytics no paywall |
| Add pumping-specific fields | [FeedingViewModel.swift:318](Naplet/Features/Feeding/ViewModels/FeedingViewModel.swift:318) | 🟢 Cosmético |

---

## Score agregado

- **🟢 Sólidas:** 6 features (fralda, banho, temp/med, vacinação, documentos, widgets) = **38%**
- **🟡 Com buracos:** 9 features = **56%**
- **🔴 Cascas/desabilitadas:** 1 feature (Apple Watch) = **6%**

**Nota geral do estado de features:** 6/10. Vasto em superfície mas raso em entrega. O app **parece** completo na App Store, mas várias features são "Potemkin" — bonitas por fora, ocas em detalhes que importam.

**Maior risco de churn pós-compra:** se o usuário paga porque viu "Multi-cuidador" e descobre que não sincroniza em realtime, vai pedir refund. Isso é mais grave que ter feature 🔴 — é feature 🟡 que **promete mais do que entrega**.
