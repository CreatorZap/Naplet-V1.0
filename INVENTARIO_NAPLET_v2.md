# INVENTARIO COMPLETO DO NAPLET - STATUS REAL
## Atualizado: 28/01/2026

---

## 1. PAGINAS LEGAIS - COMPLETAS

| Arquivo | Status | Observacao |
|---------|--------|------------|
| TermsOfServiceView.swift | COMPLETO | 6 secoes, localizado em 3 idiomas |
| PrivacyPolicyView.swift | COMPLETO | 6 secoes, localizado em 3 idiomas |

**Conteudo localizado:** Textos completos em Localizable.strings (pt-BR, en, es)

---

## 2. SUPORTE - COMPLETO

| Arquivo | Status | Observacao |
|---------|--------|------------|
| FAQView.swift | COMPLETO | 11 FAQs em 5 categorias |
| SupportView.swift | COMPLETO | Central de ajuda funcional |
| ContactFormView.swift | COMPLETO | Formulario com 5 categorias |

**Categorias FAQ:** General (3), Sleep (2), Subscription (2), Technical (2), Account (2)

**Categorias de Ticket:** bug, feature, billing, question, other

**Coming Soon Section (2 itens, SF Symbols):**
- Sounds/Lullabies (70% progress) - music.note.list
- Educational Course (40% progress) - book.fill

---

## 3. ONBOARDING - COMPLETO

| Step | Conteudo |
|------|----------|
| 1. Welcome | Tela de boas-vindas com login/invite |
| 2. Benefits | 3 cards de beneficios |
| 3. Differentials | 3 diferenciais |
| 4. Attribution | Como conheceu o app |
| 5. Goals | Objetivos de sono |
| 6. BabyName | Nome do bebe |
| 7. BabyBirth | Data de nascimento |
| 8. BabyGender | Genero |
| 9. Relationship | Relacao com bebe |
| 10. Confirmation | Revisao dos dados |
| 11. Loading | Processamento |
| 12. Completion | Conclusao com confetti |

---

## 4. LOCALIZACOES - COMPLETAS

| Idioma | Arquivo | Linhas |
|--------|---------|--------|
| pt-BR | Localizable.strings | 1.354 |
| en | Localizable.strings | 1.383 |
| es | Localizable.strings | 1.435 |

**Adicional:** NapletWidget e NapletWatch tambem localizados

**Status:** Sincronizadas e completas

---

## 5. REVENUECAT - CONFIGURADO

| Item | Valor | Status |
|------|-------|--------|
| API Key | test_qzTPNPxcoPp... | TESTE - trocar por producao |
| Entitlement | Naplet Pro | Configurado |
| Product Monthly | naplet_premium_monthly | Configurado |
| Product Annual | naplet_premium_annual | Configurado |
| Product Founders | naplet_founders_annual | Configurado |
| Offering Default | default | Configurado |
| Offering Founders | founders | Configurado |
| Trial Days | 14 | Configurado |

**Founders Period:** Ativo ate 22/04/2026 (3 meses apos lancamento)

---

## 6. SUPABASE TABLES - MAPEADAS

### Tabelas Core (4)
| Tabela | Repositorio | Uso |
|--------|-------------|-----|
| babies | BabyRepository | Perfis de bebes |
| profiles | ProfileViewModel | Perfis de usuarios |
| caregivers | CaregiverRepository | Cuidadores |
| invites | CaregiverRepository | Convites |

### Tabelas de Atividades (6)
| Tabela | Repositorio | Uso |
|--------|-------------|-----|
| sleep_records | SleepRepository | Registros de sono |
| night_wakings | SleepRepository | Wakings/interrupcoes |
| feeding_records | FeedingRepository | Alimentacao |
| diaper_records | DiaperRepository | Fraldas |
| bath_records | BathRepository | Banho |
| health_records | HealthRepository | Saude (temp, meds) |

### Tabelas de Medicacao (2)
| Tabela | Repositorio | Uso |
|--------|-------------|-----|
| medication_schedules | MedicationRepository | Agendamento |
| medication_logs | MedicationRepository | Registros |

### Tabelas de Vacinacao (2)
| Tabela | Repositorio | Uso |
|--------|-------------|-----|
| vaccines | VaccinationRepository | Catalogo de vacinas |
| baby_vaccinations | VaccinationRepository | Vacinas aplicadas |

### Tabelas de Documentos (3)
| Tabela | Repositorio | Uso |
|--------|-------------|-----|
| baby_documents | DocumentsRepository | Documentos do bebe |
| document_types | DocumentsRepository | Tipos de documento |
| document_files | DocumentsRepository | Arquivos |

### Tabelas de Referral (2)
| Tabela | Repositorio | Uso |
|--------|-------------|-----|
| referral_codes | ReferralRepository | Codigos de referral |
| referrals | ReferralRepository | Referencias |

**Total: 19 tabelas mapeadas**

---

## 7. APP ICONS - COMPLETO

| Target | Status | Arquivos |
|--------|--------|----------|
| Naplet (iOS) | COMPLETO | Design sem nome-3.png (1024x1024) |
| NapletWidget | Verificar | Contents.json |
| NapletWatch | Verificar | Contents.json |

**Nota:** Xcode 15+ gera automaticamente os outros tamanhos a partir do 1024x1024

---

## 8. ENTITLEMENTS - CONFIGURADOS

| Arquivo | Conteudo |
|---------|----------|
| Naplet.entitlements | App Groups: group.app.naplet.ios |
| NapletWidgetExtension.entitlements | App Groups: group.app.naplet.ios |

---

## 9. CONFIGURACOES DO APP - COMPLETAS

### AppConfig.swift

**Features:**
| Feature | Status |
|---------|--------|
| AI Chat | HABILITADO |
| Apple Watch | DESABILITADO |
| Sounds | DESABILITADO |
| PDF Export | DESABILITADO |
| Widgets | HABILITADO |
| Multi Caregiver | HABILITADO |
| Mock Data | DESABILITADO (usa Supabase real) |

**Limites:**
| Item | Valor |
|------|-------|
| Bebes Free | 1 |
| Bebes Premium | 5 |
| Cuidadores/Bebe | 5 |
| Historico Free | 7 dias |
| AI Chat Free | 5/mes |
| Trial | 14 dias |
| Expiracao Convite | 7 dias |

**API:**
| Item | Valor |
|------|-------|
| Timeout | 30 segundos |
| Retry Attempts | 3 |
| Retry Delay | 1 segundo |

---

## 10. INFO.PLIST - COMPLETO

| Chave | Valor |
|-------|-------|
| Bundle Region | pt-BR |
| Localizations | pt-BR, es, en |
| URL Scheme | naplet:// |
| Encryption | No (ITSAppUsesNonExemptEncryption = false) |
| Orientation | Portrait only (iPhone), All (iPad) |
| Launch Screen | LaunchScreenBackground color |
| Capabilities | arm64 |

---

## 11. DESIGN SYSTEM - COMPLETO

### NapletColors.swift - 28 cores definidas

**Background Colors (4):**
- background - #0D0B1E (Main dark)
- backgroundSecondary - #1A1730
- backgroundTertiary - #252142
- backgroundCard - #1E1B33

**Accent Colors (4):**
- primaryPurple - #8B5CF6
- primaryPink - #EC4899
- primaryBlue - #3B82F6
- primaryCyan - #06B6D4

**Gradients (6):**
- gradientPrimary (Purple -> Pink)
- gradientSecondary (Blue -> Cyan)
- gradientSleep (Indigo -> Purple)
- gradientSunrise (Orange -> Red)
- gradientNight (Dark blue)
- gradientCard (Background gradient)

**Text Colors (3):**
- textPrimary - White
- textSecondary - #A1A1AA
- textMuted - #71717A

**Status Colors (4):**
- success - #22C55E (Green)
- warning - #F59E0B (Orange)
- error - #EF4444 (Red)
- info - #3B82F6 (Blue)

**Sleep Colors (3):**
- sleepActive - #818CF8
- napColor - #A78BFA
- awakeColor - #FCD34D

**Glow Effects (3):**
- glowPurple, glowPink, glowBlue

---

## 12. NOVAS FEATURES - IMPLEMENTADAS

### A. Carteira de Documentos
**Location:** Features/Documents/

| Componente | Status |
|------------|--------|
| DocumentsView.swift | Completo |
| AddDocumentView.swift | Completo |
| DocumentDetailView.swift | Completo |
| DocumentsViewModel.swift | Completo |
| DocumentModels.swift | Completo |

**Funcionalidades:**
- Tipos de documento com SF Symbols
- Upload de arquivos/fotos
- Multiplas paginas por documento
- Favoritos
- Storage no Supabase

### B. Carteira de Vacinacao
**Location:** Features/Vaccination/

| Componente | Status |
|------------|--------|
| VaccinationDashboardView.swift | Completo |
| VaccinationDetailView.swift | Completo |
| VaccinationDashboardViewModel.swift | Completo |
| VaccinationModels.swift | Completo |
| VaccinationRepository.swift | Completo |

**Funcionalidades:**
- Catalogo de vacinas por idade
- Rastreamento de doses
- Data, lote, local de aplicacao
- Status pendente/completo
- SF Symbols (sem emojis)

### C. Sistema de Referral com QR Code
**Location:** Features/Referral/

| Componente | Status |
|------------|--------|
| ReferralView.swift | Completo |
| ReferralButton.swift | Completo |
| ReferralViewModel.swift | Completo |
| ReferralRepository.swift | Completo |
| ReferralModels.swift | Completo |
| QRCodeSheet | Completo |

**Funcionalidades:**
- Codigo unico por usuario
- QR Code geracao/compartilhamento
- Salvar QR Code nas fotos
- Share URL
- Tracking de indicacoes
- Status de Ambassador

---

## RESUMO FINAL

| Categoria | Status | Acao Necessaria |
|-----------|--------|-----------------|
| Paginas Legais | OK | Nenhuma |
| Suporte/FAQ | OK | Nenhuma |
| Onboarding | OK | Nenhuma |
| Localizacoes | OK | Nenhuma |
| RevenueCat | Parcial | Trocar chave para producao |
| Supabase | OK | Verificar RLS policies |
| App Icons | OK | PNG 1024x1024 adicionado |
| Entitlements | OK | Nenhuma |
| AppConfig | OK | Nenhuma |
| Info.plist | OK | NSPhotoLibraryUsageDescription adicionado |
| Design System | OK | Nenhuma |
| Documents | OK | Novo feature completo |
| Vaccination | OK | Novo feature completo |
| Referral | OK | QR Code implementado |

---

## BLOQUEADORES CRITICOS

### 1. RevenueCat Key
A chave atual e de teste (`test_qzTPNPxcoPpEEJoWKtEptoSPZwY`)

**Acao:** Substituir pela chave de producao no AppConfig.swift

### 2. Debug Logs - RESOLVIDO
~~3 arquivos ainda com debug logs hardcoded~~ - **REMOVIDOS**

Os blocos de debug com path `/Volumes/` foram removidos de:
- VaccinationRepository.swift
- VaccinationDashboardViewModel.swift

---

## ANTES DE SUBMETER A APP STORE

### Codigo
- [x] Debug logs removidos (3 arquivos limpos)
- [x] fatalError corrigido
- [x] Force unwrap corrigido
- [x] LaunchScreenBackground criado
- [x] Cards da Dashboard reorganizados
- [x] Localizacao documents.subtitle corrigida
- [x] Print statements em #if DEBUG (todos envolvidos)

### Configuracao
- [x] Adicionar App Icon PNG
- [ ] Trocar RevenueCat key para producao
- [x] Adicionar NSPhotoLibraryUsageDescription (para QR Code)
- [ ] Criar app no App Store Connect e obter App ID
- [ ] Configurar produtos IAP no App Store Connect

### Site
- [ ] Verificar se naplet.app/terms existe
- [ ] Verificar se naplet.app/privacy existe
- [ ] Verificar se instagram.com/naplet.app existe

---

## ESTATISTICAS DO PROJETO

| Metrica | Valor |
|---------|-------|
| Arquivos Swift | 258 |
| Tabelas Supabase | 19 |
| Linhas de Localizacao | ~4.172 total |
| Cores no Design System | 28 |
| Steps de Onboarding | 12 |
| FAQs | 11 |
| Features Principais | 15+ |

---

*Inventario gerado em 28/01/2026*
